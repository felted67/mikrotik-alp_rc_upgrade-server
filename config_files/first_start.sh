#!/bin/ash
mv /etc/apache2/httpd.conf /etc/apache2/httpd.conf.orig
mv /etc/apache2/httpd.new.conf /etc/apache2/httpd.conf
mv /root/index.html /var/www/localhost/htdocs/
chown apache:apache /var/www/localhost/htdocs/index.html
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
/sbin/php_configure.sh
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