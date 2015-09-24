include:
  - elasticsearch.install

start_elasticsearch:
  service:
    - running
    - name: elasticsearch
    - enable: True
    - require:
      - pkg: elasticsearch
    - watch:
      - file: /etc/elasticsearch/elasticsearch.yml
