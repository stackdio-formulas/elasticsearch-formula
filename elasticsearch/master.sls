include:
  - elasticsearch.install
{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}
  - elasticsearch.marvel
{% endif %}
{% if salt['pillar.get']('elasticsearch:encrypted', False) %}
  - elasticsearch.shield
{% endif %}

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
