  #    Elk-installer
** Elk Redhat install


# to install elk on CentOS
# first install git then clone this repo
# to do this run
sudo yum install git
# then
sudo git clone https://github.com/jalbrizio/Elk-installer.git /usr/local/src/Elk-installer
# once you have it downloaded sudo to root then run the install.sh
sudo su -
cd /usr/local/src/Elk-installer
chmod +x ./installer*
./installer.sh
# now if you want the dashboards 
 ./install-sof-elk.sh
# thats it so far. 
