{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

install_marvel:
  cmd:
  - run
  - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: elasticsearch


restart_elasticsearch:
  service.restart:
    - name: elasticsearch
    - require:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml
