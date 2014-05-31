#!/bin/sh

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

# install new packages
yum install -y nano wget dkms binutils gcc git-core gcc-c++ make patch libgomp glibc-headers glibc-devel kernel-headers kernel-devel bzip2 perl mongodb-org-server mongodb-org-shell mongodb-org-tools npm

#install global npm packages
npm install -g coffee-script meteorite meteor-npm

#install meteor
curl https://install.meteor.com/ | sh
