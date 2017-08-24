{%- set master = 'elasticsearch.master' in grains.roles -%}
{%- set data = 'elasticsearch.data' in grains.roles -%}
{%- set client = 'elasticsearch.client' in grains.roles -%}

include:
  - elasticsearch.install

{% if master or data or client %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "Please don't have a master, data, or client node on a config only node"
{% endif %}

elasticsearch-svc:
  service:
    - dead
    - name: elasticsearch
    - enable: false
    - require:
      - pkg: elasticsearch
