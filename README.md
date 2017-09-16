

# Elk-installer

## Elk Redhat install

__to install elk on CentOS__

__first install git then clone this repo__

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

__thats it so far. __
