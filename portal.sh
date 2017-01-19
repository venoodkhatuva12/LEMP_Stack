#!/bin/bash
#Script made for Portal LEMP installtion
#Author: Vinod.N K
#Usage: Nginx, Mysql, PhP for portal installation
#Distro : Linux -Centos, Rhel, and any fedora

# Update yum repos.and install development tools
echo "Starting installation of LEAP..."
sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install screen -y

# Remi-Repo for mysql and php
echo "Installing the Remi Repo..."
wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm && rpm -Uvh epel-release-latest-6.noarch.rpm
sudo sed -i 's/enabled=0/enabled=1/g' /etc/yum.repos.d/remi.repo
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
# Yum update with new repo
sudo yum update -y
echo "Installing mysql with database...."


# Install MySQL v5
echo "Installing MySQL..."
sudo yum install -y mysql mysql-server
echo "Configuring MySQL data-dir..."
sudo sed -i /datadir/d /etc/my.cnf
sudo sed -i '4 i datadir=/var/lib/mysql' /etc/my.cnf
sudo /etc/init.d/mysqld restart
# password for root user of mysql
read -p "Please Enter the Password for New User root : " pass
sudo /usr/bin/mysqladmin -u root password "$pass"

sleep 2
#ask user about username
read -p "Please enter the username you wish to create : " username
#ask user about allowed hostname
read -p "Please Enter Host To Allow Access Eg: %,ip or hostname : " host
#ask user about password
read -p "Please Enter the Password for New User ($username) : " password

#mysql query that will create new user, grant privileges on database with entered password
mysql -uroot -p"$pass" -e "GRANT ALL PRIVILEGES ON dbname.* TO '$username'@'$host' IDENTIFIED BY '$password'"

echo "Installed MySQL & update new user completed..."

sleep 5

sudo mkdir /apps/

# Install Nginx v1.9
cd /apps/
echo "Installing Nginx from source..."
wget "http://nginx.org/download/nginx-1.9.9.tar.gz"
sudo tar -zxvf nginx-1.9.9.tar.gz
mv nginx-1.9.9 nginx
cd nginx
sudo mkdir /apps/nginx/logs/
sudo /bin/bash configure --prefix=/apps/nginx --sbin-path=/apps/nginx/sbin/nginx --conf-path=/apps/nginx/conf/nginx.conf --pid-path=/apps/nginx/logs/nginx.pid --lock-path=/apps/nginx/logs/nginx.lock --with-http_stub_status_module --error-log-path=/apps/nginx/logs/error.log --http-log-path=/apps/nginx/logs/access.log --with-http_ssl_module --http-client-body-temp-path=/apps/nginx/body
sudo make
sudo make install
useradd -r nginx

# configuring Nginx with help of sed
echo "Configuring Nginx Conf..."
sudo sed -i 's/mime.types/apps/nginx/conf/g' /apps/nginx/conf/nginx.conf
sudo sed -i '5 i error_log   /apps/nginx/logs/error.log' /apps/nginx/conf/nginx.conf
sudo sed -i '26 i access_log   /apps/nginx/logs/access.log' /apps/nginx/conf/nginx.conf
sudo sed -i 's/index  index.html index.htm;/index index.php  index.html index.htm;/g' /apps/nginx/conf/nginx.conf
sudo wget https://s3-eu-west-1.amazonaws.com/moofwd-devops/scripts/nginx_init
sudo mv nginx_init /etc/init.d/nginx
sudo chmod 755 /etc/init.d/nginx
sudo chkconfig --add nginx
sudo chkconfig --level 345 nginx on

cd ~/

sleep 3

# Install PHP v5.4
echo "Installing PHP v5.4..."
sudo yum --enablerepo=remi install -y php-fpm php-mysql php-cli php-mcrypt php-gd php-mssql php-pgsql php-mbstring php-xm
sleep 3

# Install Composer
echo "Installing Composer for env..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sleep 3

# Install git
echo "Installing git for developer"
sudo yum install -y git
sleep 3

# Install NodeJS v0.10.26for environment
echo "Installing Nodejs v0.10.26..."
cd /usr/src
wget http://nodejs.org/dist/v0.10.26/node-v0.10.26.tar.gz
tar zxf node-v0.10.26.tar.gz
cd node-v0.10.26
sudo ./configure
sudo make
sudo make install
cd ~/
sleep 3

# Restarting Services
echo "Restarting Services all services..."
sudo service mysqld restart
sudo service nginx restart

# Set Up startup when ever rebooted the system we can put in rc.local also but i did it simple
echo "Setting start service.."
sudo chkconfig --levels 235 mysqld on

# Configure PHP
echo "Configuring PHP..."
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sudo sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf

#Installing Unzip
yum install unzip

#Now lets install Our Portal...
echo "Installing Portal & Configuration..."
cd /apps/
git clone http://@git.domain.com/domain_portal.git
cd domain_portal
sudo chmod -R 777 apps public
sudo  /usr/local/bin/composer update
sudo  /usr/local/bin/composer dump-autoload

# Done
echo "Done installation of Int_portal thanx from VinD1!
