/*
@licstart  The following is the entire license notice for the JavaScript code in this page.

This file is part of PreTest (http://pretest.nongnu.org).

Copyright (C) 2015-2017 Assaf Gordon (assafgordon@gmail.com)

The JavaScript code in this page is free software: you can
redistribute it and/or modify it under the terms of the GNU
General Public License (GNU GPL) as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.  The code is distributed WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU GPL for more details.

As additional permission under GNU GPL version 3 section 7, you
may distribute non-source (e.g., minimized or compacted) forms of
that code without the copy of the GNU GPL normally required by
section 4, provided you include this license notice and a URL
through which recipients can access the Corresponding Source.

(see https://www.gnu.org/philosophy/javascript-trap.html).

@licend  The above is the entire license notice for the JavaScript code in this page.
*/

var clean_install_vms = [
{# Ugly hack for globals in jinja2 #}
{% set glob={} %}

{% for id in vms | sort -%}
{% set data = vms[id] -%}
  {% for i in data.images -%}
  {% if i.type == "clean-install" -%}

    {# Ugly hack to add commas between items (but not before the first one) #}
    {% if glob %}
    ,
    {% endif %}
    {# Update the global variable, indicating there was at least one item #}
    {% set _ = glob.update({'stuff':True}) %}


    { "id": "{{id}}",
      "filename": "{{ i.filename }}",
      "comp_size": "{{ i.compressed_size }}",
      "raw_size": "{{ i.open_size }}"
      {%- if data.qemu_params -%}
      ,
      {#- Extra QEMU parameters, if any. These are used in the Javascript
          LibVirt/Qemu command-line builder HTML pages -#}
      {% for q in data.qemu_params -%}
      "{{ q.name }}": "{{ q.value }}"
      {%- if not loop.last %},{% endif %}
      {% endfor -%}

      {% endif -%}
    }
  {%- endif %}
  {% endfor -%}
{% endfor %}

];

var build_ready_vms = [

{# Ugly hack for globals in jinja2 #}
{% set glob={} %}

{% for id in vms | sort -%}
{% set data = vms[id] -%}
  {% for i in data.images -%}
  {% if i.type == "build-ready" -%}

    {# Ugly hack to add commas between items (but not before the first one) #}
    {% if glob %}
    ,
    {% endif %}
    {# Update the global variable, indicating there was at least one item #}
    {% set _ = glob.update({'stuff':True}) %}


    { "id": "{{id}}",
      "filename": "{{ i.filename }}",
      "comp_size": "{{ i.compressed_size }}",
      "raw_size": "{{ i.open_size }}"
      {%- if data.qemu_params -%}
      ,
      {#- Extra QEMU parameters, if any. These are used in the Javascript
          LibVirt/Qemu command-line builder HTML pages -#}
      {% for q in data.qemu_params -%}
      "{{ q.name }}": "{{ q.value }}"
      {%- if not loop.last %},{% endif %}
      {% endfor -%}

      {% endif -%}
    }
  {%- endif %}
  {% endfor -%}
{% endfor %}


];

var base_download_url = "http://files.housegordon.org/pretest/v0.1/";
