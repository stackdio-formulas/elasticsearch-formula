# repo logstash
logstash-repo:
  pkgrepo:
    - managed
{% if grains["os_family"] == "Debian" %}
    - key_url: https://packages.elasticsearch.org/GPG-KEY-elasticsearch
    - name: deb https://packages.elastic.co/logstash/2.3/debian stable main
    - refresh_db: true
{% elif grains["os_family"] == "RedHat" %}
    - humanname: logstash
    - name: logstash-2.3
    - baseurl: https://packages.elastic.co/logstash/2.3/centos
    - gpgcheck: 1
    - gpgkey: https://packages.elastic.co/GPG-KEY-elasticsearch
    - enabled: 1
{% endif %}


logstash-pkg:
  pkg:
    - installed
    - name: logstash
    - require:
      - pkgrepo: logstash-repo


