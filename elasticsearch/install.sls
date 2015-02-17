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


make_mnt_dirs:
  cmd:
  - script
  - template: jinja
  - user: root
  - source: salt://elasticsearch/create_mnt_dirs.sh
  - unless: '[ -d /mnt/elasticsearch ]'