
{% set kibana_version = pillar.elasticsearch.kibana.version %}

/usr/share/kibana:
  archive:
    - extracted
    - name: /usr/share
    - if_missing: /usr/share/kibana
    - user: root
    - group: root
    - source: https://download.elastic.co/kibana/kibana/kibana-{{ kibana_version }}-linux-x64.tar.gz
    - source_hash: https://download.elastic.co/kibana/kibana/kibana-{{ kibana_version }}-linux-x64.tar.gz.sha1.txt
    - archive_format: tar

/usr/share/kibana/config/kibana.yml:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/kibana.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - require:
      - archive: /usr/share/kibana
