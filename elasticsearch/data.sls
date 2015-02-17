/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch-data.yml
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch


configure_elasticsearch:
  cmd:
  - run
  - name: 'chkconfig --add elasticsearch'
  - require:
    - pkg: elasticsearch
    - file: /etc/elasticsearch/elasticsearch.yml


start_elasticsearch:
  service.running:
    - name: elasticsearch
    - require:
      - pkg: elasticsearch
      - file: /etc/elasticsearch/elasticsearch.yml
