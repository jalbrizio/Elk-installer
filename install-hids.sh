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
