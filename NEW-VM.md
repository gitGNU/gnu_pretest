Steps for adding a new VM/OS:

1. Create 'build_scripts/build_XXXX.sh' script .

2. Create the new VM, document 'setup' step, save 'clean install' QCOW2.

3. Re-run VM without snapshot, add build tools, using:

        ./pretest-run.pl --console -S xxxx.qcow2

    `--console` is required instead of `--ssh` (the default), otherwise the
    VM will shutdown upon SSH logoff, without proper shutdown.

4. copy `misc_scripts/pretest-auto-check-build` and
   `misc_scripts/pretest-guest-init` to the guest VM:

        # Find the SSH forwarded port number
        $ ps ax | grep qemu
        [...] hostfwd=tcp:127.0.0.1:1025-:22 [...]

        # Copy the files
        $ scp -o Port=1025 \
              misc_scripts/pretest-auto-build-check \
              misc_scripts/pretest-guest-init \
           miles@localhost:
        The authenticity of host '[localhost]:1025 ([127.0.0.1]:1025)' can't be established.
        ECDSA key fingerprint is e4:f7:1b:4b:c9:f9:42:e1:ca:99:36:ca:61:1c:2b:9c.
        Are you sure you want to continue connecting (yes/no)? yes
        Warning: Permanently added '[localhost]:1025' (ECDSA) to the list of known hosts.
        Password for miles@freebsd101:
        pretest-auto-build-check                                      100% 8807     8.6KB/s   00:00
        pretest-guest-init                                            100% 7655     7.5KB/s   00:00

    Inside the VM, copy the scripts to `/usr/local/bin`:

        sudo mv ~miles/pretest* /usr/local/bin/
        sudo chmod a+x /usr/local/bin/pretest-*

5. Add the `pretest-guest-init` script to the boot sequence (OS-specific)

6. Boot the 'build-ready' VM in snapshot mode, and check the required programs:

        make,gmake,cc,gcc,clang,autoconf,automake,autopoint,git,etc.

   Test building GNU packages, from tarballs and git:

        pretest-auto-build-check http://ftp.gnu.org/gnu/hello/hello-2.9.tar.gz
        pretest-auto-build-check http://ftp.gnu.org/gnu/coreutils/coreutils-8.23.tar.xz
        pretest-auto-build-check git://git.sv.gnu.org/datamash.git

7. Update doc/vm-sizes

    $ ./misc_scripts/collect-image-sizes.sh images-v0.1/trisquel7*
    trisquel7.build-ready.qcow2.xz      301M  1.5G
    trisquel7.clean-install.qcow2.xz    188M  1.1G

   Add the above two lines to 'doc/vm-size' and re-sort.

8. Update versions/OS.hs   using misc_scripts/get-versions.sh

    $ ./pretest-run.pl \
        workdir/trisquel7.build-ready.qcow2 \
        < misc_scripts/get-versions.sh > versions/trisquel7.txt
    Pseudo-terminal will not be allocated because stdin is not a terminal.
    Warning: Permanently added '[127.0.0.1]:1025' (ECDSA) to the list of known hosts.
    miles@127.0.0.1's password: ### Enter '12345'

  Manually inspect `versions/trisquel7.txt` - remove any login messages.
  First line should be 'autoconf-version', and there should be just 19 lines:

    $ wc -l versions/*.txt
       19 versions/centos65.txt
       19 versions/centos7.txt
       19 versions/debian76.txt
       19 versions/dilos137.txt
       19 versions/fedora20.txt
       19 versions/freebsd10.txt
       19 versions/freebsd93.txt
       <...>

9. run `./misc_scripts/build-os-versions-table.sh` ,
   then inspect `./os-versions.html`.

10. Update 'README.md', add new OS/version.

11. Update 'download.md', add new qcow2.xz URLs.

12. run `make website` to re-generate some index files.

13. Manually inspect the updates:

    meld web/ ../pretest-website/pretest/

    Ensure that 'downloads/index.html' is NOT modified (or doesn't exist)
    in ./web/ - it must be manually updated.

14. Update the website files:

    cp -r web/* ../pretest-website/pretest/

15. manually update `../pretest-website/pretest/downloads/index.html` with
    the URLs and sizes of the new OS/vm.

16. Inspect changes in source code 'git' repository, and commit the
    appropriate files:

        $ git status --short
        M  README.md
        A  build_scripts/build_trisquel7.sh
        M  doc/vm-sizes.txt
        M  downloads.md
        A  versions/trisquel7.txt

        $ git commit
        $ git push hg
        $ git push gnu

17. Commit the changes to the website:

        $ cd ../pretest-website/pretest
        $ cvs diff --brief
        $ cvs diff -u

        $ cvs commit

