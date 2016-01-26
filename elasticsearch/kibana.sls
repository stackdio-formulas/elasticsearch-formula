
{% set kibana_version = pillar.elasticsearch.kibana.version %}

kibana:
  user:
    - present
    - home: /var/lib/kibana
    - shell: /sbin/nologin
    - system: true
    - groups:
      - kibana
    - require:
      - group: kibana
  group:
    - present
    - system: true

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
    - require:
      - user: kibana
  file:
    - rename
    - source: /usr/share/kibana-{{ kibana_version }}-linux-x64
    - require:
      - archive: /usr/share/kibana

/usr/share/kibana/config/kibana.yml:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/kibana.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: /usr/share/kibana

/etc/init.d/kibana:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/init-rhel
    - template: jinja
    - user: root
    - group: root
    - mode: 755

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

/usr/share/kibana/optimize/.babelcache.json:
  file:
    - symlink
    - target: /var/run/kibana/.babelcache.json
    - force: true
    - require:
      - file: /var/run/kibana
      - file: /usr/share/kibana

/var/run/kibana/.babelcache.json:
  file:
    - absent
    - require:
      - file: /usr/share/kibana/optimize/.babelcache.json

{% if salt['pillar.get']('elasticsearch:marvel:install', True) %}

{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}
install_marvel:
  cmd:
  - run
  - user: root
  - name: '/usr/share/kibana/bin/kibana plugin --install elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - file: /usr/share/kibana
  - require_in:
    - service: kibana-svc
  - unless: 'test -d /usr/share/kibana/installedPlugins/marvel'
{% endif %}

kibana-svc:
  service:
    - running
    - name: kibana
    - watch:
      - file: /usr/share/kibana
      - file: /usr/share/kibana/config/kibana.yml
      - file: /etc/init.d/kibana
      - file: /var/log/kibana
      - file: /var/run/kibana
      - file: /usr/share/kibana/optimize/.babelcache.json
      - file: /var/run/kibana/.babelcache.json
