#!/bin/sh
#
# Create an ERK - ElasticStack Rsyslog Kibana Stack - nginx installer
#
# Target: CentOS/RHEL 7
#
###
# Reference: 
###
nginx=1

echo "Setup Nginx Proxy"
yum -y install nginx httpd-tools policycoreutils-python setroubleshoot-server

if [ ! -e /etc/nginx/ssl/cert.pem ]
then
	echo "Create SSL Certs"
	mkdir /etc/nginx/ssl
	cd /etc/nginx/ssl
	openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes
fi
	
if [ ! -e /etc/nginx/conf.d/kibana.htpasswd ]
then
	echo "Create Admin and a User users"
	htpasswd -c /etc/nginx/conf.d/kibana.htpasswd admin
	echo -n "Operator Username: "
	read u
	echo -n "Operator Password: "
	read p
	htpasswd -b /etc/nginx/conf.d/kibana.htpasswd $u $p
fi

grep server /etc/nginx/nginx.conf >& /dev/null
if [ $? != 1 ]
then
	echo "cleanup nginx.conf"
	sed '/server {/,/^    }/d' /etc/nginx/nginx.conf > /tmp/nginx.conf
	mv /tmp/nginx.conf /etc/nginx
fi

echo "setup Kibana.conf for Nginx"
n=`uname -n`
cat > /etc/nginx/conf.d/kibana.conf << EOF
upstream kibana {
    server 127.0.0.1:5601 fail_timeout=0;
}

server {
    listen      80;
    return 301 https://${n};
}

server {
  listen                *:443 ;
  ssl on;
  ssl_certificate /etc/nginx/ssl/cert.pem;
  ssl_certificate_key /etc/nginx/ssl/key.pem;

  server_name           ${n};
  access_log            /var/log/nginx/kibana.access.log;

  location / {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/conf.d/kibana.htpasswd;
    proxy_pass http://kibana;
  }
}
EOF

echo "Test Nginx"
nginx -t

echo "Setup Kibana"
echo "server.host: localhost" >> /opt/kibana/config/kibana.yml

echo "Fix SELINUX for NGINX"
restorecon -r /etc/nginx
semanage port -a -t http_port_t -p tcp 5601
chcon -R -t httpd_sys_content_t  /opt/kibana/{src,node}

echo "If SELinux issues pop up use the following to debug:"
echo "	sealert -a /var/log/audit/audit.log"

echo "Start the Daemons - Kibana will be restarted in parent script"
systemctl daemon-reload
systemctl enable nginx
systemctl restart kibana # just in case it is running
systemctl start nginx

systemctl enable nginx.service
systemctl restart nginx.service
cp /var/log/nginx/error.log /var/log/nginx/error.log-backup
errorinlog=`grep  "unexpected end of file\, expecting \"\}\"" /var/log/nginx/error.log  | tail -n 1`
#echo $errorinlog
if [ -z "$errorinlog" ]; then
echo "no errors in startup log"
else
echo "}" >> /etc/nginx/nginx.conf
cat /dev/null > /var/log/nginx/error.log
systemctl restart nginx.service
fi
