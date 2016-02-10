gcc-c++:
  pkg:
    - installed
    - require:
      - pkg: sensu

es-sensu-plugin:
  cmd.run:
    - name: /opt/sensu/embeded/bin/gem install sensu-plugins-elasticsearch
        - env:
        - PLUGINS_DIR: /etc/sensu/plugins
        - HANDLERS_DIR: /etc/sensu/handlers
        - GEM_PATH: /opt/sensu/embedded/lib/ruby/gems/2.0.0
    - require:
        - file: /etc/sensu/plugins
        - pkg: gem-pkgs
        - pkg: sensu-client-pkg


