
{% set kibana_version = pillar.elasticsearch.kibana.version %}

# Install
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
    - mode: 644
    - require:
      - archive: /usr/share/kibana

/etc/init.d/kibana:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/init-rhel
    - template: jinja
    - user: root
    - group: root
    - mode: 755

kibana:
  user:
    - present
    - home: /usr/share/kibana
    - system: true
    - groups:
      - kibana
    - require:
      - group: kibana
      - file: /usr/share/kibana
  group:
    - present

/var/log/kibana:
  file:
    - directory
    - user: kibana
    - group: kibana
    - recurse:
      - user
      - group
    - require:
      - user: kibana

/var/run/kibana:
  file:
    - directory
    - user: kibana
    - group: kibana
    - recurse:
      - user
      - group
    - require:
      - user: kibana

kibana-svc:
  service:
    - running
    - name: kibana
    - watch:
      - archive: /usr/share/kibana
      - file: /usr/share/kibana/config/kibana.yml
      - file: /etc/init.d/kibana
      - file: /var/log/kibana
      - file: /var/run/kibana
