# PreTest TODO List

(in no particular order)

## Scripts Improvements

* run script:
    * Check mimimum version of `qemu-img` (use `-q` if supported).
    * Don't use `-no-kvm` for NetBSD on qemu>2.0.0
    * Add option for no-network (or atleast no SSH redirection)

* auto-logins: Find a way to use `sshpass` with all VMs.

    sshpass -p "12345" ssh -p 2222 -o StrictHostKeyChecking=no miles@localhost

* Use different SSH redirection ports for each VM.

* Use 'misc_scripts/auto-build-check.sh' for automated tested on each VM.
    * Save results of each step to a file (configure/make/make-check)
    * Upload files to a public server
    * Accept build/project ID
    * add SUBDIRS=. to 'make check' to avoid checking gnulib

* convert project to 'autotools', with interface such as:  
    - `pretest list`                - listing available images
    - `pretest download IMAGE`      - download an image into `/var/cache/` ?
    - `pretest run IMAGE`           - run IMAGE, with interactive shell (similar to current script)
    - `pretest run IMAGE script.sh` - run IMAGE, make it run `script.sh` after booting
    - `pretest build TEMPLATE`      - build image from template (similar to current 'build' scripts)

* Consider "Travis-CI" like YAML-based build script generator (to specify
  requirements and prerequisites, and other settings?)

* pretest-auto-build-check script:
    * Use cURL on minix instead of WGET
    * Avoid non-standard GREP on DilOS (no -E support by /bin/grep) - use
      GNU grep from another directory
    * GNU Hurd - install script in /usr/local/bin

## Guest VMs Improvements

* Enable quiet/silent boot throught grub?

* Add libz-dev

* Add mercurial, cmake, gmake in all VMs

* Add custom 'pretest-guest-shutdown' to each VM, instead of guessing the
  shutdown command in `pretest-run.sh`.

* Remove 'requiretty' from /etc/sudoers on Fedora/CentOS7

* In linuxes: add 'modprobe.blacklist=bochs_drm' and 'modprobe.blacklist=cirrus'
  to grub's default kernel command line - to enable curses (perhaps even
  doing so manually during installation?)

* Fix Terminal settings (no vt100?) to work better on xterm?

* MINIX: fix WGET, or use cURL instead.

* Communicate with host when boot process is done, and login through SSH
  when possible.  
  Perhaps with a serial device, with `tail -f` or `inotify` on host

* Fix NetBSD (boot withot `-no-kvm` on Debian7+old qemu)

* Investigate multiple serial devices.  
  <http://lists.gnu.org/archive/html/qemu-devel/2010-01/msg00458.html>

* Add `/etc/motd` in each VM, pointing back to PreTest

* Remove undeeded daemons (exim4, rpc in debian?) to save RAM and CPU.

* Remove unneeded files before packing VM image file.  
  Check out `virt-sparsify` or `virt-sysprep`.

* Add Previous stable OS versions: Debian 6, Ubuntu 12 LTS

* Add more gnu/linuxes: Arch

* Add non-amd64 VMs (debian-armbe on QEMU?)

* Cygwin VM (without Windows) ?

* More OSes: Haiku, Plan9, ReactOS, xv6, FreeRTOS ?

## Manual/Texinfo improvements

* Mention Root passwod exception: minix,hurd (no password)

* Mention no sudo on minix

* Mention `scp -o Port=2222  FILE  miles@localhost:` method to copy files.

* Change `kvm` to `qemu-syste-x86_64`

* Change `pretest-run.sh` to `pretest-run.pl`
