#!/bin/bash

#Installation Script by Nick Hulslander
#https://raw.githubusercontent.com/bnrstnr/osticket_fedora_installer/master/osticket_install.sh

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

osticket="https://github.com/osTicket/osTicket"

echo "Installing osTicket for Fedora 28 Server or Minimal"
echo "If you have not made a DNS entry for the system,"
echo "it is recommended that you do so now."
echo ""
echo "Enter the database password for osTicket: "
read osticketdbpass
echo "Enter the root MariaDB user password: "
read rootpass
echo "Enter the name of your web admin user account (ex. admin)"
read adminuser
echo "Enter the initial password for admin"
read adminpass

export osticketpath='/var/www/html/osticket'
export datapath='/data'
export httpdrw='httpd_sys_rw_content_t'

#Install required packages
dnf -y install https://rpms.remirepo.net/fedora/remi-release-28.rpm
dnf -y --enablerepo=remi install wget git unzip httpd mariadb mariadb-server php56-php php56-php-gd php56-php-gettext php56-php-imap php56-php-json php56-php-mbstring php56-php-xml php56-php-mysqlnd php56-php-apc

#Install optional packages
#dnf -y install nano dnf-automatic fail2ban policycoreutils-python-utils

ln -s /opt/remi/php56/root/usr/bin/php /usr/bin/php

#Open the firewall for http and https
firewall-cmd --add-port=http/tcp --permanent
firewall-cmd --add-port=https/tcp --permanent
firewall-cmd --reload

#Setup MariaDB
mysql -e "CREATE DATABASE nextcloud;"
mysql -e "CREATE USER 'ncuser'@'localhost' IDENTIFIED BY '$ncpass';"
mysql -e "GRANT ALL ON nextcloud.* TO 'ncuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"
mysql -e "UPDATE mysql.user SET Password=PASSWORD('$rootpass') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DROP DATABASE test;"
mysql -e "FLUSH PRIVILEGES;"

git clone $osticket


