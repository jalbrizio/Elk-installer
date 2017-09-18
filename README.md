

# Elk-installer

## Elk Redhat install

__to install elk on CentOS__

__if you are using a vm either forward ssh and 5601 to the vm or set the vm network addapter to bridged__

__now disable your firewall (it will get turned back on in the script)__

`sudo iptables -F`

__find your ip address__

`ip addr`

__Next ssh to your server__

`ssh username@x.x.x.x`

__Now that you are logged in properly, install git then clone this repo__

__to do this run__

`sudo yum install git`

__then__

`sudo git clone https://github.com/jalbrizio/Elk-installer.git /usr/local/src/Elk-installer`

__once you have it downloaded sudo to root then run the install.sh__

`sudo su -`

`cd /usr/local/src/Elk-installer`

`chmod +x ./install*`

`./install.sh`

__now if you want the dashboards__

`./install-sof-elk.sh`

__now if you want to access the webpage openyour browser and enter the ip:5601__

`x.x.x.x:5601`

__If you want to cluster the elastic stack, them edit the elasticsearch.yml file__

`vim /etc/elasticsearch/elasticsearch.yml`

__now find the line that looks like #discovery.zen.ping.unicast.hosts: ["host1", "host2"]__ 

__and uncomment it, then change the hosts to the ip addresses of your elastic servers__

`sudo systemctl restart elasticsearch.service`


__If you want netflow data now you can point your router to one of these server over port 9995
If you use DDWRT go to Services and scroll down to the RFlow  section__

__thats it so far__


