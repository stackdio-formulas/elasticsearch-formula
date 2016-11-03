{%- if pillar.elasticsearch.version.split('.')[0] | int >= 2  -%}
  {%- set shield_config_dir = '/usr/share/elasticsearch/plugins/shield/config' -%}
{%- else -%}
  {%- set shield_config_dir = '/usr/share/elasticsearch/config/shield' -%}
{%- endif -%}

{% if pillar.elasticsearch.version.split('.')[0] | int >= 2  %}

install_license_shield:
  cmd:
  - run
  - user: root
  - name: '/usr/share/elasticsearch/bin/plugin install license'
  - require:
    - pkg: elasticsearch
  - require_in:
    - service: start_elasticsearch
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
    - service: start_elasticsearch
  - unless: '/usr/share/elasticsearch/bin/plugin list | grep shield'

{% else %}

install_license_sheild:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/license/latest'
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: start_elasticsearch
    - unless: '/usr/share/elasticsearch/bin/plugin -l | grep license'

install_shield:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/plugin -i elasticsearch/shield/latest'
    - require:
      - pkg: elasticsearch
      - cmd: install_license_shield
    - require_in:
      - service: start_elasticsearch
    - unless: '/usr/share/elasticsearch/bin/plugin -l | grep shield'
{% endif %}

create_shield_user:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/shield/esusers useradd synthesys -p 123456 -r admin'
    - unless: '/usr/share/elasticsearch/bin/shield/esusers list | grep synthesys'
    - require:
      - cmd: install_shield
    - require_in:
      - service: start_elasticsearch

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
      - service: start_elasticsearch

/etc/elasticsearch/ca:
  file:
    - recurse
    - source: salt://elasticsearch/ca
    - template: jinja
    - user: root
    - group: root
    - file_mode: 644
    - require:
      - pkg: elasticsearch

/etc/elasticsearch/ca/private/cakey.pem:
  file:
    - managed
    - user: root
    - group: root
    - mode: 400
    - makedirs: true
    - contents_pillar: elasticsearch:encryption:ca_key
    - require:
      - file: /etc/elasticsearch/ca

/etc/elasticsearch/ca/certs/cacert.pem:
  file:
    - managed
    - user: root
    - group: root
    - mode: 400
    - makedirs: true
    - contents_pillar: elasticsearch:encryption:ca_cert
    - require:
      - file: /etc/elasticsearch/ca

# Delete before re-creating to ensure idempotency
delete-truststore:
  cmd:
    - run
    - user: root
    - name: rm -f /etc/elasticsearch/elasticsearch.truststore

create-truststore:
  cmd:
    - run
    - user: root
    - name: /usr/java/latest/bin/keytool -importcert -keystore /etc/elasticsearch/elasticsearch.truststore -storepass elasticsearch -file /etc/elasticsearch/ca/certs/cacert.pem -alias elasticsearch-ca -noprompt
    - require:
      - cmd: delete-truststore
      - file: /etc/elasticsearch/ca
      - file: /etc/elasticsearch/ca/private/cakey.pem
      - file: /etc/elasticsearch/ca/certs/cacert.pem
    - require_in:
      - service: start_elasticsearch

create-keystore:
  file:
    - copy
    - name: /etc/elasticsearch/elasticsearch.keystore
    - source: /etc/elasticsearch/elasticsearch.truststore
    - user: root
    - group: root
    - force: true
    - mode: {% if 'elasticsearch.config_only' in grains.roles %}644{% else %}600{% endif %}
    - require:
      - cmd: create-truststore

create-key:
  cmd:
    - run
    - user: root
    - name: 'printf "Elasticsearch {{ grains.id }}\n\nElasticsearch\nUS\nUS\nUS\nyes\n" | /usr/java/latest/bin/keytool -genkey -alias {{ grains.id }} -keystore /etc/elasticsearch/elasticsearch.keystore -storepass elasticsearch -keyalg RSA -keysize 2048 -validity 8000 -ext san=dns:{{ grains.fqdn }}'
    - require:
      - file: create-keystore

create-csr:
  cmd:
    - run
    - user: root
    - name: '/usr/java/latest/bin/keytool -certreq -alias {{ grains.id }} -keystore /etc/elasticsearch/elasticsearch.keystore -storepass elasticsearch -file /etc/elasticsearch/elasticsearch.csr -keyalg rsa -ext san=dns:{{ grains.fqdn }}'
    - require:
      - cmd: create-key

sign-csr:
  cmd:
    - run
    - user: root
    - name: 'printf "{{ pillar.elasticsearch.encryption.ca_key_pass }}\ny\ny\n" | openssl ca -in /etc/elasticsearch/elasticsearch.csr -notext -out /etc/elasticsearch/elasticsearch.crt -config /etc/elasticsearch/ca/conf/caconfig.cnf -extensions v3_req'
    - require:
      - cmd: create-csr

import-signed-crt:
  cmd:
    - run
    - user: root
    - name: '/usr/java/latest/bin/keytool -importcert -keystore /etc/elasticsearch/elasticsearch.keystore -storepass elasticsearch -file /etc/elasticsearch/elasticsearch.crt -alias {{ grains.id }}'
    - require:
      - cmd: sign-csr
    - require_in:
      - service: start_elasticsearch

chown-keystore:
  cmd:
    - run
    - user: root
    - name: chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.keystore
    - require:
      - cmd: import-signed-crt
    - require_in:
      - service: start_elasticsearch

# Don't leave the CA lying around.  Must be a cmd instead of file.absent, as it causes a name collision otherwise.
remove-ca:
  cmd:
    - run
    - name: rm -rf /etc/elasticsearch/ca
    - require:
      - cmd: create-truststore
      - cmd: import-signed-crt
