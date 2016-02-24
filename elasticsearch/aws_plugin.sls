install_aws:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install cloud-aws'
  - require:
    - pkg: elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep cloud-aws'

restart_elasticsearch:
  service:
    - running
    - name: elasticsearch
    - enable: True
    - reload: True
    - require:
      - pkg: elasticsearch
