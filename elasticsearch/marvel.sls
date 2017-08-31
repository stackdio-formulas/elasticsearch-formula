
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version >= 5 %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "Marvel doesn't exist on ES 5"
{% endif %}

{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

install_license:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install license'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep license'

{% if not pillar.elasticsearch.marvel.is_external %}
install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install marvel-agent'
  - require:
    - pkg: elasticsearch
    - cmd: install_license
  - require_in:
    - service: elasticsearch-svc
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep marvel-agent'
{% endif %}
