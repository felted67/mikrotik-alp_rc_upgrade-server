#!/bin/bash
mkdir /etc/apache2/conf.d
mkdir /opt/mikrotik.upgrade.server
mkdir /opt/mikrotik.upgrade.server/tools
mkdir /opt/mikrotik.upgrade.server/repo
mkdir /opt/mikrotik.upgrade.server/mikrotik.configs
mkdir /var/www/localhost/htdocs/mikrotikmirror
ln -s  /opt/mikrotik.upgrade.server/repo /var/www/localhost/htdocs/mikrotikmirror/repo
mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf.orig
mv /etc/apache2/httpd.new.conf /etc/apache2/httpd.conf
mv /root/mikrotikmirror.conf /etc/apache2/conf.d/
mv /root/upgrade.mikrotik.com.conf /etc/apache2/conf.d/
mv /root/index.html /var/www/localhost/htdocs/
tar xvfz /root/webserver.data.tar.gz /var/www/localhost/htdocs/mikrotikmirror
mv /root/mikrotik.sync.repos.sh /opt/mikrotik.upgrade.server/tools/
mv /root/routeros.7.15.conf /opt/mikrotik.upgrade.server/tools/mikrotik.configs/
chown apache:apache /var/www/localhost/htdocs/index.html
chown -r apache:apache /var/www/localhost/htdocs/
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
rc-update add sshd 
rc-update add apache2
rc-service sshd start
rc-service apache2 start
echo "****"
echo "'"
echo "Don't forget to set root-ssh password !!!"
echo "*"
echo "****"
echo "*"
echo "first_start.sh completed !"
echo "*"
echo "****"
rc-update del auto_init