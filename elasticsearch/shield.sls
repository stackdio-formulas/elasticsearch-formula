
install_license:
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
      - cmd: install_license
    - require_in:
      - service: start_elasticsearch
    - unless: '/usr/share/elasticsearch/bin/plugin -l | grep shield'

create_shield_user:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/shield/esusers useradd admin -p 123456 -r admin'
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
    - name: 'cp -r /usr/share/elasticsearch/config/shield /etc/elasticsearch'
    - require:
      - cmd: create_shield_user
    - require_in:
      - service: start_elasticsearch

/root/server.crt:
  file:
    - managed
    - user: root
    - group: root
    - mode: 664
    - contents_pillar: elasticsearch:encryption:certificate

/root/server.key:
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
    - name: echo 'elasticsearch' | openssl pkcs12 -export -name {{ grains.id }} -in /root/server.crt -inkey /root/server.key -out /etc/elasticsearch/elasticsearch.pkcs12 -password stdin
    - require:
      - file: /root/server.crt
      - file: /root/server.key

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
