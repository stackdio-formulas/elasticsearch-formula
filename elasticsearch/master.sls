include:
  - elasticsearch.install

elasticsearch-svc:
  service:
    - running
    - name: elasticsearch
    - enable: true
    - require:
      - pkg: elasticsearch
