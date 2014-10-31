#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use File::Temp qw/tempfile/;
my $have_net_emptyport = eval {
		require Net::EmptyPort;
		1;
	};

## User/Command-line parameters
my $qcow2_filename;
my $vm_name;
my $daemonize;
my $connect_console;
my $connect_ssh;
my $serial_file;
my $ram_size=384;
my $snapshot_mode=1;
my $ssh_port;
my $ssh_addr="127.0.0.1"; # empty means 0.0.0.0, see 'hostaddr' in QEMU's hostfwd option
my $pid_file;
my $console_file;
my $debug;
my $verbose;
my $dry_run;
my $boot_order = "cd"; # currently hard-coded
my $boot_connection_attempts = 120 ; # 120 attemps =~ 4 minutes

## Internal/QEMU parameters
my $disk_if="virtio";
my $net_if ="virtio";
my $graphics_if="none";
my @extra_qemu_params;
my $ssh_user = "miles";
my $ssh_connected;
my $qemu_pid;

sub parse_commandline;
sub setup_qemu_parameters;
sub find_available_tcp_port;
sub setup_vm_hacks;
sub setup_ssh;
sub connect_ssh;
sub usage;
sub get_qemu_pid;
sub die_with_debug_info;

##
## Program Start
##
parse_commandline;
setup_vm_hacks;
setup_ssh if $connect_ssh;
my @qemu_params = setup_qemu_parameters;

print "QEMU Parameters:\n", Dumper(\@qemu_params),"\n" if $debug;

if ($dry_run) {
	print join (" ", "qemu-system-x86_64",
			 map { "'$_'" } @qemu_params ), "\n";
	exit 0;
}

# Start QEMU
# If connecting using the console - this won't return
#   until the user kills the machine.
# If connecting using SSH (thus, qmeu will daemonize),
#   this will return immediately, then we'll try SSH connection
system "qemu-system-x86_64", @qemu_params;

if ($connect_ssh) {
	$qemu_pid = get_qemu_pid();

	my $exit_code = connect_ssh();

	if ($ssh_connected)
	{
		# Done with SSH - kill the Guest VM
		my $pid = get_qemu_pid();
		my $count = kill 'SIGKILL', $pid;
		die "error: failed to kill QEMU process PID $pid\n" if $count == 0;

		# Pass the exit code from SSH back to the user.
		exit $exit_code;
	} else {
		die_with_debug_info;
	}
}

##
## Program End
##

sub usage
{
}

sub parse_commandline
{
	my $rc = GetOptions(
			"help|h"      => \&usage,
			"daemonize|d" => \$daemonize,
			"console"     => \$connect_console,
			"ssh"	      => \$connect_ssh,
			"no-snapshot|S" => sub { $snapshot_mode = 0 ; },
			"serial-file|r:s"  => \$serial_file,
			"pid-file:s"  => \$pid_file,
			"console-file:s"  => \$console_file,
			"ssh-port|p=i"=> \$ssh_port,
			"name=s"      => \$vm_name,
			"ram=i"       => \$ram_size,
			"debug"       => \$debug,
			"verbose"     => \$verbose,
			"dry-run"     => \$dry_run,
			"vm-image=s"  => \$qcow2_filename,
			)
		or die "invalid command-line options\n";

	# If no explicit --vm-image=FILE given, assume it's the first
	# non-option parameter.
	if (! defined $qcow2_filename) {
		$qcow2_filename = shift @ARGV
			or die "error: missing VM-IMAGE filename. See -h for help.\n";
	}
	die "error: VM-IMAGE file ($qcow2_filename) not found.\n"
		unless -e $qcow2_filename;

	# If no explicit name given, deduce it from the file name
	$vm_name = basename($qcow2_filename, '.qcow2','.raw','.img')
		unless defined $vm_name;
	die "error: VM name ($vm_name) contains disallowed characteres.\n"
		unless $vm_name =~ /^[A-Za-z0-9_%=\.\-]+$/;

	# If the user asked for serial/pid files, but did not specify an
	# optional filename, set it based on the VM name.
	$pid_file = $vm_name . ".pid"
		if defined $pid_file && length($pid_file)==0;
	$serial_file = $vm_name . ".serial"
		if defined $serial_file && length($serial_file)==0;
	$console_file = $vm_name . ".console"
		if defined $console_file && length($console_file)==0;
	die "error: invalid PID file name ($pid_file)\n"
		if defined $pid_file and length($pid_file)==0;
	die "error: invalid Serial file name ($serial_file)"
		if defined $serial_file and length($serial_file)==0;
	die "error: invalid Console file name ($console_file)"
		if defined $console_file and length($console_file)==0;

	# Prevent mutually exclusive options, with informative error messages.
	die "error: --console and --deaminize are mutually exclusive\n"
		if $connect_console && $daemonize;
	die "error: --console and --ssh are mutually exclusive\n"
		if $connect_console && $connect_ssh;
	die "error: --ssh and --daeminize are mutually exclusive\n"
		if $connect_ssh && $daemonize;

	die "error: invalid/too-small RAM size ($ram_size)\n"
		unless $ram_size>=5;
	die "error: invalid SSH port ($ssh_port), must be >1024\n"
		if defined $ssh_port && $ssh_port<=1024;
}

sub setup_vm_hacks
{
	## GNU Hurd 0.5 -
	## Doesn't suppoort Virtio drivres
	if ($vm_name =~ /hurd/i) {
		$disk_if = "ide";
		$net_if  = "rtl8139";
	}
	## MINIX R3.3.0: requires a VGA adapter
	if ($vm_name =~ /minix/i) {
		$graphics_if = "vncnone";
	}
	## DilOS (Illumos-based)
	if ($vm_name =~ /dilos/i) {
		# Requires a VGA adapter
		$graphics_if = "vncnone";
		# Fails to boot (kernel panic) without these devices
		@extra_qemu_params = ("-machine","pc-1.1");
		# DilOS runs too much stuff to be usable with only 384
		$ram_size = 768;
	}
}

sub setup_ssh
{
	## If the user requested the connect with SSH,
	## make QEMU daemonize, and ensure we have the required files.

	## Ensure we have a PID file and Console file
	## (eithir explicitly set by the user, or temporary filenames)
	(undef, $pid_file) = tempfile( "presest.pid.XXXXXX", TMPDIR => 1, OPEN => 0)
		unless $pid_file;
	(undef, $console_file) = tempfile( "pretest.console.XXXXXXX", TMPDIR => 1, OPEN => 0)
		unless $console_file;

	## Ensure we have a TCP PORT which forwards the guest's TCP/22
	## to the host. Either the one set by the user, or any available
	## local port.
	if (! $ssh_port) {
		$ssh_port = find_available_tcp_port;
		$ssh_addr = "127.0.0.1";
	}

	$daemonize = 1;
}

sub setup_qemu_parameters
{
	my @p;

	push @p, "-enable-kvm";

	push @p, "-name", $vm_name;
	push @p, "-m",    $ram_size;
	push @p, "-nodefaults";

	push @p, "-net", "nic,model=$net_if";
	if ($ssh_port) {
		push @p, "-net","user,hostfwd=tcp:$ssh_addr:$ssh_port-:22";
	} else {
		push @p, "-net","user";
	}

	push @p, "-drive", "file=$qcow2_filename,if=$disk_if,media=disk,index=0";
	push @p, "-boot",  $boot_order;

	push @p, "-snapshot" if $snapshot_mode;

	push @p, "-pidfile", $pid_file if $pid_file;

	if ($graphics_if eq "none") {
		push @p, "-nographic";
	} elsif ($graphics_if eq "vncnone") {
		push @p, "-vga","std", "-vnc","none";
	} else {
		die "Internal error: unknown graphic interface ($graphics_if)";
	}

	push @p, "-daemonize" if $daemonize;

	## Setup first serial port.
	## A bit tricky - depends on serveral other parameter combinations.
	if ($daemonize) {
		if ($console_file) {
			push @p, "-serial", "file:$console_file";
		} else {
			push @p, "-serial", "null";
		}
	} else {
		# If not daemonizing, connect the QEMU monitor to the
		# current terminal, in addition to the guest's first
		# serial port/console.
		push @p, "-serial", "mon:stdio";
	}

	## Setup second serial port
	push @p, "-serial", "file:$serial_file" if $serial_file;

	## Add extra parameters
	push @p, @extra_qemu_params;

	return @p;
}

sub find_available_tcp_port
{
	if ($have_net_emptyport) {
		return empty_port(1025);
	} else {
		## This terrible hack was only tested on linux
		my $text = `netstat -lnt`;
		die "error: failed to run 'netstat -lnt'"
			unless ($?>>8)==0;
		my @lines = split /\n/, $text;
		print "netstat returned: \n", Dumper(\@lines),"\n" if $debug;
		# Keep TCP (discard tcp6)
		@lines = grep { /^tcp / } @lines;
		print "tcp lines: \n", Dumper(\@lines),"\n" if $debug;
		# Grab the 4th column - the local addresses
		my @local = map { my @t = split /\s+/, $_; $t[3] ; } @lines;
		print "local addresses: \n", Dumper(\@local),"\n" if $debug;
		# Extract the numeric ports
		my @ports = map { /^(\d+)\.(\d+)\.(\d+)\.(\d+):(\d+)$/ and $5 or undef ; } @local;
		print "used ports: \n", Dumper(\@ports),"\n" if $debug;

		my %ports = map { $_ => 1 } @ports;
		foreach my $i ( 1025 .. 65500 ) {
			return $i unless exists $ports{$i};
		}

		# Highly unlikely...
		die "error: can't find available TCP port using netstat.";
	}
}

sub get_qemu_pid
{
	# Racy situation:
	# It's possible that the daemonize QEMU hasn't created the PID file yet.
	# So give it a chance to do so.
	# TODO:
	#   Improve this with QEMU monitoring API.
	my $attempts = 5;
	while (1) {
		last if -e $pid_file;
		$attempts--;
		die "failed to find PID file ($pid_file) after QEMU daemonizing\n"
			if $attempts==0;
		sleep(1);
	}

	open my $f, "<", $pid_file
		or die "failed to open PID file ($pid_file): $!\n";
	my $t = <$f>;
	close $f;

	$t = "" unless defined $t;
	chomp $t;

	die "invalid value ($t) found in PID file ($pid_file)\n"
		unless $t =~ /^\d+$/;

	return $t;
}

sub try_tcp_connect
{
	my ($host, $port) = @_;

	use Socket;
	my $iaddr   = inet_aton($host)
		or die "invalid host address '$host'";
	my $paddr   = sockaddr_in($port, $iaddr);
	my $proto   = getprotobyname("tcp");
	socket(SOCK, PF_INET, SOCK_STREAM, $proto)
		or die "failed to create socket: $!";
	my $conn_ok = connect(SOCK, $paddr);
	my $ok = 0 ;
	if ($conn_ok) {
		warn "Sending foobar to SOCKET\n" if $debug;
		send SOCK,"SSH-2.0-PreTest0.1 JustChecking\r\n",0;
		my $rin = '';
		vec($rin, fileno(SOCK),  1) = 1;
		warn "selecting...\n" if $debug;
		my $nfound = select($rin, undef,undef, 1);
		warn "select returned $nfound\n" if $debug;
		if ($nfound>0) {
			sleep 1;
			my $data = '';
			recv SOCK, $data, 1024,0;
			warn "Got response: '$data'\n" if $debug;
			$ok = $data =~ /^SSH-/;
		}
	}
	close (SOCK) or die "failed to close socket: $!";

	return $ok;
}

sub connect_ssh
{
	if ($debug) {
		warn "QEMU Guest PID: $qemu_pid\n";
		warn "Guest Console Log: $console_file\n";
	}

	## Test TCP connection to guest's port 22
	my $attempts = $boot_connection_attempts;
	while (1) {
		warn "Testing TCP connection $ssh_addr:$ssh_port...\n" if $verbose;

		die "error: QEMU process (PID $qemu_pid) not found - perhaps crashed?\n"
			unless kill 0, $qemu_pid;
		try_tcp_connect($ssh_addr,$ssh_port) and last;

		--$attempts;
		die_with_debug_info if $attempts==0;
		sleep 1;
	}


	## From here on we assume SSH can be connected,
	## and once SSH is done, QEMU should be terminated.
	$ssh_connected = 1;


	##
	## Run SSH
	## (This is too OpenSSH specific...)
	my @ssh_params = ( "-o", "StrictHostKeyChecking=no",
			   "-o", "CheckHostIP=no",
			   "-o", "UserKnownHostsFile=/dev/null",
			   "-p", $ssh_port,
			   "$ssh_user\@$ssh_addr" ) ;

	print "SSH Parameters:\n", Dumper(\@ssh_params),"\n" if $debug;

	my $rc = system "ssh", @ssh_params;
	my $exit_code = ($rc>>8);
	die "failed to execute SSH: $!\n" if $rc == -1;
	if ($rc & 127) {
		die "SSH child died with signal %d, %s coredump\n",
		       ($? & 127),  ($? & 128) ? 'with' : 'without';
	}

	## The exitcode of SSH will be the exitcode of the last command
	## executed inside the guest-VM - not necessarily zero.
	## Keep it for later
	return $exit_code;
}


sub die_with_debug_info
{
	print STDERR<<"EOF";
error: failed to connect with SSH to QEMU Guest.
Check QEMU process PID $qemu_pid.
Test SSH Connection with:
    nc $ssh_addr $ssh_port < /dev/null
    ssh -p $ssh_port $ssh_user\@$ssh_addr
Test Console log:
    tail -f $console_file
Kill the QEMU process with:
    kill $qemu_pid
It is possible the Guest VM is simply booting too slow.
EOF
	exit 1;
}
