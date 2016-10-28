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

{% if pillar.elasticsearch.encrypted %}
/etc/elasticsearch/elasticsearch-ca.crt:
  file:
    - managed
    - user: root
    - group: root
    - mode: 444
    - contents_pillar: elasticsearch:encryption:ca_cert

export-p12:
  cmd:
    - run
    - user: root
    - name: '/usr/java/latest/bin/keytool -importkeystore -srckeystore /etc/elasticsearch/elasticsearch.keystore -srcstorepass elasticsearch -srcalias {{ grains.id }} -destkeystore /etc/elasticsearch/elasticsearch.p12 -deststoretype PKCS12 -deststorepass elasticsearch'

export-pem:
  cmd:
    - run
    - user: root
    - name: 'printf "elasticsearch\n" | openssl pkcs12 -in /etc/elasticsearch/elasticsearch.p12 -nodes -nocerts -out /etc/elasticsearch/elasticsearch.pem'
    - require:
      - cmd: export-p12

chown-pem:
  cmd:
    - run
    - user: root
    - name: chown kibana:kibana /etc/elasticsearch/elasticsearch.pem && chmod 400 /etc/elasticsearch/elasticsearch.pem
    - require:
      - cmd: export-pem
      - file: /etc/elasticsearch/elasticsearch-ca.crt
    - require_in:
      - service: kibana-svc
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
    - require:
      - pkg: kibana
      - file: /opt/kibana/optimize/.babelcache.json
    - watch:
      - file: /opt/kibana/config/kibana.yml
