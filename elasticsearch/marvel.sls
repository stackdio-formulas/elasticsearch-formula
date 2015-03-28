{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

install_marvel:
  cmd:
  - run
  - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: elasticsearch
  - watch_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin -l | grep marvel'
