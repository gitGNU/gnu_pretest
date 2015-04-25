# PreTest - Pre-Release Portability Testing VMs

PreTest's goal is to provide pre-built virtual-machine images of Free-Software
POSIX-compliant operating systems, ready for testing *autotools*-based programs.

## Available VM disk images

Downloads: <http://www.nongnu.org/pretest/downloads/>

Kernel and program versions on each VM: <http://www.nongnu.org/pretest/versions/>

All VMs have user 'miles' with password '12345' and 'sudo' (or 'su') access.

## Simple QEMU usage

    # Download a VM image
    wget http://files.housegordon.org/pretest/v0.1/freebsd101.build-ready.qcow2.xz
    unxz freebsd101.build-ready.qcow2.xz

    # Run with QEMU (press CTRL-A,C for QEMU-Monitor)
    qemu-system-x86_64 --enable-kvm -nographic -m 384 -snapshot \
        -net user -net nic,model=virtio \
        -drive if=virtio,media=disk,index=0,file=freebsd101.build-ready.qcow2

## QEMU Wrapper script

Use the [pretest-run.pl](http://git.savannah.gnu.org/cgit/pretest.git/tree/pretest-run.pl)
script for easier bootstrap of the configured images:

    # Download script
    wget http://git.savannah.gnu.org/cgit/pretest.git/plain/pretest-run.pl

    # Start VM, connect to serial console (press CTRL-A,C for QEMU monitor)
    ./pretest-run.pl --console freebsd101.build-ready.qcow2

    # Optionally:
    # Copy the host user's SSH Public key to the VM
    # (so that future boots with SSH connection will not require a password):
    ./pretest-run.pl --pubkey freebsd101.build-ready.qcow2

    # Start VM, connect through SSH
    # (when logging off, VM will be automatically shutdown)
    ./pretest-run.pl freebsd101.build-ready.qcow2


See `pretest-run.pl --help` for more options.

All VMs have user 'miles' with password '12345' and 'sudo' (or 'su') access.

## LibVirt Usage

All VMs can be imported to LibVirt.

See [LibVirt](http://www.nongnu.org/pretest/manual/#LibVirt-usage) manual page
for details.

## VirtualBox Usage

Most VMs can be imported to VirtualBox.

See [VirtualBox](http://www.nongnu.org/pretest/manual/#VirtualBox-usage)
manual page for details.

## Current and Future plans

The current version of PreTest provides pre-configured VMs, which facilitate
manual testing on multiple operating systems.

Future versions will provide scripts to automated (or semi-automate) testing
of a given tarball on multiple operating systems.

If you're interested in helping or improving PreTest, please see the `TODO.md`
file in the [git repository](http://git.savannah.gnu.org/cgit/pretest.git),
and/or write to *pretest-users at nongnu.org*.

## Setup Details

* All VMs use QEMU/KVM and assume amd64 host

* A helper script `pretest-run.sh` provide an easy way to start each VM,
  using the most common QEMU/KVM settings.

* **clean-install** images are snapshots of post-installation state.
    * User 'miles' with password '12345', can `sudo` without password.
    * User 'root' with password '12345' (or no password on MINIX,Hurd)
    * SSH server runs on port 22, `pretest-run.sh` script redirects it to
      to host's port 2222 (or another port with `-p`)
    * VMs are configured to use serial console, compatible with QEMU's
      `-nographic` and `-serial mon:stdio` options.

* **build-ready** images are snapshots of post-build-tools installation state.
    * Have C/C++ compilers (gcc or clang)
    * autoconf,automake,make
    * git,wget,rsync
    * pre-configured to compile autotools-based projects, such as:

        ```
        wget http://ftp.gnu.org/gnu/hello/hello-2.9.tar.gz
        tar xzf hello-2.9.tar.gz
        cd hello-2.9
        ./configure
        make
        make check
        ```

* **Compilers-pack** image is Debian-based installation pre-configured with
  cross-compilers for ARM,MIPS,PowerPC and binfmt/qemu-static setup.

See detailed version information at <http://www.nongnu.org/pretest/versions/>

Read the manual for detailed setup information and usage examples:
<http://www.nongnu.org/pretest/manual/>

## Available Pre-Configured VM images

* CentOS 7.0, 6.5
* Fedora 21, 20
* Debian 7.6
* gNewSense 3.1 (based on Debian 6)
* OpenSUSE 13.2, 13.1
* Ubuntu 14.04.1, 15.04
* Trisquel 6.0.1 (based on Ubuntu 12.04 LTS), 7 (=Ubuntu 14.04.1 LTS)
* DilOS 1.3.7.18 (Illumous/OpenSolaris-based system)
* FreeBSD 10.1, 10, 9.3
* NetBSD 6.1.4
* OpenBSD 5.5, 5.6
* GNU-Hurd (Debian/Hurd) 0.5, 0.6
* MINIX R3.3.0
* OpenIndiana 151a8 (OpenSolaris-like system, running SunOS 5.11)
* Debian 7 GNU/kFreeBSD (GNU userspace with FreeBSD kernel)

See download page for more information: <http://www.nongnu.org/pretest/downloads/>

## Contact

Home page: <http://www.nongnu.org/pretest/>

For bug-reports, suggestions, comments and patches, please send emails to
*pretest-users at nongnu.org*.

To subscribe to the mailing list, visit:
<https://lists.nongnu.org/mailman/listinfo/pretest-users>

To view/search past discussions, visit:
<http://lists.nongnu.org/archive/html/pretest-users>

## License

* Shell/Perl scripts: [GPLv3+](http://www.gnu.org/licenses/gpl.html)
* Cookbook Texinfo document: Dual License:
  [CC-BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/), and
  [GFDL 1.3+](http://www.gnu.org/copyleft/fdl.html)
* Operation System Virtual Machine Images:  
    Each operating system use a mixture of Free-Software licenses.  
    Where an operating system offers non-free software options,
    those were removed. See the license for the relevant OSes:

    * Debian: <https://www.debian.org/legal/licenses/> (Only *main* repository used)
    * Ubuntu: <http://www.ubuntu.com/about/about-ubuntu/licensing> (only *main* and *universe* repositories used)
    * CentOS: GPL + others (link?)
    * Fedora: <https://fedoraproject.org/wiki/Licensing:Main?rd=Licensing>
    * Hurd: GPL + others (link?)
    * MINIX: <http://www.minix3.org/other/license.html>
    * DilOS: <http://www.dilos.org/license>
    * OpenBSD: <http://www.openbsd.org/policy.html>
    * FreeBSD: <https://www.freebsd.org/copyright/freebsd-license.html>
    * NetBSD: <http://www.netbsd.org/about/redistribution.html>
    * OpenSUSE: <https://en.opensuse.org/openSUSE:License>
    * Trisquel: <http://trisquel.info/en/under-what-license-trisquel-distributed>
    * gNewSense: <http://www.gnewsense.org/Licenses>
    * OpenIndiana: <http://wiki.openindiana.org/pages/viewpage.action?pageId=1048863>

    If you spot a non-free software in those pre-build images, please send
    a bug report to *pretest-users at nongnu.org*.
