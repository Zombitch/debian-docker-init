#!/bin/bash
docker pull certbot/certbot

docker stop nginx

docker run -it --rm \
  -p 80:80 \
  -v "/var/lib/docker/volumes/nginx_data/_data/conf.d:/etc/letsencrypt" \
  certbot/certbot certonly \
  --standalone \
  --preferred-challenges http \
  --agree-tos \
  -m ashbay.interactive@gmail.com \
  -d keeweb.vinais.ovh

docker start nginx

echo "Add the following CRON instruction : 0 1 * * * docker run -it --rm -v "/var/lib/docker/volumes/nginx_data/_data/conf.d:/etc/letsencrypt" certbot/certbot renew"