include:
  - elasticsearch.install
  - elasticsearch.start

/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch-master.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
