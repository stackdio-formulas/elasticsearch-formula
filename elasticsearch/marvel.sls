{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}

{%- set es_version = salt['pillar.get']('elasticsearch:version', 'latest') -%} %}

# This 2.x is how ES is describing their versions -
# they have a single yum repository with all the 2.x versions in it
# (We may need to change the formula in the future to support this better)

{% if es_version == '2.x'  %}
install_license:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install license'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep license'

install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install marvel-agent'
  - require:
    - pkg: elasticsearch
    - cmd: install_license
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep marvel-agent'

{% else %}

install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin -l | grep marvel'
{% endif %}
