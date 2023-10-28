# Debian with Docker & Ansible 

## Installation steps

In command line terminal, run :

> sudo bash

>chmod a+x ./init.sh

>./init.sh

## Ansible scripts

Run following ansible script :

* To run json-server :
> ansible-playbook json-server.yml

* To run mongodb :
> ansible-playbook mongo.yml --extra-vars "user=YOUR_MONGO_USER pwd=YOUR_MONGO_PWD network=YOUR_NETWORK_NAME"

## SSL Certificate

Add the following command to a CRON task :

> 0 1 * * * docker run -it --rm -v "/var/lib/docker/volumes/nginx_data/_data/conf.d:/etc/letsencrypt" certbot/certbot renew

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