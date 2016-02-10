gcc-c++:
  pkg:
    - installed
    - require:
      - pkg: sensu

es-sensu-plugin:
  cmd.run:
    - name: /opt/sensu/embeded/bin/gem install sensu-plugins-elasticsearch
    - require:
        - file: /etc/sensu/plugins
        - pkg: gem-pkgs
        - pkg: sensu-client-pkg


