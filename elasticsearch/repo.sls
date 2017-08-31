{% set major_version = pillar.elasticsearch.version.split('.')[0] | int %}

{% if major_version >= 5 %}
  {% set key_url = 'https://artifacts.elastic.co/GPG-KEY-elasticsearch' %}
  {% set deb_url = 'https://artifacts.elastic.co/packages/5.x/apt' %}
{% elif major_version == 2 %}
  {% set key_url = 'https://packages.elastic.co/GPG-KEY-elasticsearch' %}
  {% set deb_url = 'https://packages.elastic.co/elasticsearch/2.x/debian' %}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
# Centos

import_repo_key:
  cmd:
  - run
  - name: 'rpm --import {{ key_url }}'
  - unless: 'rpm -qa | grep elasticsearch'

elasticsearch-repo:
  file:
    - managed
    - name: /etc/yum.repos.d/elasticsearch.repo
    - source: salt://elasticsearch/etc/yum.repos.d/elasticsearch-{{ major_version }}.repo
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
  - name: 'curl {{ key_url }} | apt-key add -'
  - unless: 'apt-key list | grep Elasticsearch'

elasticsearch-repo:
  file:
    - managed
    - name: /etc/apt/sources.list.d/elasticsearch.list
    - contents:
      - deb {{ deb_url }} stable main
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key
{% endif %}
