nginx_path=/etc/nginx/sites-available/$app_dir
gunicorn_path=/etc/systemd/system/gunicorn.service

gunicorn="
[Unit]
Description=gunicorn daemon
After=network.target
[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/home/ubuntu/$project_dir
ExecStart=/home/ubuntu/$project_dir/venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/$project_dir/$app_dir.sock $app_dir.wsgi:application
[Install]
WantedBy=multi-user.target
"

server_name="server {
  listen 80;
  server_name $ip_addr;
  location = /favicon.ico { access_log off; log_not_found off; }
  location /static/ {
	root /home/ubuntu/$project_dir;
  }
  location / {
	include proxy_params;
	proxy_pass http://unix:/home/ubuntu/$project_dir/$app_dir.sock;
  }
}"

#installing packages
sudo apt-get update
yes Y | sudo apt-get install python-pip python-dev nginx git
sudo apt-get update
sudo pip install virtualenv

#downloading projects
git clone $url
cd $project_dir
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
pip install django bcrypt django-extensions
pip install gunicorn

cd $app_dir

sudo sed -i '26s/.*/DEBUG = False/' settings.py
sudo sed -i '28s/.*/ALLOWED_HOSTS = ["'$ip_addr'"]/' settings.py
sudo sed -i '120s/.*/STATIC_ROOT = os.path.join(BASE_DIR, "static\/")/' settings.py

cd ..
yes yes | python manage.py collectstatic
# gunicorn --bind 0.0.0.0:8000 $app_dir.wsgi:application
deactivate

#setup gunicorn --- working ---
sudo sh -c "echo '$gunicorn' >> '$gunicorn_path'"

sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

sudo sh -c "echo '$server_name' >> '$nginx_path'"

sudo ln -s /etc/nginx/sites-available/$app_dir /etc/nginx/sites-enabled
sudo nginx -t
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx restart
