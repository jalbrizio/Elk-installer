#!/bin/bash
echo "set vim to use vi"
alias vim=vi
echo "check selinux and temperarily disable it while doing the install."
getenforce
setenforce 0
echo "temperarily disable iptables for the install"
iptables -F
echo "make sure your server is uptodate"
yum -y update
echo "Install RSYSLOG Repo and update to latest RSYSLOG"
yum -y install wget ntp

#Author: Rainer Gerhards (rgerhards@adiscon.com)
#found at http://www.rsyslog.com/download/

wget http://rpms.adiscon.com/rsyslogall.repo

echo "	Move old rsyslog configurations"
mkdir /etc/rsyslog.d/olde
mv /etc/rsyslog.d/*.conf /etc/rsyslog.d/olde
mv rsyslogall.repo /etc/yum.repos.d
yum -y update rsyslog

echo "	Test rsyslogd configuration"
rsyslogd -N1

echo "Install ElasticSearch/Kibana Repo 5.x and update to latest"
# now for elasticsearch
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/elastic.co.repo << EOF

[elastic.co-5.x]
name=elastic.co repository for 5.x elasticsearch and kibana packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md

EOF
yum -y install java elasticsearch kibana

echo "Install ElasticSearch for RSYSLOG"
yum -y install rsyslog-elasticsearch


echo "Enable RSYSLOG IMJOURNAL for ElasticSearch"
echo "Disable RSYSLOG RateLimiting for ElasticSearch"
cp /etc/rsyslog.conf /etc/rsyslog.conf.olde
grep imjournal /etc/rsyslog.conf > /dev/null
if [ $? != 0 ]
then
	# Edit Rsyslog to add in imjournal
	sed "/immark/a\
module(load=\"imjournal\")
$IMUXSockRateLimitInterval 0
$IMJournalRatelimitInterval 0" < /etc/rsyslog.conf > /tmp/rsyslog.conf
	mv /tmp/rsyslog.conf /etc/rsyslog.conf
fi

echo "Disable RateLimit for Journald for RSYSLOG imjournal"
grep ^MaxRetentionSec /etc/systemd/journald.conf > /dev/null
if [ $? != 0 ]
then
	cat > /etc/systemd/journald.conf << EOF
Storage=volatile
Compress=no
RateLimitInterval=0
MaxRetentionSec=5s
EOF
fi

echo "Enable IMUDP/IMTCP for incoming from LogInsight"
grep "\#module(load=\"imudp\")" /etc/rsyslog.conf > /dev/null
if [ $? = 0 ]
then
	# Edit Rsyslog to enable UDP
	sed "s/#module(load=\"imudp\")/module(load=\"imudp\")/" < /etc/rsyslog.conf > /tmp/rsyslog.conf
	sed "s/#input(type=\"imudp\"/input(type=\"imudp\"/" < /tmp/rsyslog.conf > /etc/rsyslog.conf
fi
grep "\#module(load=\"imtcp\")" /etc/rsyslog.conf > /dev/null
if [ $? = 0 ]
then
	# Edit Rsyslog to enable TCP
	sed "s/#module(load=\"imtcp\")/module(load=\"imtcp\")/" < /etc/rsyslog.conf > /tmp/rsyslog.conf
	sed "s/#input(type=\"imtcp\"/input(type=\"imtcp\"/" < /tmp/rsyslog.conf > /etc/rsyslog.conf
fi

echo "Create ElasticSearch Configuration for RSYSLOG"
cat > /etc/rsyslog.d/elasticsearch.conf << EOF
module(load="omelasticsearch") # for outputting to Elasticsearch

# this is for index names to be like: logstash-YYYY.MM.DD
template(name="logstash-index"
  type="list") {
    constant(value="logstash-")
    property(name="timereported" dateFormat="rfc3339" position.from="1" position.to="4")
    constant(value=".")
    property(name="timereported" dateFormat="rfc3339" position.from="6" position.to="7")
    constant(value=".")
    property(name="timereported" dateFormat="rfc3339" position.from="9" position.to="10")
}

# this is for formatting our syslog in JSON with @timestamp
template(name="plain-syslog"
  type="list") {
    constant(value="{")
      constant(value="\"@timestamp\":\"")     property(name="timereported" dateFormat="rfc3339")
      constant(value="\",\"IP\":\"")          property(name="fromhost-ip")
      constant(value="\",\"host\":\"")        property(name="hostname")
      constant(value="\",\"severity\":\"")    property(name="syslogseverity-text")
      constant(value="\",\"facility\":\"")    property(name="syslogfacility-text")
      constant(value="\",\"tag\":\"")   property(name="syslogtag" format="json")
      constant(value="\",\"message\":\"")    property(name="msg" format="json")
    constant(value="\"}")
}

action(type="omelasticsearch"
        server="localhost"
        serverport="9200"
        template="plain-syslog"  # use the template defined earlier
        searchIndex="logstash-index"
        dynSearchIndex="on"
        searchType="events"
        bulkmode="on"                   # use the Bulk API
        queue.dequeuebatchsize="5000"   # ES bulk size
        queue.size="100000"   # capacity of the action queue
        queue.workerthreads="5"   # 5 workers for the action
        action.resumeretrycount="-1"  # retry indefinitely if ES is unreachable
        errorfile="/var/log/omelasticsearch.log"
        )
EOF

cat >> /etc/sysctl.conf << EOF
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
EOF

#
## Do we need EPEL
echo "Install Python-PIP for Curator"
rpm -qa |grep " epel-release " >> /dev/null
if [ $? != 0 ]
then
	yum -y install epel-release
fi
yum -y install python-pip

echo "Install Curator to delete logfiles after 30 days"
#
## Look for existing curator
grep curator /etc/crontab >> /dev/null
if [ $? != 0 ]
then
	cat >> /etc/crontab << EOF
0 4 * * * /usr/bin/curator –host localhost –prefix logstash- -c 5 -d 30 –timeout 3600 > /dev/null 2>&1
EOF
fi

echo "Set permissions on /data director for ElasticSearch"
if [ -e /data ]
then
	chown elasticsearch.elasticsearch /data
else
	echo "ERROR: NEED /data repository"
	exit
fi

echo "Setup ElasticSearch Configuration"
cat > /etc/elasticsearch/elasticsearch.yml << EOF
# ======================== Elasticsearch Configuration =========================
#
# NOTE: Elasticsearch comes with reasonable defaults for most settings.
#       Before you set out to tweak and tune the configuration, make sure you
#       understand what are you trying to accomplish and the consequences.
#
# The primary way of configuring a node is via this file. This template lists
# the most important settings you may want to configure for a production cluster.
#
# Please see the documentation for further information on configuration options:
# <http://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html>
#
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
cluster.name: elasticsearch
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
#node.name: primary
#
# Add custom attributes to the node:
#
# node.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
# path.data: /path/to/data
path.data: /data
#
# Path to log files:
#
# path.logs: /path/to/logs
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
bootstrap.mlockall: true
#
# Make sure that the \`ES_HEAP_SIZE\` environment variable is set to about half the memory
# available on the system and that the owner of the process is allowed to use this limit.
#
# Elasticsearch performs poorly when the system is swapping the memory.
#
# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#
# network.host: 192.168.0.1
#
# Set a custom port for HTTP:
#
# http.port: 9200
#
# For more information, see the documentation at:
# <http://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html>
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when new node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#
# discovery.zen.ping.unicast.hosts: ["host1", "host2"]
#
# Prevent the "split brain" by configuring the majority of nodes (total number of nodes / 2 + 1):
#
# discovery.zen.minimum_master_nodes: 3
#
# For more information, see the documentation at:
# <http://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html>
#
# ---------------------------------- Gateway -----------------------------------
#
# Block initial recovery after a full cluster restart until N nodes are started:
#
# gateway.recover_after_nodes: 3
#
# For more information, see the documentation at:
# <http://www.elastic.co/guide/en/elasticsearch/reference/current/modules-gateway.html>
#
# ---------------------------------- Various -----------------------------------
#
# Disable starting multiple nodes on a single system:
#
# node.max_local_storage_nodes: 1
#
# Require explicit names when deleting indices:
#
# action.destructive_requires_name: true
EOF

l=`basename $0`
y=`ls ${l}.* | awk -F\. '{print $3}'`
n=`ls ${l}.* | wc -l`
x=""
if [ $n -gt 1 ]
then
	echo -n "Enter one of the following security options for ES:"
	echo $y
	echo $y |grep X >& /dev/null
	while [ $? != 0 ]
	do
		read x
		echo $y |grep $y >& /dev/null
	done
elif [ $n == 1 ]
then
	x=$y
fi
if [ $n == 0 ]
then
	source ./${l}.${x}
fi

echo "Setup Firewall Policy to allow SYSLOG incoming and Kibana Access"
systemctl status firewalld | grep ": active" >& /dev/null
if [ $? != 1 ]
then
	if [ $nginx != 1 ]
	then
		firewall-cmd --permanent --add-port=5601/tcp
	else
		firewall-cmd --permanent --add-port=443/tcp
	fi
	firewall-cmd --permanent --add-port=514/tcp
	firewall-cmd --permanent --add-port=514/udp
	firewall-cmd --reload
fi
systemctl status iptables | grep ": active" >& /dev/null
if [ $? != 1 ]
then
	if [ $nginx != 1 ]
	then
		sed '/-A INPUT -j REJECT/i\
-A INPUT -m state --state NEW -m tcp p -tcp --dport 5601 -j ACCEPT\n\
-A INPUT -m state --state NEW -m tcp p -tcp --dport 514 -j ACCEPT\n\
-A INPUT -m state --state NEW -m udp p -udp --dport 514 -j ACCEPT' /etc/sysconfig/iptables > /tmp/iptables
	else
		sed '/-A INPUT -j REJECT/i\
-A INPUT -m state --state NEW -m tcp p -tcp --dport 443 -j ACCEPT\n\
-A INPUT -m state --state NEW -m tcp p -tcp --dport 514 -j ACCEPT\n\
-A INPUT -m state --state NEW -m udp p -udp --dport 514 -j ACCEPT' /etc/sysconfig/iptables > /tmp/iptables
	fi
	mv /tmp/iptables /etc/sysconfig

fi

echo "Now to fix SELinux for Rsyslog + ES"
restorecon -r /etc/rsyslog.d
semanage port -a -t syslogd_port_t -p tcp 9200
restorecon -R -v /dev

echo "Restart the Daemons"
sysctl -p
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl enable kibana.service
systemctl restart systemd-journald.service
systemctl restart rsyslog.service
systemctl restart elasticsearch.service
systemctl restart kibana.service

echo "Sending first message"
logger "My First Message!"
