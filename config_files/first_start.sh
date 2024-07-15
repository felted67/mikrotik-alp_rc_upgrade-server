#!/bin/bash
mkdir /etc/apache2/conf.d
mkdir /opt/mikrotik.upgrade.server
mkdir /opt/mikrotik.upgrade.server/tools
mkdir /opt/mikrotik.upgrade.server/repo
mkdir /opt/mikrotik.upgrade.server/tools/mikrotik.configs
mkdir /var/www/localhost/htdocs/mikrotikmirror
ln -s  /opt/mikrotik.upgrade.server/repo /var/www/localhost/htdocs/mikrotikmirror/repo
mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf.orig
mv /etc/apache2/httpd.new.conf /etc/apache2/httpd.conf
mv /root/mikrotikmirror.conf /etc/apache2/conf.d/
mv /root/upgrade.mikrotik.com.conf /etc/apache2/conf.d/
tar xvfz /root/webserver.data.tar.gz --directory /var/www/localhost/htdocs/mikrotikmirror/
rm /root/webserver.data.tar.gz
version=$( cat /root/version.info )
sed -i "s/VERSION/$version/g" /var/www/localhost/htdocs/mikrotikmirror/index-style/header.html
mv /root/mikrotik.sync.repos.sh /opt/mikrotik.upgrade.server/tools/
mv /root/mikrotik.sync.repos.checker.sh /opt/mikrotik.upgrade.server/tools/
mv /root/routeros.raw /opt/mikrotik.upgrade.server/tools/mikrotik.configs/
chmod 0775 /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.sh
chmod 0775 /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.checker.sh
ln -s /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.sh /usr/local/bin
ln -s /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.checker.sh /usr/local/bin
chown -r apache:apache /var/www/localhost/htdocs/
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
rc-update add sshd 
rc-update add apache2
rc-service sshd start
rc-service apache2 start
rc-update add rsyslog
rc-service rsyslog start
rc-update add crond
rc-service crond start
sleep 15
/opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.checker.sh
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