include:
  - elasticsearch.install
  - elasticsearch.start
{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}
  - elasticsearch.marvel
{% endif %}


/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch-master.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
