#!/bin/bash
#Script made for Application installtion
#Author: Vinod.N K
#Usage: Nginx, Java, PhP, OpenSSL, Gcc, Ulimit for portal installation
#Distro : Linux -Centos, Rhel, and any fedora
#Check whether root user is running the script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Update yum repos.and install development tools
echo "Starting installation of Portal..."
sudo yum update -y
sudo yum groupinstall "Development Tools" -y
sudo yum install screen -y

# Installing needed dependencies and setting ulimit
echo "Installing  needed dependencies for Portal..."
sudo yum install  gcc openssl openssl-devel pcre-devel git unzip wget -y
sudo sed -i '61 i *	soft	nofile	99999' /etc/security/limits.conf
sudo sed -i '62 i *	hard	nofile	99999' /etc/security/limits.conf
sudo sed -i '63 i *	soft	noproc	20000' /etc/security/limits.conf
sudo sed -i '64 i *	hard	noproc	20000' /etc/security/limits.conf
echo "fs.file-max=6816768" >> /etc/sysctl.conf
sudo sysctl -w fs.file-max=6816768
sudo sysctl -p

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
#ask user about password
read -p "Please Enter the Password for New User ($username) : " password

#mysql query that will create new user, grant privileges on database with entered password
mysql -uroot -p"$pass" -e "GRANT ALL PRIVILEGES ON dbname.* TO '$username'@'localhost' IDENTIFIED BY '$password'"

echo "Installed MySQL & update new user completed..."

# Installing Java8
cd /apps/
echo "Downloading & Installing  Java8..."
wget https://s3.amazonaws.com/zubron-server-1.0/Java8.zip
sudo unzip Java8.zip
sudo alternatives --install /usr/bin/java java /apps/java8/bin/java 1
sudo alternatives --config java
sudo alternatives --install /usr/bin/jar jar /apps/java8/bin/jar 1
sudo alternatives --install /usr/bin/javac javac /apps/java8/bin/javac 1
sudo alternatives --set jar /apps/java8/bin/jar
sudo alternatives --set javac /apps/java8/bin/javac
sudo /apps/java8/bin/java -version
sudo java –version
echo '#JAVA Path Setting
export JAVA_HOME=/apps/java8
export JRE_HOME=/apps/java8/jre
export PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' > /etc/profile.d/java_path.sh
chmod 755 /etc/profile.d/java_path.sh
source /etc/profile.d/java_path.sh

# Install Nginx v1.9
cd /apps/
echo "Installing Nginx from source..."
wget http://nginx.org/download/nginx-1.9.9.tar.gz
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
sudo sed -i "s/mime.types/apps/nginx/conf/g" /apps/nginx/conf/nginx.conf
sudo sed -i "5 i error_log   /apps/nginx/logs/error.log;" /apps/nginx/conf/nginx.conf
sudo sed -i "26 i access_log   /apps/nginx/logs/access.log;" /apps/nginx/conf/nginx.conf
sudo wget https://s3-eu-west-1.amazonaws.com/moofwd-devops/scripts/nginx_init
sudo mv /apps/nginx_init /etc/init.d/nginx
sudo chmod 755 /etc/init.d/nginx
sudo chkconfig --add nginx
sudo chkconfig --level 345 nginx on

#Cleaning /apps path
sudo rm -rf /apps/nginx-1.9.9.tar.gz
sudo rm -rf /apps/Java8.zip

##Now lets install Our Portal...
echo "Installing Portal & Configuration..."
sudo wget https://weblog.com/application.bin
sudo chmod 755 application.bin
sudo ./application.bin
