{% set config_only = 'elasticsearch.config_only' in grains.roles %}
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}

include:
  - elasticsearch.repo

  {% if es_major_version >= 5 %}

  {# These are only valid for ES >= 5 #}
  {% if pillar.elasticsearch.xpack.install %}
  - elasticsearch.xpack
  {% endif %}
  {# END ES >= 5 #}

  {% else %}

  {# These are only valid for ES < 5 #}
  {% if pillar.elasticsearch.marvel.install %}
  - elasticsearch.marvel
  {% endif %}
  {% if pillar.elasticsearch.encrypted %}
  - elasticsearch.shield
  {% endif %}
  {# END ES < 5 #}

  {% endif %}

  {% if pillar.elasticsearch.aws.install %}
  - elasticsearch.aws
  {% endif %}

  {% if pillar.elasticsearch.icu.install %}
  - elasticsearch.icu
  {% endif %}


elasticsearch:
  pkg:
    - installed
    - version: {{ es_version | replace('-', '_') }}-1
    - require:
      - file: elasticsearch-repo

/etc/elasticsearch:
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
    - require_in:
      - service: elasticsearch-svc

/etc/elasticsearch/elasticsearch.yml:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/elasticsearch-{{ es_major_version }}.yml
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 664
    - require:
      - file: /etc/elasticsearch
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

/etc/elasticsearch/jvm.options:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/elasticsearch/jvm.options
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 664
    - require:
      - file: /etc/elasticsearch
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc

elasticsearch_env:
  file:
    - managed
    - source: salt://elasticsearch/etc/env-{{ es_major_version }}
    {% if grains['os_family'] == 'Debian' %}
    - name: /etc/default/elasticsearch
    {% elif grains['os_family'] == 'RedHat' %}
    - name: /etc/sysconfig/elasticsearch
    {% endif %}
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: elasticsearch
    - watch_in:
      - service: elasticsearch-svc


{% if not config_only %}

{% set dirs = ['', '/data', '/logs'] %}

{% for dir in dirs %}
/mnt/elasticsearch{{ dir }}:
  file:
    - directory
    - user: elasticsearch
    - group: elasticsearch
    - mode: 755
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: elasticsearch-svc

{% endfor %}

{# END non config-only nodes #}
{% endif %}

{% if es_major_version >= 5 %}

# Create the ES keystore
create-es-keystore:
  cmd:
    - run
    - user: root
    - name: '/usr/share/elasticsearch/bin/elasticsearch-keystore create'
    - unless: 'test -f /etc/elasticsearch/elasticsearch.keystore'
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: elasticsearch-svc

# Fix permissions on the keystore
keystore-permissions:
  file:
    - managed
    - name: /etc/elasticsearch/elasticsearch.keystore
    - user: root
    - group: elasticsearch
    - mode: {% if config_only %}664{% else %}660{% endif %}
    - require:
      - pkg: elasticsearch
      - cmd: create-es-keystore
    - require_in:
      - service: elasticsearch-svc

{% endif %}

# Fix the memlock limits
/etc/security/limits.conf:
  file:
    - append
    - text:
      - elasticsearch - memlock unlimited
      - root - memlock unlimited
    - require_in:
      - service: elasticsearch-svc

{% if grains.init == 'systemd' %}
# Fix the systemd script
/usr/lib/systemd/system/elasticsearch.service:
  ini:
    - options_present
    - sections:
        Service:
          LimitMEMLOCK: infinity
    - require:
      - pkg: elasticsearch
    - require_in:
      - service: elasticsearch-svc
{% endif %}
