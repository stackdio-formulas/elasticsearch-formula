
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version < 5 %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "XPack doesn't exist on ES < 5"
{% endif %}

install-x-pack:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc
  - unless: '/usr/share/elasticsearch/bin/elasticsearch-plugin list | grep x-pack'

create_shield_user:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/shield/esusers useradd synthesys -p 123456 -r admin'
    - unless: '/usr/share/elasticsearch/bin/shield/esusers list | grep synthesys'
    - require:
      - cmd: install_shield
    - require_in:
      - service: elasticsearch-svc

create_kibana_user:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/shield/esusers useradd kibana-server -p 123456 -r kibana4_server'
    - unless: '/usr/share/elasticsearch/bin/shield/esusers list | grep kibana-server'
    - require:
      - cmd: install_shield
    - require_in:
      - service: elasticsearch-svc

# Must happen AFTER creating the user.. b/c the create user command adds the user to the config
# in /usr/share/elasticsearch ...
copy_shield_config:
  cmd:
    - run
    - user: root
    - name: 'cp -r {{ shield_config_dir }} /etc/elasticsearch'
    - require:
      - cmd: create_shield_user
    - require_in:
      - service: elasticsearch-svc

/etc/elasticsearch/elasticsearch.key:
  file:
    - managed
    - user: root
    - group: root
    - mode: {% if 'elasticsearch.config_only' in grains.roles %}444{% else %}400{% endif %}
    - contents_pillar: ssl:private_key
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/elasticsearch.crt:
  file:
    - managed
    - user: elasticsearch
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:chained_certificate
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/ca.crt:
  file:
    - managed
    - user: elasticsearch
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:ca_certificate
    - watch_in:
      - service: elasticsearch-svc

role-mapping:
  file:
    - managed
    - name: /etc/elasticsearch/shield/role_mapping.yml
    - source: salt://elasticsearch/etc/elasticsearch/shield/role_mapping.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: copy_shield_config
    - watch_in:
      - service: elasticsearch-svc
