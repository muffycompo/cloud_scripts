#!/bin/sh
#
# CentOS 7 LEMP Stack Setup
#
# This script will install and configure Nginx,PHP7.2, MySQL 5.7 on
# a CentOS 7 droplet
#
# Disable SELinux
setenforce 0
# Update CentOS
yum -y update;

# Setup EPEL Repos
yum -y install epel-release unzip nano yum-utils;

# Setup REMI Repos
yum -y localinstall http://rpms.remirepo.net/enterprise/remi-release-7.rpm;

# Setup MySQL Community Repos
yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm;

# Enable REMI Repo for PHP 7.2
yum-config-manager --enable remi-php72;

# Install packages
yum -y install nginx mysql-community-server php72-php php72-php-fpm php72-php-gd php72-php-json php72-php-mbstring php72-php-mysqlnd php72-php-xml php72-php-xmlrpc php72-php-opcache git

# Enable services
systemctl enable mysqld.service;
systemctl enable nginx.service;
systemctl enable php72-php-fpm.service;
systemctl disable httpd.service;

# Start services
systemctl start mysqld.service;
systemctl stop httpd.service;
systemctl start nginx.service;
systemctl start php72-php-fpm.service;

# Lower Password Validation
echo "validate_password_policy=LOW" >> /etc/my.cnf
echo "validate_password_length=4" >> /etc/my.cnf

# Restart MySQL Server 
systemctl restart mysqld.service;

# Obtain MySQL root password
MYSQL_ROOT_PASSWORD=$(grep 'A temporary password is generated for root@localhost' /var/log/mysqld.log | tail -1 | awk 'BEGIN{FS=" "} {print $11}')

# Write MySQL Root Password to home directory
echo "MySQL Root Password: "$MYSQL_ROOT_PASSWORD >> /root/mysql_root_password.txt

# Add nginx user to php-fpm
sed -i "s/user = apache/user = nginx/g" /etc/opt/remi/php72/php-fpm.d/www.conf
sed -i "s/group = apache/group = nginx/g" /etc/opt/remi/php72/php-fpm.d/www.conf
sed -i "s/;listen.owner = nobody/listen.owner = nginx/g" /etc/opt/remi/php72/php-fpm.d/www.conf
sed -i "s/;listen.group = nobody/listen.owner = nginx/g" /etc/opt/remi/php72/php-fpm.d/www.conf
sed -i "s/listen = 127.0.0.1:9000/listen = \/run\/php\/php7.2-fpm.sock/g" /etc/opt/remi/php72/php-fpm.d/www.conf

# Restart PHP-FPM
mkdir -p /run/php/
chown -R nginx.nginx /run/php/
systemctl restart php72-php-fpm.service;

# Droplet Public IP Address
PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)

# Enable PHP Support
cat << EOF > /etc/nginx/conf.d/default.conf
server {
    listen $PUBLIC_IP:80;
    #server_name maomuffy.com;
    root /usr/share/nginx/laravel_app/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    index index.php index.html index.htm;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Restart Nginx Server
systemctl restart nginx.service;

# Setup PHP PATH
`echo "export PATH=\$PATH:/opt/remi/php72/root/bin" >> ~/.bashrc`
`export PATH=$PATH:/opt/remi/php72/root/bin`
.  ~/.bashrc

# Install Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
php -r "unlink('composer-setup.php');"

# Install Laravel
composer create-project --prefer-dist laravel/laravel /usr/share/nginx/laravel_app

chmod -R 777 /usr/share/nginx/laravel_app/storage

# Laravel Installation Complete
echo
echo "Server Provisioned Successfully at http://$PUBLIC_IP"
echo "Now go make an AWESOME Laravel Application!"
