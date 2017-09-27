
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

{% if es_major_version < 5 %}
invalid_configuration:
  test:
    - configurable_test_state
    - changes: True
    - result: False
    - comment: "X-Pack doesn't exist on ES < 5"
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

/etc/elasticsearch/x-pack:
  file:
    - directory
    - user: root
    - group: elasticsearch
    - dir_mode: 755
    - file_mode: 664
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: elasticsearch
      - cmd: install-x-pack
    - require_in:
      - service: elasticsearch-svc

{% if pillar.elasticsearch.xpack.security.enabled %}
/etc/elasticsearch/elasticsearch.key:
  file:
    - managed
    - user: root
    - group: elasticsearch
    - mode: {% if 'elasticsearch.config_only' in grains.roles %}444{% else %}440{% endif %}
    - contents_pillar: ssl:private_key
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/elasticsearch.crt:
  file:
    - managed
    - user: root
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:certificate
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/chained.crt:
  file:
    - managed
    - user: root
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:chained_certificate
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/ca.crt:
  file:
    - managed
    - user: root
    - group: elasticsearch
    - mode: 444
    - contents_pillar: ssl:ca_certificate
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

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
    - name: /etc/elasticsearch/x-pack/role_mapping.yml
    - source: salt://elasticsearch/etc/elasticsearch/x-pack/role_mapping.yml
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 664
    - require:
      - pkg: elasticsearch
      - cmd: install-x-pack
      - file: /etc/elasticsearch/x-pack
    - watch_in:
      - service: elasticsearch-svc

{% endif %}

{% if es_major_version >= 6 and 'elasticsearch.config_only' not in grains.roles %}

# Set a password in the ES keystore (only if we're not a config only node)
set-password:
  cmd:
    - run
    - user: root
    - name: 'echo "123456" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-keystore list | grep bootstrap.password'
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - file: keystore-permissions
      - service: elasticsearch-svc

{% endif %}
