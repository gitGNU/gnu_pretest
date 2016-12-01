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

* [OpenBSD 6.0](http://files.housegordon.org/pretest/v0.1/openbsd60.clean-install.qcow2.xz)
* [OpenBSD 5.9](http://files.housegordon.org/pretest/v0.1/openbsd59.clean-install.qcow2.xz)
* [OpenBSD 5.8](http://files.housegordon.org/pretest/v0.1/openbsd58.clean-install.qcow2.xz)
* [OpenBSD 5.7](http://files.housegordon.org/pretest/v0.1/openbsd57.clean-install.qcow2.xz)
* [OpenBSD 5.6](http://files.housegordon.org/pretest/v0.1/openbsd56.clean-install.qcow2.xz)
* [OpenBSD 5.5](http://files.housegordon.org/pretest/v0.1/openbsd55.clean-install.qcow2.xz)
* [NetBSD 7.0](http://files.housegordon.org/pretest/v0.1/netbsd70.clean-install.qcow2.xz)
* [NetBSD 6.1.4](http://files.housegordon.org/pretest/v0.1/netbsd614.clean-install.qcow2.xz)
* [FreeBSD 11-p1](http://files.housegordon.org/pretest/v0.1/freebsd11p1.clean-install.qcow2.xz)
* [FreeBSD 10.3](http://files.housegordon.org/pretest/v0.1/freebsd103.clean-install.qcow2.xz)
* [FreeBSD 10.1](http://files.housegordon.org/pretest/v0.1/freebsd101.clean-install.qcow2.xz)
* [FreeBSD 10](http://files.housegordon.org/pretest/v0.1/freebsd10.clean-install.qcow2.xz)
* [FreeBSD 9.3](http://files.housegordon.org/pretest/v0.1/freebsd93.clean-install.qcow2.xz)
* [MINIX R3.3.0](http://files.housegordon.org/pretest/v0.1/minixR330.clean-install.qcow2.xz)
* [GNU Hurd/Debian 0.6](http://files.housegordon.org/pretest/v0.1/hurd06.clean-install.qcow2.xz)
* [GNU Hurd/Debian 0.7](http://files.housegordon.org/pretest/v0.1/hurd07.clean-install.qcow2.xz)
* [MirBSD 10](http://files.housegordon.org/pretest/v0.1/mirbsd10.clean-install.qcow2.xz)
* [Debian 8.1](http://files.housegordon.org/pretest/v0.1/debian81.clean-install.qcow2.xz)
* [Debian 7.6](http://files.housegordon.org/pretest/v0.1/debian76.clean-install.qcow2.xz)
* [gNewSense 3.1](http://files.housegordon.org/pretest/v0.1/gnewsense31.clean-install.qcow2.xz)
* [CentOS 7.0](http://files.housegordon.org/pretest/v0.1/centos7.clean-install.qcow2.xz)
* [CentOS 6.5](http://files.housegordon.org/pretest/v0.1/centos6.5.clean-install.qcow2.xz)
* [Fedora 25](http://files.housegordon.org/pretest/v0.1/fedora25.clean-install.qcow2.xz)
* [Fedora 24](http://files.housegordon.org/pretest/v0.1/fedora24.clean-install.qcow2.xz)
* [Fedora 23](http://files.housegordon.org/pretest/v0.1/fedora23.clean-install.qcow2.xz)
* [Fedora 22](http://files.housegordon.org/pretest/v0.1/fedora22.clean-install.qcow2.xz)
* [Fedora 21](http://files.housegordon.org/pretest/v0.1/fedora21.clean-install.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora20.clean-install.qcow2.xz)
* [Ubuntu 16.04](http://files.housegordon.org/pretest/v0.1/ubuntu1604.clean-install.qcow2.xz)
* [Ubuntu 15.04](http://files.housegordon.org/pretest/v0.1/ubuntu15.clean-install.qcow2.xz)
* [Ubuntu 14.04.1](http://files.housegordon.org/pretest/v0.1/ubuntu14.clean-install.qcow2.xz)
* [Trisquel 6.0.1](http://files.housegordon.org/pretest/v0.1/trisquel601.clean-install.qcow2.xz)
* [Trisquel 7](http://files.housegordon.org/pretest/v0.1/trisquel7.clean-install.qcow2.xz)
* [OpenSUSE 42.1 (LEAP)](http://files.housegordon.org/pretest/v0.1/opensuse421.clean-install.qcow2.xz)
* [OpenSUSE 13.2](http://files.housegordon.org/pretest/v0.1/opensuse132.clean-install.qcow2.xz)
* [OpenSUSE 13.1](http://files.housegordon.org/pretest/v0.1/opensuse131.clean-install.qcow2.xz)
* [DilOS 1.3.7](http://files.housegordon.org/pretest/v0.1/dilos137.clean-install.qcow2.xz)
* [OpenIndiana 151a8](http://files.housegordon.org/pretest/v0.1/openindiana151a8.clean-install.qcow2.xz)
* [Debian 7 GNU/kFreeBSD](http://files.housegordon.org/pretest/v0.1/debian7-kfreebsd.clean-install.qcow2.xz)
* [Alpine-3.3.3](http://files.housegordon.org/pretest/v0.1/alpine-3.3.3.clean-install.qcow2.xz)

## Build-Ready images

* [OpenBSD 6.0](http://files.housegordon.org/pretest/v0.1/openbsd60.build-ready.qcow2.xz)
* [OpenBSD 5.9](http://files.housegordon.org/pretest/v0.1/openbsd59.build-ready.qcow2.xz)
* [OpenBSD 5.8](http://files.housegordon.org/pretest/v0.1/openbsd58.build-ready.qcow2.xz)
* [OpenBSD 5.7](http://files.housegordon.org/pretest/v0.1/openbsd57.build-ready.qcow2.xz)
* [OpenBSD 5.6](http://files.housegordon.org/pretest/v0.1/openbsd56.build-ready.qcow2.xz)
* [OpenBSD 5.5](http://files.housegordon.org/pretest/v0.1/openbsd55.build-ready.qcow2.xz)
* [NetBSD 7.0](http://files.housegordon.org/pretest/v0.1/netbsd70.build-ready.qcow2.xz)
* [NetBSD 6.1.4](http://files.housegordon.org/pretest/v0.1/netbsd614.build-ready.qcow2.xz)
* [FreeBSD 11-p1](http://files.housegordon.org/pretest/v0.1/freebsd11p1.build-ready.qcow2.xz)
* [FreeBSD 10.3](http://files.housegordon.org/pretest/v0.1/freebsd103.build-ready.qcow2.xz)
* [FreeBSD 10.1](http://files.housegordon.org/pretest/v0.1/freebsd101.build-ready.qcow2.xz)
* [FreeBSD 10](http://files.housegordon.org/pretest/v0.1/freebsd10.build-ready.qcow2.xz)
* [FreeBSD 9.3](http://files.housegordon.org/pretest/v0.1/freebsd93.build-ready.qcow2.xz)
* [MINIX R3.3.0](http://files.housegordon.org/pretest/v0.1/minixR330.build-ready.qcow2.xz)
* [GNU Hurd/Debian 0.5](http://files.housegordon.org/pretest/v0.1/hurd.build-ready.qcow2.xz)
* [GNU Hurd/Debian 0.6](http://files.housegordon.org/pretest/v0.1/hurd06.build-ready.qcow2.xz)
* [GNU Hurd/Debian 0.7](http://files.housegordon.org/pretest/v0.1/hurd07.build-ready.qcow2.xz)
* [MirBSD 10](http://files.housegordon.org/pretest/v0.1/mirbsd10.build-ready.qcow2.xz)
* [Debian 8.1](http://files.housegordon.org/pretest/v0.1/debian81.build-ready.qcow2.xz)
* [Debian 7.6](http://files.housegordon.org/pretest/v0.1/debian76.build-ready.qcow2.xz)
* [Debian Compilers Pack](http://files.housegordon.org/pretest/v0.1/debian76.compilers-pack.qcow2.xz)
* [gNewSense 3.1](http://files.housegordon.org/pretest/v0.1/gnewsense31.build-ready.qcow2.xz)
* [CentOS 7.0](http://files.housegordon.org/pretest/v0.1/centos7.build-ready.qcow2.xz)
* [CentOS 6.5](http://files.housegordon.org/pretest/v0.1/centos6.5.build-ready.qcow2.xz)
* [Fedora 25](http://files.housegordon.org/pretest/v0.1/fedora25.build-ready.qcow2.xz)
* [Fedora 24](http://files.housegordon.org/pretest/v0.1/fedora24.build-ready.qcow2.xz)
* [Fedora 23](http://files.housegordon.org/pretest/v0.1/fedora23.build-ready.qcow2.xz)
* [Fedora 22](http://files.housegordon.org/pretest/v0.1/fedora22.build-ready.qcow2.xz)
* [Fedora 21](http://files.housegordon.org/pretest/v0.1/fedora21.build-ready.qcow2.xz)
* [Fedora 20](http://files.housegordon.org/pretest/v0.1/fedora20.build-ready.qcow2.xz)
* [Ubuntu 16.04](http://files.housegordon.org/pretest/v0.1/ubuntu1604.build-ready.qcow2.xz)
* [Ubuntu 15.04](http://files.housegordon.org/pretest/v0.1/ubuntu15.build-ready.qcow2.xz)
* [Ubuntu 14.04.1](http://files.housegordon.org/pretest/v0.1/ubuntu14.build-ready.qcow2.xz)
* [Trisquel 6.0.1](http://files.housegordon.org/pretest/v0.1/trisquel601.build-ready.qcow2.xz)
* [Trisquel 7](http://files.housegordon.org/pretest/v0.1/trisquel7.build-ready.qcow2.xz)
* [OpenSUSE 42.1 (LEAP)](http://files.housegordon.org/pretest/v0.1/opensuse421.build-ready.qcow2.xz)
* [OpenSUSE 13.2](http://files.housegordon.org/pretest/v0.1/opensuse132.build-ready.qcow2.xz)
* [OpenSUSE 13.1](http://files.housegordon.org/pretest/v0.1/opensuse131.build-ready.qcow2.xz)
* [DilOS 1.3.7](http://files.housegordon.org/pretest/v0.1/dilos137.build-ready.qcow2.xz)
* [OpenIndiana 151a8](http://files.housegordon.org/pretest/v0.1/openindiana151a8.build-ready.qcow2.xz)
* [Debian 7 GNU/kFreeBSD](http://files.housegordon.org/pretest/v0.1/debian7-kfreebsd.build-ready.qcow2.xz)
* [Alpine-3.3.3](http://files.housegordon.org/pretest/v0.1/alpine-3.3.3.build-ready.qcow2.xz)
