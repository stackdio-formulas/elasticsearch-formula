include:
  - elasticsearch.install
  - elasticsearch.start

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

/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch-data.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
