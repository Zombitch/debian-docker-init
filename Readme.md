# Debian with Docker & Ansible 

## Installation steps

In command line terminal, run :

> sudo bash

> chmod a+x ./init.sh

> ./init.sh

## Ansible scripts

Run following ansible script :

* To run json-server :
> ansible-playbook json-server.yml

* To run mongodb :
> ansible-playbook mongo.yml --extra-vars "user=YOUR_MONGO_USER pwd=YOUR_MONGO_PWD network=YOUR_NETWORK_NAME"

* To run Neko (m1k1o virtual browser) :
> ansible-playbook neko.yml --extra-vars "pwd=YOUR_NEKO_PWD admin_pwd=YOUR_NEKO_ADMIN_PWD network=YOUR_NETWORK_NAME"

## SSL Certificate

Generate a new certificat : 

> request-new-certificat.sh mydomain.com

Create a new www director for certbot in nginx : 

> mkdir -p /var/lib/docker/volumes/nginx_data/_data/www/certbot/.well-known/acme-challenge

Add a certbot.conf in nginx conf.d/ folder : 

  server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Certbot/ACME challenge for any domain
    location /.well-known/acme-challenge/ {
        root /etc/nginx/www/certbot;
        allow all;
    }

    # Everything else can go wherever you want
    location / {
        return 301 https://$host$request_uri;
    }
    }

Add the following command to a CRON task :

> 5 3 * * * docker run --rm -v "/var/lib/docker/volumes/nginx_data/_data/letsencrypt:/etc/letsencrypt" -v "/var/lib/docker/volumes/nginx_data/_data/letsencrypt-lib:/var/lib/letsencrypt" -v "/var/lib/docker/volumes/nginx_data/_data/www/certbot:/etc/nginx/www/certbot" certbot/certbot:latest renew --no-random-sleep-on-renew --quiet

## FAQ

Q: Getting error when accessing Code Editor : "websockets closed with close code 1006"
R : Use the following nginx conf :
location / {
        proxy_pass http://codeserver_host:8443/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
