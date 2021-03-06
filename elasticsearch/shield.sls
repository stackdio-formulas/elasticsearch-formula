
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version >= 5 %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "Shield doesn't exist on ES 5"
{% endif %}

{% set shield_config_dir = '/usr/share/elasticsearch/plugins/shield/config' %}

install_license_shield:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install license'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: elasticsearch-svc
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep license'

install_shield:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install shield'
  - require:
    - pkg: elasticsearch
    - cmd: install_license_shield
  - require_in:
    - service: elasticsearch-svc
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep shield'

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

/etc/elasticsearch/elasticsearch.crt:
  file:
    - managed
    - user: elasticsearch
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:certificate
    - require:
      - file: /etc/elasticsearch/elasticsearch.key

/etc/elasticsearch/ca.crt:
  file:
    - managed
    - user: elasticsearch
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:ca_certificate
    - require:
      - file: /etc/elasticsearch/elasticsearch.key

/etc/elasticsearch/chained.crt:
  file:
    - managed
    - user: elasticsearch
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:chained_certificate
    - require:
      - file: /etc/elasticsearch/elasticsearch.key

create-pkcs12:
  cmd:
    - run
    - user: root
    - name: openssl pkcs12 -export -in /etc/elasticsearch/elasticsearch.crt -certfile /etc/elasticsearch/chained.crt -inkey /etc/elasticsearch/elasticsearch.key -out /etc/elasticsearch/elasticsearch.pkcs12 -name {{ grains.id }} -password pass:elasticsearch
    - require:
      - file: /etc/elasticsearch/chained.crt
      - file: /etc/elasticsearch/elasticsearch.crt
      - file: /etc/elasticsearch/elasticsearch.key

create-truststore:
  cmd:
    - run
    - user: root
    - name: /usr/java/latest/bin/keytool -importcert -keystore /etc/elasticsearch/elasticsearch.truststore -storepass elasticsearch -file /etc/elasticsearch/ca.crt -alias root-ca -noprompt
    - unless: /usr/java/latest/bin/keytool -list -keystore /etc/elasticsearch/elasticsearch.truststore -storepass elasticsearch | grep root-ca
    - require:
      - file: /etc/elasticsearch/ca.crt
    - require_in:
      - service: elasticsearch-svc

create-keystore:
  cmd:
    - run
    - user: root
    - name: /usr/java/latest/bin/keytool -importkeystore -srckeystore /etc/elasticsearch/elasticsearch.pkcs12 -srcstorepass elasticsearch -srcstoretype pkcs12 -destkeystore /etc/elasticsearch/elasticsearch.keystore -deststorepass elasticsearch
    - unless: /usr/java/latest/bin/keytool -list -keystore /etc/elasticsearch/elasticsearch.keystore -storepass elasticsearch | grep {{ grains.id }}
    - require:
      - cmd: create-pkcs12
    - require_in:
      - service: elasticsearch-svc

chmod-keystore:
  cmd:
    - run
    - user: root
    - name: chmod {% if 'elasticsearch.config_only' in grains.roles %}444{% else %}400{% endif %} /etc/elasticsearch/elasticsearch.keystore
    - require:
      - cmd: create-keystore
    - require_in:
      - service: elasticsearch-svc

chown-keystore:
  cmd:
    - run
    - user: root
    - name: chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.keystore
    - require:
      - cmd: create-keystore
      - cmd: chmod-keystore
    - require_in:
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
