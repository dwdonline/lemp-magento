# lemp-magento
This script will take a fresh Ubuntu 14/15 server and update, then install Nginx, Php5-fpm, Percona (MySQL), and Pagespeed, then set up the server configuration for Magento and WordPress. It will also install Magento and Wordpress (have to run the web installers), setting up their files and MySQL databases.

To use, login to your server and run the following:

cd to the directory you want to put the script in. I usually just go to root:

cd

wget -q https://raw.githubusercontent.com/dwdonline/lemp-magento/master/lemp_magento.sh

chmod 550 lemp_magento.sh

./lemp_magento.sh

