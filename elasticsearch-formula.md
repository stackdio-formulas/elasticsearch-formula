# elasticsearch-formula
Stackd.IO formula for elasticsearch

---
Maybe use this kind of format? https://github.com/pravka/salt-consul


Supports both 1.x and 2.x versions of ES. 

Not all plugins support all versions.

---
Pillar data options:


    elasticsearch:
        version: 1.5, 1.7, 2.x
        heap_size: 1g <- should be 50% of avalable ram
        replicas: 2 <- defailt number of replicas for indexes
        discover_master: false <- set true to enable zen discovery
        marvel:
            install: true
            version: latest
            external_cluster: null <- FQDN of an external monitoring cluster
            is_external: null <- set True if this will be used as an external monitoring cluster for other ES clusters
        kibana:
            version: 4.4.0
            sense: true <- install kibana sense plugin, only for ES 2.x
        encrypted: false
        encryption:
            certificate: CHANGE_ME
            private_key: CHANGE_ME
        aws:
            install: false <- install the aws-cloud ES plugin
            region: null
            access_key: null
            secret_key: null


