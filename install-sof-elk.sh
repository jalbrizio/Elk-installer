#!/bin/bash
#
# Created by Jeremi Albrizio.
# Repo forked from Texiwill gepo and modified for my purposes. there is no warenty stated or implied.  use this as is and if copied please give me credit where aplicable.
# this also includes the sof-elk sans repo for dashboards and other needed info.
# Creation Date 09/13/2017
# Last modified date 09/14/2017
#
#
echo "set vim to use vi"
alias vim=vi
echo "check selinux and temperarily disable it while doing the install."
getenforce
setenforce 0
echo "temperarily disable iptables for the install"
iptables -F
echo "make sure your server is uptodate"
yum -y update

git clone https://github.com/philhagen/sof-elk.git /usr/local/sof-elk/
find /usr/local/sof-elk/ | grep \\. | egrep -v "\/$|.git"  | xargs sed -i s/\\/opt/\\/usr\\/share/g
yum -y install filebeat heartbeat metricbeat packetbeat logstash java-1.8.0-openjdk-devel unzip jq
ln -s /usr/local/sof-elk/configfiles/* /etc/logstash/conf.d/
ln -s  /usr/local/sof-elk/supporting-scripts/* /usr/local/sbin/
/usr/share/logstash/bin/logstash-plugin install logstash-filter-grok
ls /etc/logstash/conf.d/ | awk -F- '{print $2"-"$3"-"$4}' | sed s/-$//g| sed s/-$//g | sed s/.conf//g | sed s/^/logstash-/g | egrep -v "input-json|logstash-input-windows_json|logstash-input-suricata|logstash-input-passivedns|logstash-input-netflow|logstash-input-httpdlog|logstash-preprocess|logstash-netflow|logstash-bro|logstash-snare|logstash-squidlog|logstash-dhcpd|logstash-bindquery|logstash-passivedns|logstash-sshd|logstash-pam|logstash-iptables|logstash-cisco|logstash-http|logstash-switch_brocade|logstash-windows|logstash-dns_windows|logstash-android|logstash-suricata|logstash-postprocess|logstash-output-bro|logstash-output-switch|logstash-output-netflow|logstash-output-sflow|logstash-output-dhcp|logstash-output-esxi|logstash-output-greensql|logstash-output-httpdlog|logstash-output-mcafee|logstash-output-snort|logstash-output-firewall|logstash-output-windows|logstash-output-dns_windows|logstash-output-android|logstash-output-suricata|logstash-output-alerts|logstash-input-bro" | xargs /usr/share/logstash/bin/logstash-plugin install

sudo ln -s /etc/metricbeat/metricbeat.template.json /usr/share/metricbeat/bin/
sudo ln -s /etc/metricbeat/metricbeat.template-es2x.json /usr/share/metricbeat/bin/
sudo ln -s /etc/metricbeat/metricbeat.template-es6x.json /usr/share/metricbeat/bin/
nohup sudo /usr/share/metricbeat/bin/metricbeat -e -c /etc/metricbeat/metricbeat.full.yml  -setup &
##
wget -O /usr/local/src/setuptools-36.5.0.zip  https://pypi.python.org/packages/a4/c8/9a7a47f683d54d83f648d37c3e180317f80dc126a304c45dc6663246233a/setuptools-36.5.0.zip
unzip /usr/local/src/setuptools-36.5.0.zip -d /usr/local/src/
python /usr/local/src/setuptools-36.5.0/easy_install.py -U setuptools
pip install -r python-freez2.txt
# load sof elk dashboards
#/usr/local/sof-elk/supporting-scripts/load_all_dashboards.sh
