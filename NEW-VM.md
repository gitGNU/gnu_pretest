Steps for adding a new VM/OS:

1. Create 'build_scripts/build_XXXX.sh' script .

2. Create the new VM, document 'setup' step, save 'clean install' QCOW2.

3. Re-run VM without snapshot, add build tools, using:

        ./pretest-run.pl --console -S -p 1025 xxxx.qcow2

    `--console` is required instead of `--ssh` (the default), otherwise the
    VM will shutdown upon SSH logoff, without proper shutdown.

    To shutdown and save changes, run `shutdown` or `/sbin/halt` (or another
    appropriate command for the OS).

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
        Password for miles@freebsd101:
        pretest-auto-build-check                                      100% 8807     8.6KB/s   00:00
        pretest-guest-init                                            100% 7655     7.5KB/s   00:00

    Inside the VM, copy the scripts to `/usr/local/bin`:

        sudo mv ~miles/pretest* /usr/local/bin/
        sudo chmod a+x /usr/local/bin/pretest-*
        sudo chown root:root /usr/local/bin/pretest-*

5. Add the `pretest-guest-init` script to the boot sequence (OS-specific)

6. Boot the 'build-ready' VM in snapshot mode, and check the required programs:

        make,gmake,cc,gcc,clang,autoconf,automake,autopoint,git
        bison,flex,patch
        etc.

   Test building GNU packages, from tarballs and git:

        pretest-auto-build-check http://ftp.gnu.org/gnu/hello/hello-2.9.tar.gz
        pretest-auto-build-check http://ftp.gnu.org/gnu/coreutils/coreutils-8.23.tar.xz
        pretest-auto-build-check git://git.sv.gnu.org/coreutils.git
        pretest-auto-build-check git://git.sv.gnu.org/datamash.git

7. Test the images with `--console` to ensure console log messages and getty
   are properly set:

        ./pretest-run.pl --console freebsd101.clean-install.qcow2

8. Test the image with `--ssh` (the default, with no options) to ensure SSH
   is properly configured (e.g. firewall + openssh on OpenSUSE):

        ./pretest-run.pl freebsd101.clean-install.qcow2

9. Test login with user 'miles' password '12345', ensure `sudo` works without
   requiring a password

10. Update `versions/XXX` using `misc_scripts/get-versions.sh`

    $ ./pretest-run.pl \
        workdir/trisquel7.build-ready.qcow2 \
        < misc_scripts/get-versions.sh > versions/trisquel7.txt
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

  If any program is missing (e.g. `autoconf` or `make` or `makeinfo`), go back
  and install them in the build-ready image.

11. run `./misc_scripts/build-os-versions-table.sh` ,
   then inspect `./os-versions.html`.

12. For GNU/Linux (or other compatible OS/Filesystems), use "virt-sparsify" to
   reduce the size of the QCOW2 image before compression:

        sudo virt-sparsify freebsd101.clean-install.qcow2 \
                           freebsd101.clean-install.sparse.qcow2

   Test the sparsified-qcow2 image, ensuring it can still boot:

        ./pretest-run.pl freebsd101.clean-install.sparse.qcow2

   If it boots - good. Use it.
   If it doesn't - discard it and use the non-sparse qcow2 file.

13. Compress the qcow2 images

        xz -T3 < freebsd101.clean-install.sparse.qcow2 \
               > images-v0.1/freebsd101.clean-install.qcow2.xz
        xz -T3 < freebsd101.build-ready.sparse.qcow2 \
               > images-v0.1/freebsd101.build-ready.qcow2.xz

14. Upload images

        hgfiles-upload.sh images-v0.1/freebsd101.clean-install.qcow2.xz pretest/v0.1
        hgfiles-upload.sh images-v0.1/freebsd101.build-ready.qcow2.xz pretest/v0.1

15. Update doc/vm-sizes

    $ ./misc_scripts/collect-image-sizes.sh images-v0.1/trisquel7*
    trisquel7.build-ready.qcow2.xz      301M  1.5G
    trisquel7.clean-install.qcow2.xz    188M  1.1G

   Add the above two lines to 'doc/vm-size' and re-sort.

16. Update 'README.md', add new OS/version.

17. Update 'download.md', add new qcow2.xz URLs.

18. run `make website` to re-generate some index files.

19. Manually inspect the updates:

    meld web/ ../pretest-website/pretest/

    Ensure that 'index.htmk' 'downloads/index.html' are NOT modified
    (or doesn't exist) in ./web/ - it must be manually updated.

20. Update the website files:

    cp -r web/* ../pretest-website/pretest/

21. manually update `../pretest-website/pretest/downloads/index.html` with
    the URLs and sizes of the new OS/vm.
    manually update `../pretest-website/pretest/index.html` with
    the version numbers of the new VMs.
    manually update `../pretest-website/pretest/vm-images.js` with
    the new image information.

22. Inspect changes in source code 'git' repository, and commit the
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

23. Commit the changes to the website:

        $ cd ../pretest-website/pretest
        $ cvs diff --brief
        $ cvs diff -u

        $ cvs commit

