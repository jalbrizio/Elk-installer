#!/bin/bash
#
# Created by Jeremi Albrizio. 
# Repo forked from Texiwill gepo and modified for my purposes. there is no warenty stated or implied.  use this as is and if copied please give me credit where aplicable.
# this also includes the sof-elk sans repo for dashboards and other needed info and includes WUZA for adding HIDS.
# Creation Date 09/13/2017
# Last modified date 10/4/2017
#
#
cat > /etc/yum.repos.d/wazuh.repo <<\EOF
[wazuh_repo]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=CentOS-$releasever - Wazuh
baseurl=https://packages.wazuh.com/yum/el/$releasever/$basearch
protect=1
EOF

yum -y install wazuh-manager
systemctl status wazuh-manager
systemctl enable wazuh-manager
curl --silent --location https://rpm.nodesource.com/setup_6.x | bash -
yum -y install nodejs wazuh-api

systemctl daemon-reload
systemctl status wazuh-manager
systemctl status wazuh-api
systemctl enable wazuh-manager
systemctl enable wazuh-api
systemctl restart filebeat.service

curl https://raw.githubusercontent.com/wazuh/wazuh-kibana-app/2.1/server/startup/integration_files/template_file.json | curl -XPUT 'http://localhost:9200/_template/wazuh' -H 'Content-Type: application/json' -d @-


curl https://raw.githubusercontent.com/wazuh/wazuh-kibana-app/2.1/server/startup/integration_files/alert_sample.json | curl -XPUT "http://localhost:9200/wazuh-alerts-"`date +%Y.%m.%d`"/wazuh/sample" -H 'Content-Type: application/json' -d @-

/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip

#If you have an older version of kibana go https://github.com/wazuh/wazuh-kibana-app and pick your version

#/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-2.1.1_5.6.1.zip

sudo systemctl restart kibana

#
# Now follow the instructions here https://documentation.wazuh.com/current/installation-guide/installing-elastic-stack/connect_wazuh_app.html
# add firewall ports to allow incommint connections.
firewall-cmd --permanent --add-port=1514/udp
firewall-cmd --reload

