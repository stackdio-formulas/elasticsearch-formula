{% set kibana_version = pillar.elasticsearch.kibana.version %}
{% set es_version = pillar.elasticsearch.version %}
{% set es_major_version = es_version.split('.')[0] | int %}
{% set kibana_major_version = kibana_version.split('.')[0] | int %}
{% set shield = salt['pillar.get']('elasticsearch:encrypted', False) %}

{% if es_version >= 5 %}
  {% set kibana_home = '/usr/share/kibana' %}
  {% set kibana_config = '/etc/kibana' %}
  {% set kibana_plugins = '/usr/share/kibana/plugins' %}
{% else %}
  {% set kibana_home = '/opt/kibana' %}
  {% set kibana_config = '/opt/kibana/config' %}
  {% set kibana_plugins = '/opt/kibana/installedPlugins' %}
{% endif %}

include:
  - elasticsearch.kibana.repo

kibana:
  pkg:
    - installed
    - version: {% if es_major_version >= 5 %}{{ es_version }}{% else %}{{ kibana_version }}{% endif %}-1
    - require:
      - file: kibana-repo

{% if pillar.elasticsearch.xpack.security.enabled or pillar.elasticsearch.encrypted %}
{{ kibana_config }}/kibana.key:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 400
    - contents_pillar: ssl:private_key
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

{{ kibana_config }}/kibana.crt:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 444
    - contents_pillar: ssl:chained_certificate
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

{{ kibana_config }}/ca.crt:
  file:
    - managed
    - user: kibana
    - group: kibana
    - mode: 444
    - contents_pillar: ssl:ca_certificate
    - require:
      - pkg: kibana
    - require_in:
      - pkg: kibana-svc

{% endif %}

{{ kibana_config }}/kibana.yml:
  file:
    - managed
    - source: salt://elasticsearch/etc/kibana/kibana-{% if es_major_version >= 5 %}{{ es_major_version }}{% else %}{{ kibana_major_version }}{% endif %}.yml
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: kibana

{% if es_major_version >= 5 %}
########
# ES >= 5 ONLY
########

{% if pillar.elasticsearch.xpack.install %}
########
# X-Pack
########

install-x-pack:
  cmd:
  - run
  - user: root
  - name: '/usr/share/kibana/bin/kibana-plugin install x-pack'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
  - unless: '/usr/share/kibana/bin/kibana-plugin list | grep x-pack'

{% endif %}


{% else %}

########
# ES < 5 ONLY
########

{% if shield %}
########
# Shield
########

install_shield:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install kibana/shield/{{ es_version }}'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
    - file: {{ kibana_home }}/optimize/.babelcache.json
  - unless: 'test -d /opt/kibana/installedPlugins/shield'
{% endif %}

{% if pillar.elasticsearch.marvel.install %}
########
# Marvel
########

{% set marvel_version = salt['pillar.get']('elasticsearch:marvel:version', 'latest') %}
install_marvel:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install elasticsearch/marvel/{{ marvel_version }}'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
    - file: {{ kibana_home }}/optimize/.babelcache.json
  - unless: 'test -d /opt/kibana/installedPlugins/marvel'
{% endif %}

{% if pillar.elasticsearch.kibana.sense %}
########
# Sense
########

install_sense:
  cmd:
  - run
  - user: root
  - name: '/opt/kibana/bin/kibana plugin --install elastic/sense'
  - require:
    - pkg: kibana
  - require_in:
    - service: kibana-svc
    - file: {{ kibana_home }}/optimize/.babelcache.json
  - unless: 'test -d /opt/kibana/installedPlugins/sense'
{% endif %}

{% endif %}



{{ kibana_home }}/optimize/.babelcache.json:
  file:
    - managed
    - user: kibana
    - group: kibana
    - require:
      - pkg: kibana

kibana-svc:
  service:
    - running
    - name: kibana
    - enable: true
    - require:
      - pkg: kibana
      - file: {{ kibana_home }}/optimize/.babelcache.json
    - watch:
      - file: {{ kibana_config }}/kibana.yml
