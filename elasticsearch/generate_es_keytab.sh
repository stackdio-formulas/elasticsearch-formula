{%- from 'krb5/settings.sls' import krb5 with context %}
{%- set realm = krb5.realm -%}
#!/bin/bash

export KRB5_CONFIG={{ pillar.krb5.conf_file }}

(
echo "addprinc -randkey elasticsearch/{{ grains.fqdn }}"
echo "xst -k krb5.keytab elasticsearch/{{ grains.fqdn }}"
) | kadmin -p kadmin/admin -kt /root/admin.keytab -r {{ realm }}

chown elasticsearch:elasticsearch krb5.keytab
chmod 400 krb5.keytab
