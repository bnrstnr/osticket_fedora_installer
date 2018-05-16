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
echo ""
echo "Setup for the osTicket Database"
echo "Enter the database password for osTicket: "
read ostpass
echo "Enter the MariaDB root user password: "
read rootpass
echo ""
echo "Setup osTicket"
echo "Helpdesk Name? (The name of your support system e.g. [Company Name] Support"
read ostname
echo "Default System Email? (Default email address e.g. support@yourcompany.com - you can add more later!"
read ostemail
echo ""
echo "Setup for the osTicket Admin User"
echo "Admin First Name"
read adminfname
echo "Admin Last Name"
read adminlname
echo "Admin Email Address (Admin's personal email address. Must be different from system's default email.)"
read adminemail
echo "Username (Admin's login name. Must be at least three (3) characters.)"
read adminusername
echo "Password (Admin's password.  Must be five (5) characters or more.)"
read adminpass

#export osticketpath='/var/www/html/helpdesk'
#export datapath='/data'
#export httpdrw='httpd_sys_rw_content_t'

#Install required packages
yum -y update
yum -y install epel-release wget
wget https://rpms.remirepo.net/enterprise/remi-release-7.rpm
rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm

cd /etc/yum.repos.d
wget https://rpms.remirepo.net/enterprise/remi.repo

yum -y --enablerepo=remi-php56 install git httpd mariadb mariadb-server php php-gd php-gettext php-imap php-json php-mbstring php-xml php-mysqlnd php-apc php-intl php-pecl-zendopcache

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
cd /tmp/
git clone $osticket
cd osTicket
php manage.php deploy --setup /var/www/html/helpdesk
chown -R apache:apache /var/www/html/helpdesk
cd /var/www/html/helpdesk
cp include/ost-sampleconfig.php include/ost-config.php
chcon -t httpd_sys_rw_content_t /var/www/html/helpdesk -R

sed -i -e 's/%ADMIN-EMAIL/$adminemail/'     /var/www/html/helpdesk/include/ost-config.php
sed -i -e 's/%CONFIG-DBHOST/localhost/'     /var/www/html/helpdesk/include/ost-config.php
sed -i -e 's/%CONFIG-DBNAME/ost_db/'        /var/www/html/helpdesk/include/ost-config.php
sed -i -e 's/%CONFIG-DBUSER/ost_user/'      /var/www/html/helpdesk/include/ost-config.php
sed -i -e 's/%CONFIG-DBPASS/$ostpass/'      /var/www/html/helpdesk/include/ost-config.php
sed -i -e 's/%CONFIG-PREFIX/ost_/'          /var/www/html/helpdesk/include/ost-config.php

cd /var/www/html/helpdesk/setup
sudo -u apache php install.php fname=$adminfname lname=$adminlname admin_email=$adminemail
