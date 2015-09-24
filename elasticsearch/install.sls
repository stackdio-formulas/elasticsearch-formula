{% if grains['os_family'] == 'RedHat' %}
# Centos

import_repo_key:
  cmd:
  - run
  - name: 'rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch'
  - unless: 'rpm -qa | grep elasticsearch'

/etc/yum.repos.d/elasticsearch.repo:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/yum.repos.d/elasticsearch.repo
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
    - require_in:
      - pkg: elasticsearch

{% elif grains['os_family'] == 'Debian' %}
# Ubuntu

import_repo_key:
  cmd:
  - run
  - user: root
  - name: 'curl https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -'
  - unless: 'apt-key list | grep Elasticsearch'

/etc/apt/sources.list.d/elasticsearch.list:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/apt/sources.list.d/elasticsearch.list
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
    - require_in:
      - pkg: elasticsearch
{% endif %}


elasticsearch:
  pkg:
    - installed


{% set dirs = ['', '/data', '/work', '/logs'] %}

{% for dir in dirs %}
/mnt/elasticsearch{{ dir }}:
  file:
    - directory
    - user: elasticsearch
    - group: elasticsearch
    - mode: 755
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: start_elasticsearch

{% endfor %}
