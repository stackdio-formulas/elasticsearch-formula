include:
  - elasticsearch.install

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
