import_repo_key:
  cmd:
  - run
  - name: 'rpm --import https://packages.elasticsearch.org/GPG-KEY-elasticsearch'
  - unless: 'rpm -qa | grep elasticsearch'


/etc/yum.repos.d/elasticsearch.repo:
  file:
    - managed
    - mkdirs: false
    - source: salt://elasticsearch/etc/yum.repos.d/elasticsearch.repo
    - user: root
    - group: root
    - mode: 644
    - require:
      - cmd: import_repo_key


elasticsearch:
  pkg.installed:
    - require:
      - file: /etc/yum.repos.d/elasticsearch.repo


{% set dirs = ['', '/data', '/work', '/logs'] %}

{% for dir in dirs %}
/mnt/elasticsearch{{ dir }}:
  file:
    - directory
    - user: elasticsearch
    - group: elasticsearch
    - mode: 755
    - require:
      - pkg: elasticsearch

{% endfor %}
