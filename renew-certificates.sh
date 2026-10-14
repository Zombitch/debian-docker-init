#!/usr/bin/env bash
# Renew all Let's Encrypt certificates and reload nginx so it serves the new ones.
# Cron example (daily): 5 3 * * * /opt/debian-docker-init/renew-certificates.sh
set -euo pipefail

NGINX_CONTAINER="${NGINX_CONTAINER:-nginx}"
CERTBOT_IMAGE="${CERTBOT_IMAGE:-certbot/certbot:latest}"
NGINX_VOLUME_PATH="${NGINX_VOLUME_PATH:-/var/lib/docker/volumes/nginx_data/_data}"

docker run --rm --pull always \
  -v "${NGINX_VOLUME_PATH}/letsencrypt:/etc/letsencrypt" \
  -v "${NGINX_VOLUME_PATH}/letsencrypt-lib:/var/lib/letsencrypt" \
  -v "${NGINX_VOLUME_PATH}/www/certbot:/etc/nginx/www/certbot" \
  "${CERTBOT_IMAGE}" renew --no-random-sleep-on-renew --quiet

# nginx keeps certificates in memory: without a reload, renewed certs are never served.
docker exec "${NGINX_CONTAINER}" nginx -t
docker exec "${NGINX_CONTAINER}" nginx -s reload
