{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

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
