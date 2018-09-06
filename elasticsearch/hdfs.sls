
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version >= 5 %}

{% if pillar.elasticsearch.hdfs.kerberos.enabled %}
include:
  - krb5

# For security to work, we rely on a KDC to be available in this stack.
# Your blueprint should include the KDC role on one machine, and it's
# generally recommended that KDC be installed on a machine by itself
{% set kdc_host = salt['mine.get']('G@stack_id:' ~ grains.stack_id ~ ' and G@roles:krb5.kdc', 'grains.items', 'compound').keys()[0] %}

krb-pkgs:
  pkg.installed:
    - pkgs:
      - krb5-workstation
      - krb5-libs

# load admin keytab from the master fileserver
load_admin_keytab:
  module.run:
    - name: cp.get_file
    - path: salt://{{ kdc_host }}/root/admin.keytab
    - dest: /root/admin.keytab
    - user: root
    - group: root
    - mode: 600
    - require:
      - file: krb5_conf_file
      - pkg: krb-pkgs

generate_es_keytab:
  cmd.script:
    - source: salt://elasticsearch/generate_es_keytab.sh
    - template: jinja
    - user: root
    - group: root
    - cwd: /etc/elasticsearch/repository-hdfs
    - unless: test -f /etc/elasticsearch/repository-hdfs/krb5.keytab
    - require:
      - module: load_admin_keytab
      - pkg: krb-pkgs
      - pkg: elasticsearch
      - file: /etc/elasticsearch/repository-hdfs
    - require_in:
      - service: elasticsearch-svc

{% endif %}

install-repository-hdfs:
  cmd.run:
    - user: root
    - name: '/usr/share/elasticsearch/bin/elasticsearch-plugin install -b repository-hdfs'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep repository-hdfs'
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: elasticsearch-svc

/etc/elasticsearch/repository-hdfs:
  file.directory:
    - user: root
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: elasticsearch
      - cmd: install-repository-hdfs
    - require_in:
      - service: elasticsearch-svc

{% endif %}
