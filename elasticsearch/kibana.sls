{% set kibana_version = pillar.elasticsearch.kibana.version %}
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

{% if pillar.elasticsearch.encrypted %}
/etc/elasticsearch/elasticsearch-ca.crt:
  file:
    - managed
    - user: root
    - group: root
    - mode: 444
    - contents_pillar: elasticsearch:encryption:ca_cert

/etc/elasticsearch/elasticsearch-ca.key:
  file:
    - managed
    - user: root
    - group: root
    - mode: 444
    - contents_pillar: elasticsearch:encryption:ca_key

generate-key:
  cmd:
    - run
    - user: root
    - name: 'openssl genrsa -out /etc/elasticsearch/kibana.key 2048'

generate-csr:
  cmd:
    - run
    - user: root
    - name: 'openssl req -new -key /etc/elasticsearch/kibana.key -out /etc/elasticsearch/kibana.csr -subj "/C=US/ST=US/L=US/O=Elasticsearch/OU=Kibana/CN={{ grains.fqdn }}"'
    - require:
      - cmd: generate-key

generate-cert:
  cmd:
    - run
    - user: root
    - name: 'printf "{{ pillar.elasticsearch.encryption.ca_key_pass }}\n" | openssl x509 -req -in /etc/elasticsearch/kibana.csr -CA /etc/elasticsearch/elasticsearch-ca.crt -CAkey /etc/elasticsearch/elasticsearch-ca.key -CAcreateserial -out /etc/elasticsearch/kibana.crt -days 1000 -sha256'
    - require:
      - cmd: generate-csr
      - file: /etc/elasticsearch/elasticsearch-ca.crt
      - file: /etc/elasticsearch/elasticsearch-ca.key

chown-pem:
  cmd:
    - run
    - user: root
    - name: chown kibana:kibana /etc/elasticsearch/kibana.key && chmod 400 /etc/elasticsearch/kibana.key
    - require:
      - cmd: generate-key
      - cmd: generate-cert
      - pkg: kibana
    - require_in:
      - service: kibana-svc

{% for file in ['/etc/elasticsearch/elasticsearch-ca.srl', '/etc/elasticsearch/elasticsearch-ca.key'] %}
delete-{{ file }}:
  cmd:
    - run
    - user: root
    - name: 'rm -f {{ file }}'
    - require:
      - cmd: generate-cert
{% endfor %}

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

{% if shield %}
install_shield:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install kibana/shield/latest'
  - require:
    - pkg: kibana
    {% if pillar.elasticsearch.encrypted %}
    - cmd: chown-pem
    {% endif %}
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
    {% if pillar.elasticsearch.encrypted %}
    - cmd: chown-pem
    {% endif %}
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
    {% if pillar.elasticsearch.encrypted %}
    - cmd: chown-pem
    {% endif %}
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
