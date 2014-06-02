#!/bin/sh

# the following command starts this script
# curl -L https://raw.githubusercontent.com/Zaku-eu/meteor-droplet-scripts/master/fedora.sh | /bin/sh

# build for fedora 20 x64 droplet of digitalocean

# add mongodb repo
echo "[mongodb]
name=MongoDB Repository
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/
gpgcheck=0
enabled=1
" >> /etc/yum.repos.d/mongodb.repo

# update installed packages
yum update -y

# install new packages                   <-| The first five packages are currently part of the default image - i leave them for legacy support
yum install -y nano wget make libgomp bzip2 mc dkms binutils gcc git-core gcc-c++ patch glibc-headers glibc-devel kernel-headers kernel-devel perl mongodb-org-server mongodb-org-shell mongodb-org-tools npm

# install global npm packages
npm install -g coffee-script meteorite meteor-npm

# install meteor
curl https://install.meteor.com/ | sh

# additional
#echo "[google-chrome]
#name=google-chrome - 64-bit
#baseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64
#enabled=1
#gpgcheck=1
#gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub
#" >> /etc/yum.repos.d/google-chrome.repo
#yum install -y google-chrome-stable

mkdir /root/tmp -p
cd /root/tmp
wget http://download.documentfoundation.org/libreoffice/stable/4.2.4/rpm/x86_64/LibreOffice_4.2.4_Linux_x86-64_rpm.tar.gz
tar -xvf LibreOffice_*
cd LibreOffice_*
yum localinstall -y RPMS/*.rpm
yum install -y unoconv pdftk

cd /root
rm tmp -fr
rm /etc/rc.d/init.d/mongod -f

echo '#!/bin/bash

# mongod - Startup script for mongod

# chkconfig: 35 85 15
# description: Mongo is a scalable, document-oriented database.
# processname: mongod
# config: /etc/mongod.conf
# pidfile: /var/run/mongodb/mongod.pid

. /etc/rc.d/init.d/functions

# things from mongod.conf get there by mongod reading it


# NOTE: if you change any OPTIONS here, you get what you pay for:
# this script assumes all options are in the config file.
CONFIGFILE="/etc/mongod.conf"
OPTIONS=" -f $CONFIGFILE"
SYSCONFIG="/etc/sysconfig/mongod"

# FIXME: 1.9.x has a --shutdown flag that parses the config file and
# shuts down the correct running pid, but that'\''s unavailable in 1.8
# for now.  This can go away when this script stops supporting 1.8.
DBPATH=`awk -F= '\''/^dbpath[[:blank:]]*=[[:blank:]]*/{print $2}'\'' "$CONFIGFILE"`
PIDFILE=`awk -F= '\''/^pidfilepath[[:blank:]]*=[[:blank:]]*/{print $2}'\'' "$CONFIGFILE"`
mongod=${MONGOD-/usr/bin/mongod}

MONGO_USER=mongod
MONGO_GROUP=mongod

if [ -f "$SYSCONFIG" ]; then
    . "$SYSCONFIG"
fi

# Handle NUMA access to CPUs (SERVER-3574)
# This verifies the existence of numactl as well as testing that the command works
NUMACTL_ARGS="--interleave=all"
if which numactl >/dev/null 2>/dev/null && numactl $NUMACTL_ARGS ls / >/dev/null 2>/dev/null
then
    NUMACTL="numactl $NUMACTL_ARGS"
else
    NUMACTL=""
fi

start()
{
  # Recommended ulimit values for mongod or mongos
  # See http://docs.mongodb.org/manual/reference/ulimit/#recommended-settings
  #
  ulimit -f unlimited
  ulimit -t unlimited
  ulimit -v unlimited
  ulimit -n 64000
  ulimit -m unlimited
  ulimit -u 32000

  mkdir -p -m0755 /var/run/mongodb
  chown mongod:mongod /var/run/mongodb

  echo -n $"Starting mongod: "
  daemon --user "$MONGO_USER" "$NUMACTL $mongod $OPTIONS >/dev/null 2>&1"
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && touch /var/lock/subsys/mongod
}

stop()
{
  echo -n $"Stopping mongod: "
  killproc -p "$PIDFILE" -d 300 /usr/bin/mongod
  RETVAL=$?
  echo
  [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/mongod
}

restart () {
  stop
  start
}


RETVAL=0

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart|reload|force-reload)
    restart
    ;;
  condrestart)
    [ -f /var/lock/subsys/mongod ] && restart || :
    ;;
  status)
    status $mongod
    RETVAL=$?
    ;;
  *)
    echo "Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart}"
    RETVAL=1
esac

exit $RETVAL' > /etc/rc.d/init.d/mongod
chmod +x /etc/rc.d/init.d/mongod
systemctl enable mongod.service

firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp

#echo '#!/bin/bash
#
#' >> /etc/rc.local
#chmod +x /etc/rc.local
#systemctl enable rc-local.service

cd /root
git clone https://github.com/Zaku-eu/colourco.de.git

reboot
