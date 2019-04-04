#!/bin/bash
#Script made for PHP Portal installtion
#Author: Vinod.N K
#Usage: Nginx, Mysql, PhP7, Mongodb, Node for portal installation
#Distro : Linux -Centos, Rhel, and any fedora

# Update yum repos.and install development tools
echo "Starting installation of LEAP..."
sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install screen -y

# Epel & Remi-Repo for mysql and php
echo "Installing the Remi Repo..."
wget wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && rpm -ivh epel-release-latest-7.noarch.rpm
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
sudo yum install yum-utils -y
sudo yum-config-manager --enable remi-php70

# Yum update with new repo
sudo yum --enablerepo=remi,remi-php70 update -y && sudo yum --enablerepo=remi,remi-php70 upgrade -y
sudo yum install unzip openssl-devel mlocate zlib-devel pcre* -y

echo "Installing MySQL DB...."
# Install MySQL v5.5
echo "Installing MySQL..."
wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo rpm -ivh mysql-community-release-el7-5.noarch.rpm
sudo yum update -y
sudo yum --enablerepo=remi,remi-php70 install -y mysql-server
echo "Configuring MySQL data-dir..."
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
wget "http://nginx.org/download/nginx-1.13.9.tar.gz"
sudo tar -zxvf nginx-1.13.9.tar.gz
mv nginx-1.13.9 nginx
cd nginx
sudo mkdir /apps/nginx/logs/
sudo /bin/bash configure --sbin-path=/apps/nginx/sbin/nginx --conf-path=/apps/nginx/conf/nginx.conf --error-log-path=/apps/nginx/logs/error.log --http-log-path=/apps/nginx/logs/access.log --pid-path=/apps/nginx/logs/nginx.pid --lock-path=/apps/nginx/logs/nginx.lock --with-http_stub_status_module --with-http_ssl_module --http-client-body-temp-path=/apps/nginx/body --with-http_v2_module

sudo make
sudo make install
useradd -s /bin/false nginx

# configuring Nginx with help of sed
echo "Configuring Nginx Conf..."
sudo sed -i 's/mime.types/apps/nginx/conf/g' /apps/nginx/conf/nginx.conf
sudo sed -i '5 i error_log   /apps/nginx/logs/error.log;' /apps/nginx/conf/nginx.conf
sudo sed -i '26 i access_log   /apps/nginx/logs/access.log;' /apps/nginx/conf/nginx.conf
sudo sed -i 's/index  index.html index.htm;/index index.php  index.html index.htm;/g' /apps/nginx/conf/nginx.conf
sudo wget https://s3-eu-west-1.amazonaws.com/moofwd-devops/scripts/nginx_init
sudo mv nginx_init /etc/init.d/nginx
sudo chmod 755 /etc/init.d/nginx
sudo chkconfig --add nginx
sudo chkconfig --level 345 nginx on

cd ~/

sleep 3

# Install PHP v5.5
echo "Installing PHP v7.0..."

sudo yum -y remove php5*; sleep 1; yum -y remove php6*
sudo yum --enablerepo=remi,remi-php70 install -y php-pecl-memcached php-pecl-ssh2 php-ldap php-pecl-redis php-pspell php-pecl-xdebug php-gmp php-pdo php-odbc php-pdo-dblib php-cli php-pecl-igbinary-devel php-devel php-pecl-oauth php-process php-enchant php-pgsql php-mysqlnd php-dba php-pecl-imagick-devel php-soap php-xml php-common php-bcmath php-mbstring php-json php-pecl-apcu-devel php-fpm php-dbg php-pecl-igbinary php-pecl-memcache php-mcrypt php php-pecl-imagick php-pecl-apcu php-embedded php-intl php-gd php-xmlrpc php-snmp php-tidy php-imap php-recode php-opcache php-common php-pear

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
sudo pecl7 install mongodb
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php.ini
sudo sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sudo sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sudo echo -e “extension=mongodb.so” >>/etc/php.ini
sed -i "s/128M/2048M/g" /etc/php.ini
sudo service php-fpm start

#Mongo Installtion
echo "[mongodb-org-3.6.11]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.6/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.6.asc" >> /etc/yum.repos.d/mongod-org.repo

mkdir /var/lib/mongo/data/db
sed -i "s/bindIp=127.0.0.1/bindIp=0.0.0.0/g" /etc/mongod.conf
sed -i "s/dbPath: \/var\/lib\/mongo/dbPath: \/var\/lib\/mongo\/data\/db/g" /etc/mongod.conf
chown -R mongod:mongod /var/lib/mongo
sudo systemctl restart mongod.service

#mongo  php3 plugin
cd /apps
git clone https://github.com/mongodb/mongo-php-driver.git
cd mongo-php-driver
git submodule update --init
phpize
./configure; sleep 1; make all; sleep 1; make install
php --ri mongodb | grep version


#Let’s Encrypt for SSL Cert.
cd  /apps
wget https://dl.eff.org/certbot-auto
chmod a+x certbot-auto
pip install -U certbot && /apps/nginx/sbin/nginx -s stop
yum install python-virtualenv.noarch -y

read -p "what is the domain name ?" DOMAIN
./certbot-auto certonly --standalone -d $DOMAIN --no-bootstrap
/apps/nginx/sbin/nginx

# Done
