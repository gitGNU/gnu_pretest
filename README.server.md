# Pretest Reports Server

The script `pretest-auto-build-check` collects all logs
of the build steps (configure/make/make-check), creates
a tarball with the logs and some additional information,
and can optionally upload the tarball to a remote server.

The script `server/pretest-server.py` is a python/flask
application which can accept uploaded tarballs from
the `pretest-auto-build-check` script, parse the results
and display summary of the build (as well as offer to
download the tarball as is).

## Public Server

There is a public server running at http://pretest.housegordon.org .
You can build a tarball and send results to the server with:

    pretest-auto-build-check \
              -r http://pretest.housegordon.org/upload \
              http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz

NOTE:
This public server comes with absolutely no guarentees what-so-ever.
Data might be deleted without warning.

## Local Flow Example

1.  In one terminal window, run the flask application:

        $ cd server

        # create a directory to store the uploaded tarfiles
        $ mkdir tarfiles

        # Run the server directly at least once, to create
        # the empty sqlite3 database file (pretest.db):
        $ python pretest-server --debug
        pretest-server.py
        * Running on http://127.0.0.1:5167/ (Press CTRL+C to quit)

2.  Visit <http://127.0.0.1:5167> to view the simple interface.

3.  Experiment with a build (on your local machine), run:

        $ ./misc_scripts/pretest-auto-build-check \
              -r http://127.0.0.1/upload \
              http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz

    Will download `hello-2.8.tar.gz` and will try to build it
    on your local machine. When build is complete (pass or fail),
    the results will be uploaded to the running flask application.

4.  When combining with pretest images (under QEMU/KVM), use the following
    command line:

        $ ./pretest-run.pl IMAGE.build-ready.qcow2 -- \
                pretest-auto-build-check \
                     -r http://10.0.2.2:5167/upload \
                        http://ftp.gnu.org/gnu/hello/hello-2.8.tar.gz

    Note the following: use `10.0.2.2` IP address, as inside the QEMU
    guest it is mapped to the host's `127.0.0.1`. Use `--` to
    ensure the `-r` parameter is not mistakingly parsed by `pretest-run.pl`.

## Public Server Setup

Typically the server would run behind a front-end HTTP server (e.g. nginx)
and using a more robust framework (e.g. `gunicorn`).

Example: run the server under `gunicorn` with unix-sockets:

    # Run one directly, to create the database file, and create the
    # tarfiles directory
    $ mkdir tarfiles
    $ python ./pretest-server.py

    # Then run with gunicorn (as root):
    $ gunicorn --bind unix:/var/run/pretest-server.sock \
              --access-logfile /var/log/pretest.access.log \
              --error-logfile /var/log/pretest.error.log \
              --chdir /home/user/pretest \
              --user user --group user \
              --daemon \
              pretest-server:app

A typical NGINX configuration would be:

    upstream pretest {
        server unix:/var/run/pretest-server.sock;
    }
    server {
        listen 80;
        server_name pretest.example.org;
        client_max_body_size 1m;
        root /var/www/index.html;
        location / {
            proxy_pass http://pretest;
            proxy_set_header Host            $host;
            proxy_set_header X-Forwarded-For $remote_addr;
        }
    }

