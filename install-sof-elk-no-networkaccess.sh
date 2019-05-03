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

echo "pulling the latest sof-elk repo"
echo "If you have access uncomment this line otherwise manually copy the sof-elk repo to /usr/local/sof-elk"
#git clone https://github.com/philhagen/sof-elk.git /usr/local/sof-elk/

find /usr/local/sof-elk/ | grep \\. | egrep -v "\/$|.git"  | xargs sed -i s/\\/opt/\\/usr\\/share/g
find /usr/local/sof-elk/ | grep \\. | egrep -v "\/$|.git"  | xargs sed -i s/darkTheme\\\\\"\:true/darkTheme\\\\\"\:false/g
echo "installing the rpms needed for beats to work"
yum -y install filebeat heartbeat metricbeat packetbeat logstash java-1.8.0-openjdk-devel unzip jq
echo "linking the netflow configs to logstash"
ln -s /usr/local/sof-elk/configfiles/*netflow* /etc/logstash/conf.d/
echo "linking the syslog configs to logstash"
ln -s /usr/local/sof-elk/configfiles/*syslog* /etc/logstash/conf.d/
echo"installing the relp logstash plogin so the syslog logstash setting work"
/usr/share/logstash/bin/logstash-plugin install logstash-input-relp
echo "linking the syslog-httpdlog configs to logstash"
ln -s /usr/local/sof-elk/configfiles/*httpdlog* /etc/logstash/conf.d/

echo "linking the supporting scripts to the proper location"
ln -s  /usr/local/sof-elk/supporting-scripts/* /usr/local/sbin/
##
#

echo "If you have access uncomment this line otherwise manually copy the setup tools to /usr/local/src/setuptools-36.5.0.zip"
#wget -O /usr/local/src/setuptools-36.5.0.zip  https://pypi.python.org/packages/a4/c8/9a7a47f683d54d83f648d37c3e180317f80dc126a304c45dc6663246233a/setuptools-36.5.0.zip
unzip /usr/local/src/setuptools-36.5.0.zip -d /usr/local/src/
yes | pip uninstall setuptools
pip install --upgrade pip
python /usr/local/src/setuptools-36.5.0/easy_install.py -U setuptools
sleep 3
pip install --upgrade pip
pip install -r python-freez2.txt

##
#
echo "installing logstash filter grok"
/usr/share/logstash/bin/logstash-plugin install logstash-filter-grok
echo "installing the rest of the logstash plugins"
ls /usr/local/sof-elk/configfiles/ | awk -F- '{print $2"-"$3"-"$4}' | sed s/-$//g| sed s/-$//g | sed s/.conf//g | sed s/^/logstash-/g | egrep -v "input-json|logstash-input-windows_json|logstash-input-suricata|logstash-input-passivedns|logstash-input-netflow|logstash-input-httpdlog|logstash-preprocess|logstash-netflow|logstash-bro|logstash-snare|logstash-squidlog|logstash-dhcpd|logstash-bindquery|logstash-passivedns|logstash-sshd|logstash-pam|logstash-iptables|logstash-cisco|logstash-http|logstash-switch_brocade|logstash-windows|logstash-dns_windows|logstash-android|logstash-suricata|logstash-postprocess|logstash-output-bro|logstash-output-switch|logstash-output-netflow|logstash-output-sflow|logstash-output-dhcp|logstash-output-esxi|logstash-output-greensql|logstash-output-httpdlog|logstash-output-mcafee|logstash-output-snort|logstash-output-firewall|logstash-output-windows|logstash-output-dns_windows|logstash-output-android|logstash-output-suricata|logstash-output-alerts|logstash-input-bro" | xargs /usr/share/logstash/bin/logstash-plugin install
echo "linking metricbeat templates to the proper location then starting metricbeat"
sudo ln -s /etc/metricbeat/metricbeat.template.json /usr/share/metricbeat/bin/
sudo ln -s /etc/metricbeat/metricbeat.template-es2x.json /usr/share/metricbeat/bin/
sudo ln -s /etc/metricbeat/metricbeat.template-es6x.json /usr/share/metricbeat/bin/
nohup sudo /usr/share/metricbeat/bin/metricbeat -e -c /etc/metricbeat/metricbeat.full.yml  -setup &
##

#wget -O /usr/local/src/setuptools-36.5.0.zip  https://pypi.python.org/packages/a4/c8/9a7a47f683d54d83f648d37c3e180317f80dc126a304c45dc6663246233a/setuptools-36.5.0.zip
#unzip /usr/local/src/setuptools-36.5.0.zip -d /usr/local/src/
#yes | pip uninstall setuptools
#pip install --upgrade pip
#python /usr/local/src/setuptools-36.5.0/easy_install.py -U setuptools
#sleep 3
#pip install --upgrade pip
#pip install -r python-freez2.txt

echo "make sure all of the beats autostart"
systemctl enable metricbeat.service
systemctl enable packetbeat.service
systemctl enable heartbeat.service
systemctl enable filebeat.service

systemctl restart metricbeat.service
systemctl restart packetbeat.service
systemctl restart heartbeat.service
systemctl restart filebeat.service

echo "set the firewall rules to allow incomming connections for logs to be imported"

firewall-cmd --permanent --add-port=5514/tcp
firewall-cmd --permanent --add-port=5515/tcp
firewall-cmd --permanent --add-port=5516/tcp
firewall-cmd --permanent --add-port=5517/tcp
firewall-cmd --permanent --add-port=9995/tcp
firewall-cmd --reload

echo "It would be best to reboot now but thats up to you"
# load sof elk dashboards
#/usr/local/sof-elk/supporting-scripts/load_all_dashboards.sh
