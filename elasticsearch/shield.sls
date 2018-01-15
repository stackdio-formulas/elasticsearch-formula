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

/etc/elasticsearch/server.crt:
  file:
    - managed
    - user: root
    - group: root
    - mode: 664
    - contents_pillar: elasticsearch:encryption:certificate

/etc/elasticsearch/server.key:
  file:
    - managed
    - user: root
    - group: root
    - mode: 664
    - contents_pillar: elasticsearch:encryption:private_key

convert-to-jks:
  cmd:
    - run
    - user: root
    - name: echo 'elasticsearch' | openssl pkcs12 -export -name {{ grains.id }} -in /etc/elasticsearch/server.crt -inkey /etc/elasticsearch/server.key -out /etc/elasticsearch/elasticsearch.pkcs12 -password stdin
    - creates:  /etc/elasticsearch/elasticsearch.pkcs12
    - require:
      - file: /etc/elasticsearch/server.crt
      - file: /etc/elasticsearch/server.key

create-keystore:
  cmd:
    - run
    - user: root
    - name: '$JAVA_HOME/bin/keytool -importkeystore -srckeystore /etc/elasticsearch/elasticsearch.pkcs12 -destkeystore /etc/elasticsearch/elasticsearch.keystore -srcstoretype pkcs12 -srcalias {{ grains.id }} -destalias {{ grains.id }} -srcstorepass elasticsearch -deststorepass elasticsearch -destkeypass elasticsearch -noprompt'
    - require:
      - cmd: convert-to-jks

chown-keystore:
  cmd:
    - run
    - user: root
    - name: 'chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.keystore && chmod 440 /etc/elasticsearch/elasticsearch.keystore'
    - require:
      - cmd: create-keystore
    - require_in:
      - service: start_elasticsearch
