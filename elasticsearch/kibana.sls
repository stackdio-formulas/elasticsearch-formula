{% set kibana_version = pillar.elasticsearch.kibana.version %}
{% set es_version = pillar.elasticsearch.version %}
{%- set shield = salt['pillar.get']('elasticsearch:encrypted', False) -%}

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

{% if pillar.elasticsearch.encrypted %}
/opt/kibana/config/kibana.key:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 400
    - contents_pillar: ssl:private_key
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

/opt/kibana/config/kibana.crt:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 444
    - contents_pillar: ssl:chained_certificate
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

/opt/kibana/config/ca.crt:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 444
    - contents_pillar: ssl:ca_certificate
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

{% endif %}

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

{% if shield %}
install_shield:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install kibana/shield/{{ es_version }}'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
    - file: /opt/kibana/optimize/.babelcache.json
  - unless: 'test -d /opt/kibana/installedPlugins/shield'
{% endif %}

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
    - file: /opt/kibana/optimize/.babelcache.json
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
    - file: /opt/kibana/optimize/.babelcache.json
  - unless: 'test -d /opt/kibana/installedPlugins/sense'
{% endif %}

/opt/kibana/optimize/.babelcache.json:
  file:
    - managed
    - user: kibana
    - group: kibana
    - require:
      - pkg: kibana

kibana-svc:
  service:
    - running
    - name: kibana
    - enable: true
    - require:
      - pkg: kibana
      - file: /opt/kibana/optimize/.babelcache.json
    - watch:
      - file: /opt/kibana/config/kibana.yml
