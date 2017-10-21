
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
/etc/elasticsearch/x-pack/elasticsearch.key:
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

/etc/elasticsearch/x-pack/elasticsearch.crt:
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

/etc/elasticsearch/x-pack/chained.crt:
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

/etc/elasticsearch/x-pack/ca.crt:
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
    - name: openssl pkcs12 -export -in /etc/elasticsearch/x-pack/elasticsearch.crt -certfile /etc/elasticsearch/x-pack/chained.crt -inkey /etc/elasticsearch/x-pack/elasticsearch.key -out /etc/elasticsearch/x-pack/elasticsearch.pkcs12 -name {{ grains.id }} -password pass:elasticsearch
    - require:
      - file: /etc/elasticsearch/x-pack/chained.crt
      - file: /etc/elasticsearch/x-pack/elasticsearch.crt
      - file: /etc/elasticsearch/x-pack/elasticsearch.key

create-truststore:
  cmd:
    - run
    - user: root
    - name: /usr/java/latest/bin/keytool -importcert -keystore /etc/elasticsearch/x-pack/elasticsearch.truststore -storepass elasticsearch -file /etc/elasticsearch/x-pack/ca.crt -alias root-ca -noprompt
    - unless: /usr/java/latest/bin/keytool -list -keystore /etc/elasticsearch/x-pack/elasticsearch.truststore -storepass elasticsearch | grep root-ca
    - require:
      - file: /etc/elasticsearch/x-pack/ca.crt
    - require_in:
      - service: elasticsearch-svc

create-keystore:
  cmd:
    - run
    - user: root
    - name: /usr/java/latest/bin/keytool -importkeystore -srckeystore /etc/elasticsearch/x-pack/elasticsearch.pkcs12 -srcstorepass elasticsearch -srcstoretype pkcs12 -destkeystore /etc/elasticsearch/x-pack/elasticsearch.keystore -deststorepass elasticsearch
    - unless: /usr/java/latest/bin/keytool -list -keystore /etc/elasticsearch/x-pack/elasticsearch.keystore -storepass elasticsearch | grep {{ grains.id }}
    - require:
      - cmd: create-pkcs12
    - require_in:
      - service: elasticsearch-svc

chmod-keystore:
  cmd:
    - run
    - user: root
    - name: chmod {% if 'elasticsearch.config_only' in grains.roles %}444{% else %}400{% endif %} /etc/elasticsearch/x-pack/elasticsearch.keystore
    - require:
      - cmd: create-keystore
    - require_in:
      - service: elasticsearch-svc

chown-keystore:
  cmd:
    - run
    - user: root
    - name: chown elasticsearch:elasticsearch /etc/elasticsearch/x-pack/elasticsearch.keystore
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

{% if es_major_version >= 5 %}
# Set the keystore passwords
set-keystore-password:
  cmd:
    - run
    - user: root
    - name: 'echo "elasticsearch" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin xpack.ssl.keystore.secure_password'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-keystore list | grep xpack.ssl.keystore.secure_password'
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - file: keystore-permissions
      - service: elasticsearch-svc

set-keystore-key-password:
  cmd:
    - run
    - user: root
    - name: 'echo "elasticsearch" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin xpack.ssl.keystore.secure_key_password'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-keystore list | grep xpack.ssl.keystore.secure_key_password'
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - file: keystore-permissions
      - service: elasticsearch-svc

set-truststore-password:
  cmd:
    - run
    - user: root
    - name: 'echo "elasticsearch" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin xpack.ssl.truststore.secure_password'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-keystore list | grep xpack.ssl.truststore.secure_password'
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - file: keystore-permissions
      - service: elasticsearch-svc
{% endif %}

{% endif %}

{% if es_major_version >= 6 and 'elasticsearch.config_only' not in grains.roles %}

# Set a password in the ES keystore (only if we're not a config only node)
set-bootstrap-password:
  cmd:
    - run
    - user: root
    - name: 'echo "changeme" | /usr/share/elasticsearch/bin/elasticsearch-keystore add --stdin bootstrap.password'
    - unless: '/usr/share/elasticsearch/bin/elasticsearch-keystore list | grep bootstrap.password'
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - file: keystore-permissions
      - service: elasticsearch-svc

{% endif %}
