 echo 'Enter your  IP address.....'
 read -p 'ip: ' ip
 echo 'enter an address for clone eg. htt://.....'
 read -p 'Address: ' address
 url=$address
 project_name="${url##*/}"
 echo $project_name

 server_name="server {
    listen 80;
    server_name $ip; 
    passenger_enabled on; 
    passenger_app_env development; 
    root /var/www/$project_name/public;
 }"

 destdir=/etc/nginx/sites-available/rails.conf

 gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
 \curl -sSL https://get.rvm.io | bash -s stable
 source ~/.rvm/scripts/rvm
 rvm requirements

 rvmsudo /usr/bin/apt-get install build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion

 rvm install 2.3.1
 rvm use 2.3.1 --default
 rvm rubygems current --force
 gem install rails -v 4.2.7 --no-ri --no-rdoc

 gem install passenger
 sudo apt-get install libcurl4-openssl-dev
 sudo dd if=/dev/zero of=/swap bs=1M count=1024

 sudo mkswap /swap
 sudo swapon /swap
 rvmsudo passenger-install-nginx-module


 sudo apt-get install postgresql postgresql-contrib libpq-dev
 sudo su postgres -c psql

 sudo apt-get install nodejs
 sudo apt-get install git
 cd /var
 sudo mkdir www
 cd www
 sudo git clone $address
 sudo chown -R ubuntu $project_name
 cd $project_name
 bundle install
 sudo touch log/development.log

 rake db:create:all
 rake db:migrate

sudo wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O /etc/init.d/nginx
sudo chmod +x /etc/init.d/nginx
cd /etc/init.d
sudo sed -i '21s/.*/# config:      \/etc\/nginx\/conf\/nginx.conf/' nginx
sudo sed -i '22s/.*/# pidfile:     \/etc\/nginx\/logs\/nginx.pid/' nginx
sudo sed -i '87s/.*/NGINXPATH=${NGINXPATH:-\/etc\/nginx}/' nginx

sudo service nginx restart
cd /etc/nginx
sudo mkdir sites-available
sudo mkdir sites-enabled
cd conf
sudo sed -i '83a include \/etc\/nginx\/sites-enabled\/*;' nginx.conf 
cd /etc/nginx/sites-available
sudo touch rails.conf
sudo sh -c "echo '$server_name' >> '$destdir'"
sudo ln -s /etc/nginx/sites-available/rails.conf /etc/nginx/sites-enabled/rails.conf
sudo service nginx restart
sudo service nginx restart




