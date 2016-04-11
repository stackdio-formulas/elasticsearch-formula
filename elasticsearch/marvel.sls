{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

{% if pillar.elasticsearch.version.split('.')[0] | int >= 2 %}
install_license:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install license'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep license'

{% if not pillar.elasticsearch.marvel.is_external %}
install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install marvel-agent'
  - require:
    - pkg: elasticsearch
    - cmd: install_license
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep marvel-agent'
{% endif %}

{% else %}

install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin -l | grep marvel'
{% endif %}
