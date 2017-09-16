

# Elk-installer

## Elk Redhat install

__to install elk on CentOS__

__if you are using a vm either forward ssh and 5601 to the vm or set the vm network addapter to bridged__

__now disable your firewall (it will get turned back on in the script)__

`sudo iptables -F`

__ find your ip address __

`ip addr`

__ Next ssh to your server__

`ssh username@x.x.x.x`

__ Now that you are logged in properly, install git then clone this repo__

__to do this run__

`sudo yum install git`

__then__

`sudo git clone https://github.com/jalbrizio/Elk-installer.git /usr/local/src/Elk-installer`

__once you have it downloaded sudo to root then run the install.sh__

`sudo su -`

`cd /usr/local/src/Elk-installer`

`chmod +x ./install*`

`./install.sh`

__now if you want the dashboards __

`./install-sof-elk.sh`

__now if you want to access
__thats it so far. __
