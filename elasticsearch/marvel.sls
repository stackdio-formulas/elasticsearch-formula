install_marvel:
  cmd:
  - run
  - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/{{ elasticsearch.marvel.version }}'
  - require:
    - pkg: elasticsearch


restart_elasticsearch:
  service.restart:
    - name: elasticsearch
    - require:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml
