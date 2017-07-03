server_name="server {
    listen 80;
    location / {
        proxy_pass http://$ip_addr:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}"
destdir=/etc/nginx/sites-available/$project_dir

sudo apt-get update
sudo apt-get install -y build-essential openssl libssl-dev pkg-config
sudo apt-get install -y nodejs nodejs-legacy
sudo apt-get install npm
sudo npm cache clean -f
sudo npm install -g n
sudo n latest
sudo apt-get install nginx
sudo apt-get install git
sudo apt-get update
cd /var/www
sudo git clone $url

cd /etc/nginx/sites-available/
sudo rm default
sudo touch $project_dir
sudo sh -c "echo '$server_name' >> '$destdir'"
sudo ln -s /etc/nginx/sites-available/$project_dir /etc/nginx/sites-enabled/$project_dir
cd ../sites-enabled/
sudo rm default
sudo npm install pm2 -g
sudo service nginx restart
cd /var/www/$project_dir/
sudo npm install
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ub... xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/source$
sudo apt-get update
sudo apt-get install -y mongodb
sudo killall mongod
cd /
sudo mkdir data
sudo mkdir data/db
cd -
sudo npm install
sudo chown -R ubuntu /data/db
pm2 start mongod
pm2 start server.js
