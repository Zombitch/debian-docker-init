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