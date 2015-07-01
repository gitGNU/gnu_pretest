# PreTest - Available VM Downloads

PreTest's goal is to provide pre-built virtual-machine images of Free-Software POSIX-compliant operating systems, ready for testing autotools-based programs.

Learn more at <http://www.nongnu.org/pretest/>

## Basic Usage

    # Download a VM image
    wget http://files.housegordon.org/pretest/v0.1/freebsd10.build-ready.qcow2.xz
    unxz freebsd10.build-ready.qcow2.xz

    # Run with KVM
    kvm -nographic -m 384 \
        -snapshot \
        -net user -net nic,model=virtio \
        -drive if=virtio,media=disk,index=0,file=freebsd10.build-ready.qcow2

    # For more KVM options, use the supplied helper script
    ./pretest-run.sh freebsd10.build-ready.qcow2

For easier start-up, use the [pretest-run.sh](http://git.savannah.gnu.org/cgit/pretest.git/tree/pretest-run.sh) script.

## Clean-Install images

* [OpenBSD 5.5](http://files.housegordon.org/pretest/v0.1/openbsd55.clean-install.qcow2.xz)
* [OpenBSD 5.6](http://files.housegordon.org/pretest/v0.1/openbsd56.clean-install.qcow2.xz)
* [OpenBSD 5.7](http://files.housegordon.org/pretest/v0.1/openbsd57.clean-install.qcow2.xz)
* [NetBSD 6.1.4](http://files.housegordon.org/pretest/v0.1/netbsd614.clean-install.qcow2.xz)
* [FreeBSD 10.1](http://files.housegordon.org/pretest/v0.1/freebsd101.clean-install.qcow2.xz)
* [FreeBSD 10](http://files.housegordon.org/pretest/v0.1/freebsd10.clean-install.qcow2.xz)
* [FreeBSD 9.3](http://files.housegordon.org/pretest/v0.1/freebsd93.clean-install.qcow2.xz)
* [MINIX R3.3.0](http://files.housegordon.org/pretest/v0.1/minixR330.clean-install.qcow2.xz)
* [GNU Hurd/Debian 0.6](http://files.housegordon.org/pretest/v0.1/hurd06.clean-install.qcow2.xz)
* [Debian 8.1](http://files.housegordon.org/pretest/v0.1/debian81.clean-install.qcow2.xz)
* [Debian 7.6](http://files.housegordon.org/pretest/v0.1/debian76.clean-install.qcow2.xz)
* [gNewSense 3.1](http://files.housegordon.org/pretest/v0.1/gnewsense31.clean-install.qcow2.xz)
* [CentOS 7.0](http://files.housegordon.org/pretest/v0.1/centos7.clean-install.qcow2.xz)
* [CentOS 6.5](http://files.housegordon.org/pretest/v0.1/centos6.5.clean-install.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora21.clean-install.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora20.clean-install.qcow2.xz)
* [Ubuntu 14.04.1](http://files.housegordon.org/pretest/v0.1/ubuntu14.clean-install.qcow2.xz)
* [Ubuntu 15.04](http://files.housegordon.org/pretest/v0.1/ubuntu15.clean-install.qcow2.xz)
* [Trisquel 6.0.1](http://files.housegordon.org/pretest/v0.1/trisquel601.clean-install.qcow2.xz)
* [Trisquel 7](http://files.housegordon.org/pretest/v0.1/trisquel7.clean-install.qcow2.xz)
* [OpenSUSE 13.2](http://files.housegordon.org/pretest/v0.1/opensuse132.clean-install.qcow2.xz)
* [OpenSUSE 13.1](http://files.housegordon.org/pretest/v0.1/opensuse131.clean-install.qcow2.xz)
* [DilOS 1.3.7](http://files.housegordon.org/pretest/v0.1/dilos137.clean-install.qcow2.xz)
* [OpenIndiana 151a8](http://files.housegordon.org/pretest/v0.1/openindiana151a8.clean-install.qcow2.xz)
* [Debian 7 GNU/kFreeBSD](http://files.housegordon.org/pretest/v0.1/debian7-kfreebsd.clean-install.qcow2.xz)

## Build-Ready images

* [OpenBSD 5.5](http://files.housegordon.org/pretest/v0.1/openbsd55.build-ready.qcow2.xz)
* [OpenBSD 5.6](http://files.housegordon.org/pretest/v0.1/openbsd56.build-ready.qcow2.xz)
* [OpenBSD 5.7](http://files.housegordon.org/pretest/v0.1/openbsd57.build-ready.qcow2.xz)
* [NetBSD 6.1.4](http://files.housegordon.org/pretest/v0.1/netbsd614.build-ready.qcow2.xz)
* [FreeBSD 10.1](http://files.housegordon.org/pretest/v0.1/freebsd101.build-ready.qcow2.xz)
* [FreeBSD 10](http://files.housegordon.org/pretest/v0.1/freebsd10.build-ready.qcow2.xz)
* [FreeBSD 9.3](http://files.housegordon.org/pretest/v0.1/freebsd93.build-ready.qcow2.xz)
* [MINIX R3.3.0](http://files.housegordon.org/pretest/v0.1/minixR330.build-ready.qcow2.xz)
* [GNU Hurd/Debian 0.5](http://files.housegordon.org/pretest/v0.1/hurd.build-ready.qcow2.xz)
* [GNU Hurd/Debian 0.6](http://files.housegordon.org/pretest/v0.1/hurd06.build-ready.qcow2.xz)
* [Debian 8.1](http://files.housegordon.org/pretest/v0.1/debian81.build-ready.qcow2.xz)
* [Debian 7.6](http://files.housegordon.org/pretest/v0.1/debian76.build-ready.qcow2.xz)
* [Debian Compilers Pack](http://files.housegordon.org/pretest/v0.1/debian76.compilers-pack.qcow2.xz)
* [gNewSense 3.1](http://files.housegordon.org/pretest/v0.1/gnewsense31.build-ready.qcow2.xz)
* [CentOS 7.0](http://files.housegordon.org/pretest/v0.1/centos7.build-ready.qcow2.xz)
* [CentOS 6.5](http://files.housegordon.org/pretest/v0.1/centos6.5.build-ready.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora21.build-ready.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora20.build-ready.qcow2.xz)
* [Ubuntu 14.04.1](http://files.housegordon.org/pretest/v0.1/ubuntu14.build-ready.qcow2.xz)
* [Ubuntu 15.04](http://files.housegordon.org/pretest/v0.1/ubuntu15.build-ready.qcow2.xz)
* [Trisquel 6.0.1](http://files.housegordon.org/pretest/v0.1/trisquel601.build-ready.qcow2.xz)
* [Trisquel 7](http://files.housegordon.org/pretest/v0.1/trisquel7.build-ready.qcow2.xz)
* [OpenSUSE 13.2](http://files.housegordon.org/pretest/v0.1/opensuse132.build-ready.qcow2.xz)
* [OpenSUSE 13.1](http://files.housegordon.org/pretest/v0.1/opensuse131.build-ready.qcow2.xz)
* [DilOS 1.3.7](http://files.housegordon.org/pretest/v0.1/dilos137.build-ready.qcow2.xz)
* [OpenIndiana 151a8](http://files.housegordon.org/pretest/v0.1/openindiana151a8.build-ready.qcow2.xz)
* [Debian 7 GNU/kFreeBSD](http://files.housegordon.org/pretest/v0.1/debian7-kfreebsd.build-ready.qcow2.xz)
