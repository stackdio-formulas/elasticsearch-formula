install_aws:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install -b cloud-aws'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep cloud-aws'
