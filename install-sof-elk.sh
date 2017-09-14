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
yum install filebeat heartbeat metricbeat packetbeat logstash
ln -s /usr/local/sof-elk/configfiles/* /etc/logstash/conf.d/
