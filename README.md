# PreTest - Pre-Release Portability Testing VMs

PreTest's goal is to provide pre-built virtual-machine images of Free-Software
POSIX-compliant operating systems, ready for testing *autotools*-based programs.

Typical usage:

    # Download a VM image
    wget http://files.housegordon.org/pretest/v0.1/freebsd10.build-ready.qcow2.xz
    unxz freebsd10.build-ready.qcow2.xz

    # Run with KVM
    kvm -nographic -m 384 \
        -snapshot \
        -net user -net nic,model=virtio \
        -drive if=virtio,media=disk,index=0,file=freebsd10.build-ready-v1.qcow2

    # For more KVM options, use the supplied helper script
    ./run_scripts/pretest_run.sh freebsd10.build-ready.v1.qcow2

All VMs have user 'miles' with password '12345' and 'sudo' (or 'su') access.

## Setup Details

Read the manual for detailed setup information and usage examples.

'clean-install' images are snapshots of post-installation state.  
'build-ready' images are snapshots of post-build-tools installation state.

## Available VM images

* CentOS 6.5:
[clean-install](http://files.housegordon.org/pretest/v0.1/centos6.5.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/centos6.5.build-ready.qcow2.xz)

* CentOS 7.0
[clean-install](http://files.housegordon.org/pretest/v0.1/centos7.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/centos7.build-ready.qcow2.xz)

* Debian 7.6:
[clean-install](http://files.housegordon.org/pretest/v0.1/debian76.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/debian76.build-ready.qcow2.xz),
[cross-compilers-pack](http://files.housegordon.org/pretest/v0.1/debian76.compilers-pack.qcow2.xz)

* DilOS 1.3.7.18:
[clean-install](http://files.housegordon.org/pretest/v0.1/dilos137.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/dilos137.build-ready.qcow2.xz)

* FreeBSD 10:
[clean-install](http://files.housegordon.org/pretest/v0.1/freebsd10.clearn-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/freebsd10.build-ready.qcow2.xz)

* GNU-Hurd 0.5/Debian:
[build-ready](http://files.housegordon.org/pretest/v0.1/hurd.build-ready.qcow2.xz)


* MINIX R3.3.0:
[clean-install](http://files.housegordon.org/pretest/v0.1/minixR330.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/minixR330.build-ready-v1.qcow2.xz)

* NetBSD 6.1.4:
[clean-install](http://files.housegordon.org/pretest/v0.1/netbsd614.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/netbsd614.build-ready.qcow2.xz)

* OpenBSD 5.5:
[clean-install](http://files.housegordon.org/pretest/v0.1/openbsd55.clean-install.qcow2.xz),
[build-ready](http://files.housegordon.org/pretest/v0.1/openbsd55.build-ready.qcow2.xz)

* Ubuntu 14.04.1:
[clean-install](http://files.housegordon.org/pretest/v0.1/ubuntu14.clean-install.qcow2.xz)
[build-ready](http://files.housegordon.org/pretest/v0.1/ubuntu14.build-ready.qcow2.xz)

## License

* Shell/Perl scripts: [GPLv3+](http://www.gnu.org/licenses/gpl.html)
* Cookbook Texinfo document: [CC-BY-SA 4.0](http://creativecommons.org/licenses/by-sa/4.0/)
* Operation System Virtual Machine Images:  
    Each operating system use a mixture of Free-Software license.  
    Where an operating system offers non-free software options,
    those were removed. See the license for the relevant OSes:

    * Debian: <https://www.debian.org/legal/licenses/> (Only *main* repository used)
    * Ubuntu: <http://www.ubuntu.com/about/about-ubuntu/licensing> (only *main* and *universe* repositories used)
    * CentOS: GPL + others (link?)
    * Hurd: GPL + others (link?)
    * MINIX: <http://www.minix3.org/other/license.html>
    * DilOS: <http://www.dilos.org/license>
    * OpenBSD: <http://www.openbsd.org/policy.html>
    * FreeBSD: <https://www.freebsd.org/copyright/freebsd-license.html>
    * NetBSD: <http://www.netbsd.org/about/redistribution.html>

    If you spot a non-free software in those pre-build images, please send
    a bug report.
