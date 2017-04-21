#!/usr/bin/env python

import sys, re
from pprint import pprint
from jinja2 import Template

ids_file = "./doc/vm-ids.txt"
sizes_file = "./doc/vm-sizes.txt"
qemu_params_file = "./doc/vm-qemu-params.txt"

base_url = "http://files.housegordon.org/pretest/v0.1/"

templ_file = "./doc/downloads.template.html"
downloads_html_file = "./web/downloads/index.html"

vm_images_templ_file = "./doc/vm-images.template.js"
vm_images_js_file = "./web/vm-images.js"

def read_ids(f):
    """reads the vm-ids file, return a dict"""
    d = {}
    for i in open(f):
        id,name = i.strip().split(None,1)
        d[id] = { 'id' : id, 'name' : name }
    return d



def read_sizes(data,filename):
    """reads the vm-sizes file, adds info to data dict"""

    # Regexp for the filenames
    img_re = re.compile('^(.*)\.(build-ready|clean-install|compilers-pack)\.qcow2.xz$')
    size_re = re.compile('^([0-9]+)(G|M)$')

    for i in open(filename):
        img_file,xz_size,qcow_size = i.strip().split(None,2)

        # Check the filename and type
        img_parts = img_re.search(img_file)
        if not img_parts:
            sys.exit("file '%s' from sizes file does not match a known pattern" \
                     % ( img_file ))

        id = img_parts.group(1)
        typ = img_parts.group(2)
        if not (id in data):
            sys.exit("ID '%s' from file '%s' from sizes file not found in ids file" % \
                     (id, img_file))


        # Add the entry
        if not ('images' in data[id]):
            data[id]['images'] = []

        data[id]['images'].append( { 'compressed_size' : xz_size,
                                     'open_size' : qcow_size,
                                     'url' : base_url + img_file,
                                     'filename' : img_file,
                                     'type' : typ
                                     })

    return data


def read_qemu_params(data,filename):
    """reads the vm-qemu-params file, adds info to data dict"""

    for i in open(filename):
        i = i.strip()
        if len(i)==0:
            continue
        if i.startswith('#'):
            continue

        id,param_name,param_value = i.split(None,2)

        if not (id in data):
            sys.exit("ID '%s' from qemu-params file not found in ids file" % \
                     (id))

        if not ('qemu_params' in data[id]):
            data[id]['qemu_params'] = []
        data[id]['qemu_params'].append( { 'name' : param_name, 'value' : param_value } )

    return data


def generate_downloads_html(data,filename):
    # Render the HTML with Jinaj2
    tmpl_str = open(templ_file).read()
    j = Template(tmpl_str)
    html_str = j.render(vms=data)

    # Write to output file
    f = open(filename,'w')
    f.write(html_str)
    f.close()

def generate_vm_images_js(data,filename):
    # Render the HTML with Jinaj2
    tmpl_str = open(vm_images_templ_file).read()
    j = Template(tmpl_str)
    html_str = j.render(vms=data)

    # Write to output file
    f = open(filename,'w')
    f.write(html_str)
    f.close()



if __name__ == "__main__":
    vms = read_ids(ids_file)
    vms = read_sizes(vms,sizes_file)
    vms = read_qemu_params(vms,qemu_params_file)
    #pprint(vms)
    generate_downloads_html(vms, downloads_html_file)
    generate_vm_images_js(vms, vm_images_js_file)
