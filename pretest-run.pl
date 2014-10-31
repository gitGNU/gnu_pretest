#!/usr/bin/env perl

# Copyright (C) 2014 Assaf Gordon (assafgordon@gmail.com)
#
# This file is part of PreTest
#
# PreTest is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PreTest is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PreTest If not, see <http://www.gnu.org/licenses/>.

## no critic (ErrorHandling::RequireCarping)
## no critic (RegularExpressions::RequireExtendedFormatting)
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;
use Socket;
use Data::Dumper;
use Getopt::Long;
use File::Basename;
use File::Temp qw/tempfile/;

my $VERSION = "0.1.1";

## User/Command-line parameters
my $qcow2_filename;
my $vm_name;
my $daemonize;
my $connect_console;
my $connect_ssh;
my $connect_ssh_copy_id;
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
my $graceful_shutdown_attempts = 30 ; # 30 attempts =~ 30 seconds

## Internal/QEMU parameters
my $disk_if="virtio";
my $net_if ="virtio";
my $graphics_if="none";
my @extra_qemu_params;
my $ssh_user = "miles";
my $qemu_pid;

sub parse_commandline;
sub setup_qemu_parameters;
sub find_available_tcp_port;
sub setup_vm_hacks;
sub setup_ssh;
sub connect_ssh;
sub usage;
sub get_qemu_pid;
sub die_with_qemu_running;
sub xsystem;
sub try_ssh_connect;
sub kill_qemu;
sub gracefull_kill_qemu;

##
## Program Start
##
parse_commandline;
setup_vm_hacks;
setup_ssh if $connect_ssh || $connect_ssh_copy_id;
my @qemu_params = setup_qemu_parameters;

if ($dry_run) {
	print join (' ', 'qemu-system-x86_64',
			 map { "'$_'" } @qemu_params ), "\n";
	exit 0;
}

# Start QEMU
# If connecting using the console - this won't return
#   until the user kills the machine.
# If connecting using SSH (thus, qmeu will daemonize),
#   this will return immediately, then we'll try SSH connection
my $qemu_exit_code = xsystem('qemu-system-x86_64', @qemu_params);

if ($connect_ssh) {
	my $exit_code = connect_ssh();
	kill_qemu();
	exit $exit_code;
}
if ($connect_ssh_copy_id) {
	connect_ssh_copy_id();
	gracefull_kill_qemu();
}

exit 0;

##
## Program End
##

sub usage
{
	my $base = basename($0);
	print<<"EOF";
PreTest Run Script version $VERSION
Copyright (C) 2014 Assaf Gordon (agn at gnu dot org)
License: GPLv3+

Usage:
$base [OPTIONS] FILE.QCOW2

FILE.QCOW2 - The Guest VM QCOW2 disk image file.
             By default, the Guest is started in snapshot mode,
             and connected to with SSH.

Options:
 -h, --help           this help screen
 -d, --daemonize      start the guest VM in the background, then return
     --console        connect the guest VM's serial console to the current
                      terminal. QEMU Monitor will be attached as well,
                      accessible with CTRL-A,C .
     --ssh            connect to the guest VM using SSH. SSH will be started
                      on the current terminal. This is the default mode.
     --pubkey         start the guest VM and use 'ssh-copy-id' to copy the
                      user's public SSH key to guest VM. You will be prompted
                      for a password (which is '12345'). When done, the Guest
                      VM will be shutdown automatically.
 -S, --no-snapshot    do not use QEMU's -snapshot mode, write changes back to
                      the guest VM disk image file.
 -r FILE, --serial-file FILE
                      connect the guest VM's 2nd serial port to FILE.
                      To send data from guest VM to host, run (in the guest VM):
                         echo hello > /dev/ttyS1 (on GNU/Linux)
                         echo hello > /dev/com1  (on Hurd)
                         echo hello > /dev/ttyu1 (on FreeBSD)
                         echo hello > /dev/tty01 (on Dilos,MINIX,OpenBSD,NetBSD)
     --pid-file FILE
                      write QEMU's process ID to FILE.  useful with --daemonize.
     --console-file FILE
                      connect the Guest VM's first serial/console output to
                      FILE.  useful with --daemonize.
 -p N, --ssh-port N   forward the Guest VM's port 22 to host port N.
                      useful with --daemonize.
                      when using --ssh, an available port number will be found
                      automatically, and there's no need to use --ssh-port.
     --name X         use name X (instead of detecting name from QCOW2 file)
                      the name is used for specific QEMU options (e.g. if the
                      name contains 'minix', the appropriate minix options will
                      be passed to QEMU).
     --ram N          amount of RAM to allocate to the guest VM.
                      default is $ram_size for most VMs.
     --debug          show debugging information, such as command-line parameters.
     --verbose        show progress information.
     --dry-run        don't run QEMU, instead - print the command-line.
     --vm-image FILE
                      run the Guest VM inside FILE (a QCOW2 file).
                      if not specified, the first non-option parameters is assumed
                      to be the QCOW2 filename.

Typical usage:

With a new Guest VM, run once with --pubkey to add your SSH key
(you will be prompted for a password, which is '12345' for all pretest VMs):

   $base --pubkey freebsd10.qcow2

Then, start the guest VM, and automatically connect to it with SSH:

   $base freebsd10.qcow2

When exiting the SSH session (with 'exit' or CTRL-D), the guest VM will be
immediately terminated (with no data-loss or corruption because the default is
using -snapshot mode).

PreTest website:           http://pretest.nongnu.org
Download pre-build VMs:    http://www.nongnu.org/pretest/downloads/
Questions and bug-reports: pretest-users\@nongnu.org
search archives:           http://lists.nongnu.org/archive/html/pretest-users

EOF
	exit 0;
}

sub parse_commandline ## no critic (ProhibitExcessComplexity)
{
	my $rc = GetOptions(
			"help|h"      => \&usage,
			"daemonize|d" => \$daemonize,
			"console"     => \$connect_console,
			"ssh"         => \$connect_ssh,
			"pubkey"      => \$connect_ssh_copy_id,
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
	my @ops;
	push @ops, "--console" if $connect_console;
	push @ops, "--ssh" if $connect_ssh;
	push @ops, "--deaminize" if $daemonize;
	push @ops, "--pubkey" if $connect_ssh_copy_id;
	die "error: @ops are mutually exclusive options\n" if scalar(@ops)>1;
	$connect_ssh = 1 if scalar(@ops)==0; # default operation: ssh connection

	die "error: invalid/too-small RAM size ($ram_size)\n"
		if $ram_size<5;
	die "error: invalid SSH port ($ssh_port), must be >1024\n"
		if defined $ssh_port && $ssh_port<=1024;

	return;
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

	return;
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

	## If adding an SSH pubkey, don't run with 'snapshot' - changes should
	## be saved back to the disk image.
	$snapshot_mode = undef if ($connect_ssh_copy_id);

	$daemonize = 1;

	return;
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
	## This terrible hack was only tested on linux
	my $text = `netstat -lnt`; ## no critic (InputOutput::ProhibitBacktickOperators)
	die "error: failed to run 'netstat -lnt'"
		unless ($?>>8)==0;
	my @lines = split /\n/, $text;
	print "netstat returned: \n", Dumper(\@lines),"\n" if $debug;
	# Keep TCP (discard tcp6)
	@lines = grep { /^tcp / } @lines;
	print "tcp lines: \n", Dumper(\@lines),"\n" if $debug;
	# Grab the 4th column - the local addresses
	my @local = map { $_->[3] }
			map { [ split /\s+/, $_ ] }
			@lines;
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

sub try_ssh_connect
{
	my ($host, $port) = @_; 

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

sub wait_for_ssh_connection
{
	$qemu_pid = get_qemu_pid();

	## Test TCP connection to guest's port 22
	my $attempts = $boot_connection_attempts;
	while (1) {
		warn "Testing TCP connection $ssh_addr:$ssh_port...\n" if $verbose;

		die "error: QEMU process (PID $qemu_pid) not found - perhaps crashed?\n"
			unless kill 0, $qemu_pid;
		try_ssh_connect($ssh_addr,$ssh_port) and last;

		--$attempts;
		die_with_qemu_running ("failed to connect with SSH to guest VM")
			 if $attempts==0;
		sleep 1;
	}

	return;
}

sub connect_ssh
{
	wait_for_ssh_connection();

	## Run SSH
	## (This is too OpenSSH specific...)
	my @ssh_params = ( "-o", "StrictHostKeyChecking=no",
			   "-o", "CheckHostIP=no",
			   "-o", "UserKnownHostsFile=/dev/null",
			   "-p", $ssh_port,
			   "$ssh_user\@$ssh_addr" ) ;

	my $exit_code = xsystem("ssh", @ssh_params);

	## The exitcode of SSH will be the exitcode of the last command
	## executed inside the guest-VM - not necessarily zero.
	## Keep it for later
	return $exit_code;
}

sub connect_ssh_copy_id
{
	wait_for_ssh_connection();

	## Run ssh-copy-id
	## (This is too OpenSSH specific...)
	my @ssh_params = ( "-o", "StrictHostKeyChecking=no",
			   "-o", "CheckHostIP=no",
			   "-o", "UserKnownHostsFile=/dev/null",
			   "-p", $ssh_port,
			   "$ssh_user\@$ssh_addr" ) ;

	my $exit_code = xsystem("ssh-copy-id", @ssh_params);

	die_with_qemu_running ("failed to copy SSH public key")
		unless $exit_code == 0 ;

	## Ugly Hack for shutdown command.
	## TODO: Use QEMU Monitor?
	# start with GNU/Linux default
	my $shutdown_cmd = "sudo /sbin/shutdown -h -P now";

	$shutdown_cmd = "sudo /sbin/shutdown -p now"
		if $vm_name =~ /freebsd/i;

	$shutdown_cmd = "sudo /sbin/shutdown -h -p now"
		if $vm_name =~ /(open|net)bsd/i;

	$shutdown_cmd = "su root -c '/sbin/shutdown -h -p now'" # MINIX, no sudo
		if $vm_name =~ /minix/i;

	## DilOS (Illumos-based)
	$shutdown_cmd = "sudo /usr/sbin/shutdown -y now"
		if $vm_name =~ /dilos/i;

	## Shutdown the machine
	@ssh_params = ( "-o", "StrictHostKeyChecking=no",
			"-o", "CheckHostIP=no",
			"-o", "UserKnownHostsFile=/dev/null",
			"-o", "BatchMode=yes",
			"-p", $ssh_port,
			"-t",
			"$ssh_user\@$ssh_addr",
			"sh", "-c", "\"$shutdown_cmd\"");

	$exit_code = xsystem("ssh", @ssh_params);

	return;
}


sub die_with_qemu_running ## no critic (Subroutines::RequireArgUnpacking)
{
	my $info = join(" ",@_);

	print STDERR<<"EOF";
Error: $info

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

sub xsystem
{
	my ($program, @params) = @_;

	print STDERR "Starting '$program'\n" if $verbose;

	print STDERR "Running Command:\n",
		"  $program \\\n",
		join("\\\n", map{ "    '$_' " } @params),
		"\n\n" if $debug;

	my $rc = system $program, @params;
	my $exit_code = ($rc>>8);
	my $signal = ($rc & 127);

	die "error: failed to execute '$program': $!\n" if $rc == -1;
	die "error: '$program' died with signal $signal\n" if $signal;

	return $exit_code;
}

sub kill_qemu
{
	# Done with SSH - kill the Guest VM
	my $pid = get_qemu_pid();
	my $count = kill 'SIGKILL', $pid;
	die_with_qemu_running("failed to kil QEMU process") if $count == 0;
	return;
}

sub gracefull_kill_qemu
{
	# Done with SSH - Wait for QEMU to terminate (since the guest VM
	# was shutdown).
	my $pid = get_qemu_pid();

	my $attempts = $graceful_shutdown_attempts;
	while (1) {
		print STDERR "Waiting for Guest VM to shutdown...\n" if $debug;
		my $cnt = kill 0, $pid;
		last if $cnt==0;
		--$attempts;
		die_with_qemu_running("QEMU did not shutdown properly (after SSH pubkey copy)")
			if $attempts==0;
		sleep 1;
	}
	return;
}

