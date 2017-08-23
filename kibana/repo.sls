{% set major_version = pillar.elasticsearch.kibana.version.split('.')[0] | int %}


{% if major_version >= 5 %}

# Starting in kibana 5, kibana is located in the same repo with ES
include:
  - elasticsearch.repo

# Just have a placeholder here, so other things can depend on the correct state
kibana-repo:
  file:
    - absent
    - name: /etc/yum.repos.d/kibana.repo
    - require:
      - file: elasticsearch-repo

{% else %}

{% if grains['os_family'] == 'RedHat' %}
# Centos

import_repo_key:
  cmd:
  - run
  - name: 'rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch'
  - unless: 'rpm -qa | grep elasticsearch'

kibana-repo:
  file:
    - managed
    - name: /etc/yum.repos.d/kibana.repo
    - source: salt://elasticsearch/etc/yum.repos.d/kibana.repo
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key

{% elif grains['os_family'] == 'Debian' %}
# Ubuntu

import_repo_key:
  cmd:
  - run
  - user: root
  - name: 'curl https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -'
  - unless: 'apt-key list | grep Elasticsearch'

kibana-repo:
  file:
    - managed
    - name: /etc/apt/sources.list.d/kibana.list
    - source: salt://elasticsearch/etc/apt/sources.list.d/kibana.list
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
{% endif %}

{% endif %}
