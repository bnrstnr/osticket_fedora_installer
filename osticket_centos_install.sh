#!/bin/bash

#Installation Script by Nick Hulslander
#https://raw.githubusercontent.com/bnrstnr/osticket_fedora_installer/master/osticket_centos_install.sh

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

osticket="https://github.com/osTicket/osTicket"

echo "Installing osTicket for CentOS 7 Minimal"
echo "If you have not made a DNS entry for the system,"
echo "it is recommended that you do so now."
echo ""
echo "Enter the database password for osTicket: "
read ostpass
echo "Enter the MariaDB root user password: "
read rootpass
#echo "Enter the name of your web admin user account (ex. admin)"
#read adminuser
#echo "Enter the initial password for admin"
#read adminpass

export osticketpath='/var/www/html/helpdesk'
export datapath='/data'
export httpdrw='httpd_sys_rw_content_t'

#Install required packages
yum -y update
yum -y install epel-release wget
wget https://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm

cd /etc/yum.repos.d
wget https://rpms.remirepo.net/enterprise/remi.repo

yum -y --enablerepo=remi-php56 install git unzip httpd mariadb mariadb-server php php-gd php-gettext php-imap php-json php-mbstring php-xml php-mysqlnd php-apc php-intl php-pecl-zendopcache

#Install optional packages
#yum -y install nano dnf-automatic fail2ban policycoreutils-python-utils

#Start Services
systemctl enable --now httpd.service
systemctl enable --now mariadb.service

#Open the firewall for http and https
firewall-cmd --add-port=http/tcp --permanent
firewall-cmd --add-port=https/tcp --permanent
firewall-cmd --reload

#Setup MariaDB
mysql -e "CREATE DATABASE ost_db;"
mysql -e "CREATE USER 'ost_user'@'localhost' IDENTIFIED BY '$ostpass';"
mysql -e "GRANT ALL ON ost_db.* TO 'ost_user'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

#Secure MariaDB
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$rootpass') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE test;"
mysql -e "FLUSH PRIVILEGES;"

#Setup osTicket
cd
git clone $osticket
cd osTicket
php manage.php deploy --setup /var/www/html/helpdesk
chown -R apache:apache /var/www/html/helpdesk
cp include/ost-sampleconfig.php include/ost-config.php
chmod 0666 include/ost-config.php

sed -i -e 's/;

