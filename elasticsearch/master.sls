include:
  - elasticsearch.install
  - elasticsearch.start
{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}
  - elasticsearch.marvel
{% endif %}
{% if salt['pillar.get']('elasticsearch:encrypted', False) %}
  - elasticsearch.shield
{% endif %}


/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
