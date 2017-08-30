
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version >= 5 %}

# After ES 5, was split into 2 plugins

install-discovery-ec2:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/elasticsearch-plugin install -b discovery-ec2'
  - unless: '/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep discovery-ec2'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc

install-repository-s3:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/elasticsearch-plugin install -b repository-s3'
  - unless: '/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep repository-s3'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc


/etc/elasticsearch/discovery-ec2:
  file:
    - directory
    - user: root
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: elasticsearch
      - cmd: install-discovery-ec2
    - require_in:
      - service: elasticsearch-svc


/etc/elasticsearch/repository-s3:
  file:
    - directory
    - user: root
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: elasticsearch
      - cmd: install-repository-s3
    - require_in:
      - service: elasticsearch-svc

{% else %}

install-cloud-aws:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install -b cloud-aws'
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep cloud-aws'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc

{% endif %}
