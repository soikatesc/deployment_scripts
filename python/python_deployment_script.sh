 echo 'Enter your  IP address.....'
 read -p 'ip: ' ip
 echo 'enter an address for clone eg. htt://.....'
 read -p 'Address: ' address
 url=$address
 repo_name="${url##*/}"
 echo $repo_name
 read -p 'Project Name: ' project_name

 nginx_path=/etc/nginx/sites-available/$project_name
 gunicorn_path=/etc/systemd/system/gunicorn.service

gunicorn="
[Unit]
Description=gunicorn daemon
After=network.target
[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/$repo_name
ExecStart=/home/ubuntu/$repo_name/venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/$repo_name/$project_name.sock $project_name.wsgi:application
[Install]
WantedBy=multi-user.target
"

server_name="server {
  listen 80;
  server_name $ip;
  location = /favicon.ico { access_log off; log_not_found off; }
  location /static/ {
      root /home/ubuntu/$repo_name;
  }
  location / {
      include proxy_params;
      proxy_pass http://unix:/home/ubuntu/$repo_name/$project_name.sock;
  }
}"

#installing packages
sudo apt-get update
yes Y | sudo apt-get install python-pip python-dev nginx git
sudo apt-get update
sudo pip install virtualenv

#downloading projects
git clone $address
cd $repo_name
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt 
pip install django bcrypt django-extensions
pip install gunicorn

cd $project_name

sudo sed -i '26s/.*/DEBUG = False/' settings.py
sudo sed -i '28s/.*/ALLOWED_HOSTS = ["'$ip'"]/' settings.py
sudo sed -i '120s/.*/STATIC_ROOT = os.path.join(BASE_DIR, "static\/")/' settings.py


cd ..
yes yes | python manage.py collectstatic
# gunicorn --bind 0.0.0.0:8000 $project_name.wsgi:application
deactivate

#Setup gunicorn --- working--
sudo sh -c "echo '$gunicorn' >> '$gunicorn_path'"

sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

sudo sh -c "echo '$server_name' >> '$nginx_path'"

sudo ln -s /etc/nginx/sites-available/$project_name /etc/nginx/sites-enabled
sudo nginx -t
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx restart
