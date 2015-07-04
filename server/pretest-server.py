#!/usr/bin/env python

"""
This file is part of PreTest
copyright (c) 2015 Assaf Gordon (assafgordon@gmail.com)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""
import os,sys,re,json,datetime,random,string
from subprocess import Popen,PIPE
import yaml
from flask import Flask, url_for, request, g,\
                  redirect, Response, send_from_directory, \
                    render_template
from werkzeug import secure_filename
import tarfile
import sqlite3
import logging

db_filename = "pretest.db"
app_port = 5167
storage_directory = "./tarfiles/"

app = Flask(__name__)
base58 = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";
dbconn = None

def tar_read_line(tar,filename):
    f = tar.extractfile(filename)
    l = f.readline().strip()
    return l

def tar_read_dict(tar,filename,sep=":"):
    f = tar.extractfile(filename)
    d = {}
    for l in f.readlines():
        k,v = l.split(sep,1)
        k = k.strip()
        v = v.strip()
        d[k] = v
    return d

def get_system_id(ver_dict):
    lsb_id   = ver_dict.get("lsb_release-i","")
    lsb_rel  = ver_dict.get("lsb_release-r","")
    lsb_desc = ver_dict.get("lsb_release-d","")
    uname_s  = ver_dict.get("uname-s","")
    uname_r  = ver_dict.get("uname-r","")
    uname_m  = ver_dict.get("uname-m","")

    # For GNU/Linuxes, 'lsb' contains the distribution name
    # and version, which is usually informative enough.
    if lsb_id and lsb_rel:
        return "%s %s (%s)" % (lsb_id, lsb_rel, uname_m)

    # For other OSes, the kernel name and version
    # reported by uname usually corresponds with
    # the OS/distribution name.
    return "%s %s (%s)" % (uname_s, uname_r, uname_m)

def create_pretest_db(dbconn):
    # Create table
    c = dbconn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS pretest_reports
             (id integer primary key,
              timestamp integer,
              uname_s text,
              uname_r text,
              uname_m text,
              uname_p text,
              uname_i text,
              uname_o text,
              uname_v text,
              lsb_release_v text,
              lsb_release_i text,
              lsb_release_d text,
              lsb_release_r text,
              lsb_release_c text,
              system_id text,
              basename text,
              url      text,
              status   text,
              tarfile  text
                )
               ''')

def add_tar_to_db(tar,filename_on_disk):
    status = tar_read_line(tar,"logs/status")
    versions = tar_read_dict(tar,"logs/versions.txt",":")
    inputs = tar_read_dict(tar,"logs/input.txt","=")

    sys_id = get_system_id(versions)
    values = [
            versions.get("uname-s",""),
            versions.get("uname-r",""),
            versions.get("uname-m",""),
            versions.get("uname-p",""),
            versions.get("uname-i",""),
            versions.get("uname-o",""),
            versions.get("uname-v",""),
            versions.get("lsb_release-v",""),
            versions.get("lsb_release-i",""),
            versions.get("lsb_release-d",""),
            versions.get("lsb_release-r",""),
            versions.get("lsb_release-c",""),
            sys_id,
            inputs.get("BASENAME",""),
            inputs.get("SOURCE",""),
            status,
            filename_on_disk]

    c = get_db().cursor()
    c.execute('''
    insert into pretest_reports
    values (NULL,strftime('%s','now'),
            ?,?,?,?,?,?,?,
            ?,?,?,?,?,
            ?,?,?,?,?)''',
            values)
    get_db().commit()


def get_random_id(storage_dir,size=6, chars=base58):
    attempts = 5;
    while attempts>0:
        filename = ''.join(random.choice(chars) for x in range(size))
        filepath = os.path.join(storage_dir,filename)
        if not os.path.exists(filepath):
            return filepath
        attempts = attempts - 1
    err = "failed to generate unique random filename in '%s'" \
                     % ( storage_dir )
    app.logger.error(err)
    raise err

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(db_filename)
        db.row_factory = sqlite3.Row
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv

@app.route("/", methods=['GET'])
def index():
    reports = query_db('''
select id,basename,system_id,status,
        datetime(timestamp, 'unixepoch', 'localtime') as time,
        tarfile
    from pretest_reports order by timestamp desc
''')
    return render_template('index.html', reports=reports)

@app.route("/upload", methods=['POST'])
def create():
    key = None
    for k in request.files:
        if key is not None:
            return Response("found more than one key",
                            mimetime="text/plain"), 400
        key = k
        f = request.files[key]
        if not f:
            return Response("empty file",
                            mimetime="text/plain"), 400
        return save_file(f)

    txt = "missing POST parmater"
    return Response(txt,mimetype="text/plain"), 400

@app.route("/s/<id>/<filename>")
def getfile(id,filename):
    try:
        id = int(id)
    except:
        app.logger.error("got invalid ID: '%s'" % ( id ) )
        return Response("invalid ID"), 400

    reports = query_db('select basename,tarfile from pretest_reports where id = %d' % (id),one=True)
    if reports is None:
        app.logger.error("got invalid ID: '%s' (not found in DB)" % ( id ) )
        return Response("invalid ID"), 400

    base = reports['basename']
    tarfile = reports['tarfile']

    filepath = os.path.join(storage_directory,tarfile)
    if not os.path.exists(filepath):
        app.logger.error("got non-existing ID: '%s'" % ( id ) )
        return Response("invalid ID"), 400

    app.logger.info("sending file: %s" % filepath)
    return send_from_directory(storage_directory, tarfile,as_attachment=True,
                                attachment_filename=filename)

def save_file(fileobj):
    filepath = get_random_id(storage_directory)
    fileobj.save(filepath)
    id = os.path.basename(filepath)

    tar = tarfile.open(filepath, "r:bz2")
    add_tar_to_db(tar,id)
    tar.close()

    txt = url_for("getfile", _external=True, id=id, filename="dummy.tar.bz2") + "\n"
    app.logger.info("storing new file in: " + filepath)
    return Response(txt,mimetype="text/plain")

if __name__ == "__main__":
    dbconn = sqlite3.connect('pretest.db')
    create_pretest_db(dbconn)

    app.run(host='0.0.0.0',port=app_port,debug=True)

