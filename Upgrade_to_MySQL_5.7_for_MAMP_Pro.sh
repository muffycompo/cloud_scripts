#!/bin/bash

wget http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.22-macos10.13-x86_64.tar.gz
tar xfvz mysql-5.7.22-macos10.13-x86_64.tar.gz

echo "Stopping MAMP"
sudo /Applications/MAMP/bin/stop.sh
sudo killall httpd mysqld

echo "Copy Bin"
sudo rsync -arv --progress mysql-5.7.*/bin/* /Applications/MAMP/Library/bin/ --exclude=mysqld_multi --exclude=mysqld_safe 

echo "Copy Share"
sudo rsync -arv --progress mysql-5.7.*/share/* /Applications/MAMP/Library/share/

echo "Building MySQL 5.7 Folder"
# sudo cp -r /Applications/MAMP/db/mysql56 /Applications/MAMP/db/mysql57 # MAMP Only
sudo cp -r /Library/Application\ Support/appsolute/MAMP\ PRO/db/mysql56 /Applications/MAMP/db/mysql57 # MAMP Pro
sudo rm -fr /Applications/MAMP/db/mysql57/mysql/innodb_*
sudo rm -fr /Applications/MAMP/db/mysql57/mysql/slave_*
sudo chmod -R o+rw  /Applications/MAMP/db/mysql57/
sudo chmod -R o+rw /Applications/MAMP/tmp/mysql/
sed -i.bak 's/mysql56/mysql57/g' /Applications/MAMP/Library/bin/mysqld_safe

echo "Fixing Access (workaround)"
sudo chmod -R o+rw  /Applications/MAMP/tmp/mysql/

echo "Starting MySQL"
sudo /Applications/MAMP/Library/bin/mysqld_safe --port=3306 --socket=/Applications/MAMP/tmp/mysql/mysql.sock --pid-file=/Applications/MAMP/tmp/mysql/mysql.pid --log-error=/Applications/MAMP/logs/mysql_error_log

echo "Migrate, finaly, to new version"
sudo /Applications/MAMP/Library/bin/mysql_upgrade --user=root --password=root --port=3306 --socket=/Applications/MAMP/tmp/mysql/mysql.sock --force