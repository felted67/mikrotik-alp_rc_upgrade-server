#!/bin/bash
mkdir -p /etc/apache2/conf.d
mkdir -p /opt/mikrotik.upgrade.server
mkdir -p /opt/mikrotik.upgrade.server/tools
mkdir -p /opt/mikrotik.upgrade.server/repo
mkdir -p /opt/mikrotik.upgrade.server/repo/routeros/0.0
mkdir -p /opt/mikrotik.upgrade.server/tools/mikrotik.configs
mkdir -p /var/www/localhost/htdocs/mikrotikmirror
ln -s  /opt/mikrotik.upgrade.server/repo /var/www/localhost/htdocs/mikrotikmirror/repo
mv /etc/crontabs/root /etc/crontabs/root.orig
mv /root/crontabs.root.new /etc/crontabs/root
chmod 0600 /etc/crontabs/root
chown root:root /etc/crontabs/root
mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf.orig
mv /etc/apache2/httpd.new.conf /etc/apache2/httpd.conf
mv /etc/apache2/conf.d/mpm.conf /etc/apache2/conf.d/mpm.conf.orig
mv /etc/apache2/conf.d/mpm.new.conf /etc/apache2/conf.d/mpm.conf
mv /root/mikrotikmirror.conf /etc/apache2/conf.d/
mv /root/upgrade.mikrotik.com.conf /etc/apache2/conf.d/
tar xvfz /root/webserver.data.tar.gz --directory /var/www/localhost/htdocs/mikrotikmirror/
rm /root/webserver.data.tar.gz
version=$( cat /root/version.info )
sed -i "s/VERSION/$version/g" /var/www/localhost/htdocs/mikrotikmirror/index-style/header.html
mv /etc/motd /etc/motd.orig
sed -i "s/VERSION/$version/g" /root/motd.new
mv /root/motd.new /etc/motd
mv /root/mikrotik.sync.repos.sh /opt/mikrotik.upgrade.server/tools/
mv /root/mikrotik.sync.repos.checker.sh /opt/mikrotik.upgrade.server/tools/
mv /root/status.gen.sh /usr/local/bin/
mv /root/routeros.raw /opt/mikrotik.upgrade.server/tools/mikrotik.configs/
mv /root/routeros.0.00.conf /opt/mikrotik.upgrade.server/tools/mikrotik.configs/
mv /root/CHANGELOG.0.0 /opt/mikrotik.upgrade.server/repo/routeros/0.0/CHANGELOG
mv /root/mus-documentation.pdf /var/www/localhost/htdocs/mikrotikmirror/doc/
rm /var/www/localhost/htdocs/mikrotikmirror/doc/coming_soon
chmod 0775 /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.sh
chmod 0775 /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.checker.sh
chmod 0775 /usr/local/bin/status.gen.sh
ln -s /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.sh /usr/local/bin/
ln -s /opt/mikrotik.upgrade.server/tools/mikrotik.sync.repos.checker.sh /usr/local/bin/
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
/usr/local/bin/status.gen.sh
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