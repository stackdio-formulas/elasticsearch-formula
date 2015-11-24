include:
  - elasticsearch.install
{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}
  - elasticsearch.marvel
{% endif %}
{% if salt['pillar.get']('elasticsearch:encrypted', False) %}
  - elasticsearch.shield
{% endif %}

{%- set master = 'elasticsearch.master' in grains.roles -%}
{%- set data = 'elasticsearch.data' in grains.roles -%}

{%- if (master and client) or (data and client) -%}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "Please don't put a client on the same host as a master or data node"
{%- endif -%}

start_elasticsearch:
  service:
    - running
    - name: elasticsearch
    - enable: True
    - require:
      - pkg: elasticsearch
    - watch:
      - file: /etc/elasticsearch/elasticsearch.yml
      - file: elasticsearch_default_config
