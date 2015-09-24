include:
  - elasticsearch.install
  - elasticsearch.start
{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}
  - elasticsearch.marvel
{% endif %}
{% if salt['pillar.get']('elasticsearch:encrypted', False) %}
  - elasticsearch.shield
{% endif %}

elasticsearch_default_config:
  file:
    - managed
    - source: salt://elasticsearch/etc/default_config
    {% if grains['os_family'] == 'Debian' %}
    - name: /etc/default/elasticsearch
    {% elif grains['os_family'] == 'RedHat' %}
    - name: /etc/sysconfig/elasticsearch
    {% endif %}
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: start_elasticsearch

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
