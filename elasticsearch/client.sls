{%- set master = 'elasticsearch.master' in grains.roles -%}
{%- set data = 'elasticsearch.data' in grains.roles -%}

include:
  - elasticsearch.install

{% if master or data %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "Please don't put a client on the same host as a master or data node"
{% endif %}


elasticsearch-svc:
  service:
    - running
    - name: elasticsearch
    - enable: true
    - require:
      - pkg: elasticsearch
