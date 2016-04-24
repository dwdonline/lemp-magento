#!/bin/bash
#### Installation script to setup Ubuntu, Nginx, Percona, Php-fpm
#### By Philip N. Deatherage, Deatherage Web Development
#### www.dwdonline.com

pause(){
 read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

echo "---> WELCOME! FIRST WE NEED TO MAKE SURE THE SYSTEM IS UP TO DATE!"
pause

apt-get update
apt-get -y upgrade

echo "---> NOW, LET'S BUILD THE ESSENTIALS AND INSTALL ZIP/UNZIP"
pause

apt-get update
apt-get -y install build-essential zip unzip

echo "---> ALRIGHT, NOW WE ARE READY TO INSTALL THE GOOD STUFF!"
pause

echo "---> INSTALLING NGINX AND PHP-FPM"

nginx=development

add-apt-repository ppa:nginx/$nginx

apt-get -y update

add-apt-repository -y ppa:ondrej/php5-5.6

apt-get -y update

apt-get -y install php5-fpm php5-mhash php5-mcrypt php5-curl php5-cli php5-mysql php5-gd php5-intl php5-xsl libperl-dev libpcre3 libpcre3-dev libssl-dev php5-gd libgd2-xpm-dev libgeoip-dev libgd2-xpm-dev nginx

echo "---> NOW, LET'S COMPILE NGINX WITH PAGESPEED"
pause

cd
wget -q https://github.com/pagespeed/ngx_pagespeed/archive/master.zip
unzip master.zip
cd ngx_pagespeed-master
wget -q https://dl.google.com/dl/page-speed/psol/1.11.33.0.tar.gz
tar -xzvf 1.11.33.0.tar.gz # expands to psol/
cd
wget -q http://nginx.org/download/nginx-1.9.14.tar.gz
tar -xzvf nginx-1.9.14.tar.gz
cd nginx-1.9.14

./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --with-http_stub_status_module --user=www-data --group=www-data --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_image_filter_module --add-module=$HOME/ngx_pagespeed-master --with-ipv6 --with-http_geoip_module --with-http_realip_module;

make

make install

service nginx restart

echo "---> INSTALLING PERCONA"
pause

echo
read -e -p "---> What do you want your MySQL root password to be?: " -i "password" MYSQL_PASSWORD

apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A

echo "deb http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list

echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list

touch /etc/apt/preferences.d/00percona.pref

echo "Package: *" >> /etc/apt/preferences.d/00percona.pref
echo "Pin: release o=Percona Development Team" >> /etc/apt/preferences.d/00percona.pref
echo "Pin-Priority: 1001" >> /etc/apt/preferences.d/00percona.pref

apt-get -y update

export DEBIAN_FRONTEND=noninteractive
echo "percona-server-server-5.6 percona-server-server/root_password password ${MYSQL_PASSWORD}" | sudo debconf-set-selections
echo "percona-server-server-5.6 percona-server-server/root_password_again password ${MYSQL_PASSWORD}" | sudo debconf-set-selections
apt-get -y install percona-server-server-5.6 percona-server-client-5.6

echo "---> NOW, LET'S SETUP SSL. YOU'LL NEED TO ADD YOUR CERTIFICATE LATER"
pause

echo
read -e -p "---> What will your domain name be (without the www): " -i "domain.com" MY_DOMAIN

cd "/etc/ssl/"

mkdir "sites"

cd "sites"

openssl genrsa -out ${MY_DOMAIN}.key 2048
openssl req -new -key ${MY_DOMAIN}.com.key -out ${MY_DOMAIN}.com.csr

cd

echo "---> OK, WE ARE DONE SETTING UP THE SERVER. LET'S PROCEED TO CONFIGURING THE NGINX HOST FILES FOR MAGENTO AND WORDPRESS"
pause

#### Install nginx configuration
#### IT WILL REMOVE ALL CONFIGURATION FILES THAT HAVE BEEN PREVIOUSLY INSTALLED.

NGINX_EXTRA_CONF="error_page.conf extra_protect.conf export.conf hhvm.conf headers.conf maintenance.conf multishop.conf pagespeed.conf spider.conf"
NGINX_EXTRA_CONF_URL="https://raw.githubusercontent.com/magenx/nginx-config/master/magento/conf.d/"

echo "---> CREATING NGINX CONFIGURATION FILES NOW"
echo

read -e -p "---> Enter your domain name (without www.): " -i "myshop.com" MY_DOMAIN
read -e -p "---> Enter your web root path: " -i "/var/www/html" MY_SHOP_PATH
read -e -p "---> Enter your web user usually www-data (nginx for Centos): " -i "www-data" MY_WEB_USER

wget -qO /etc/nginx/port.conf https://raw.githubusercontent.com/magenx/nginx-config/master/magento/port.conf
wget -qO /etc/nginx/fastcgi_params https://raw.githubusercontent.com/magenx/nginx-config/master/magento/fastcgi_params
wget -qO /etc/nginx/nginx.conf https://raw.githubusercontent.com/magenx/nginx-config/master/magento/nginx.conf

sed -i "s/www/sites-enabled/g" /etc/nginx/nginx.conf

mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/www/default.conf
wget -q https://raw.githubusercontent.com/magenx/nginx-config/master/magento/www/magento.conf

sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/magento.conf
sed -i "s,root /var/www/html,root ${MY_SHOP_PATH},g" /etc/nginx/sites-available/magento.conf
sed -i "s,user  nginx,user  ${MY_WEB_USER},g" /etc/nginx/nginx.conf
sed -i "s,listen = /var/run/php5-fpm.sock,listen = 127.0.0.1:9000,g" /etc/php5/fpm/pool.d/www.conf

ln -s /etc/nginx/sites-available/magento.conf /etc/nginx/sites-enabled/magento.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

cd /etc/nginx/conf.d/
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_EXTRA_CONF_URL}${CONFIG}
done

sed -i "s,pagespeed  FileCachePath,#pagespeed  FileCachePath,g" /etc/nginx/conf.d/pagespeed.conf
sed -i "s,pagespeed  LogDir,#pagespeed  LogDir,g" /etc/nginx/conf.d/pagespeed.conf

sed -i '/http   {/a     ## Pagespeed module\n    pagespeed  FileCachePath  "/var/tmp/";\n    pagespeed  LogDir "/var/log/pagespeed";\n    pagespeed ProcessScriptVariables on;\n' /etc/nginx/nginx.conf

read -p "Would you like to install Adminer for managing your MySQL databases now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then
cd "/var/www/html"
wget -q https://www.adminer.org/static/download/4.2.4/adminer-4.2.4-mysql.php
mv adminer-4.2.4-mysql.php adminer.php
else
  exit 0
fi

read -p "Would you like to install Magento now?<y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "/var/www/html"
rm "index.nginx-debian.html"
wget -q https://www.dwdonline.com/magento-1.9.2.4-2016-02-23-06-04-07.tar.gz
tar -xzvf magento-1.9.2.4-2016-02-23-06-04-07.tar.gz --strip 1

echo
read -e -p "---> What do you want to name your Magento MySQL database?: " -i "magento1924" MYSQL_DATABASE
read -e -p "---> What do you want to name your Magento MySQL user?: " -i "magento1924user" MYSQL_USER
read -e -p "---> What do you want your Magento MySQL password to be?: " -i "Yn3f3nDf" MYSQL_USER_PASSWORD

ip="$(ifconfig | grep -A 1 'eth0' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${MYSQL_DATABASE}; CREATE user '${MYSQL_USER}'@'$ip' IDENTIFIED BY '${MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'$ip' IDENTIFIED BY '${MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${MYSQL_DATABASE}"
echo "Your database user is: ${MYSQL_USER}"
echo "Your databse password is: ${MYSQL_USER_PASSWORD}"

else
  exit 0
fi

read -p "Would you like to install WordPress now? <y/N> " prompt
if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]
then

cd "/var/www/html"

wget -q https://wordpress.org/latest.zip

unzip latest.zip

mv wordpress blog

echo
read -e -p "---> What do you want to name your WordPress MySQL database?: " -i "" WP_MYSQL_DATABASE
read -e -p "---> What do you want to name your WordPress MySQL user?: " -i "" WP_MYSQL_USER
read -e -p "---> What do you want your WordPress MySQL password to be?: " -i "" WP_MYSQL_USER_PASSWORD

echo "Please enter your MySQL root password below:"

mysql -u root -p -e "CREATE database ${MYSQL_DATABASE}; CREATE user '${WP_MYSQL_USER}'@'$ip' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}'; GRANT ALL PRIVILEGES ON ${WP_MYSQL_DATABASE}.* TO '${WP_MYSQL_USER}'@'$ip' IDENTIFIED BY '${WP_MYSQL_USER_PASSWORD}';"

echo "Your database name is: ${WP_MYSQL_DATABASE}"
echo "Your database user is: ${WP_MYSQL_USER}"
echo "Your databse password is: ${WP_MYSQL_USER_PASSWORD}"

else
  exit 0
fi

echo "---> Last thing, let's set the permissions for Magento and WordPresss:"
pause

cd "/var/www/html"

chown -R www-data .

find . -type f -exec chmod 400 {} \;
find . -type d -exec chmod 500 {} \; 
find var/ -type f -exec chmod 600 {} \; 
find media/ -type f -exec chmod 600 {} \;
find var/ -type d -exec chmod 700 {} \; 
find media/ -type d -exec chmod 700 {} \;
chmod 700 includes
chmod 600 includes/config.php

find blog/wp-content/ -type f -exec chmod 600 {} \; 
find blog/wp-content/ -type d -exec chmod 700 {} \;

echo "I just saved you a shitload of time and headache. You're welcome."
