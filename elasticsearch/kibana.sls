{% set kibana_version = pillar.elasticsearch.kibana.version %}

{% if grains['os_family'] == 'RedHat' %}
# Centos

import_repo_key:
  cmd:
  - run
  - name: 'rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch'
  - unless: 'rpm -qa | grep elasticsearch'

/etc/yum.repos.d/kibana.repo:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/yum.repos.d/kibana.repo
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
    - require_in:
      - pkg: kibana

{% elif grains['os_family'] == 'Debian' %}
# Ubuntu

import_repo_key:
  cmd:
  - run
  - user: root
  - name: 'curl https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -'
  - unless: 'apt-key list | grep Elasticsearch'

/etc/apt/sources.list.d/kibana.list:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/apt/sources.list.d/kibana.list
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
    - require_in:
      - pkg: kibana
{% endif %}


kibana:
  pkg:
    - installed

/opt/kibana/config/kibana.yml:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/kibana.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: kibana

{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}

{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}
install_marvel:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
  - unless: 'test -d /opt/kibana/installedPlugins/marvel'
{% endif %}

{% if salt['pillar.get']('elasticsearch:sense:install', True) %}
install_sense:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install elastic/sense'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
  - unless: 'test -d /opt/kibana/installedPlugins/sense'
{% endif %}

kibana-svc:
  service:
    - running
    - name: kibana
    - require:
      - pkg: kibana
    - watch:
      - file: /opt/kibana/config/kibana.yml
