#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <domaine> [email]"
  echo "Exemple: $0 luxanimastudio.com toi@luxanimastudio.com"
  exit 1
fi

DOMAIN="$1"
CERT_NAME="$DOMAIN"

LE_DIR="/var/lib/docker/volumes/nginx_data/_data/letsencrypt"
LE_LIB="/var/lib/docker/volumes/nginx_data/_data/letsencrypt-lib"
WEBROOT="/var/lib/docker/volumes/nginx_data/_data/www/certbot"
NGINX_CONTAINER="${NGINX_CONTAINER:-nginx}"

docker run --rm \
  -v "${LE_DIR}:/etc/letsencrypt" \
  -v "${LE_LIB}:/var/lib/letsencrypt" \
  -v "${WEBROOT}:/etc/nginx/www/certbot" \
  certbot/certbot:latest certonly \
  --webroot -w /etc/nginx/www/certbot \
  --cert-name "${CERT_NAME}" \
  -d "${DOMAIN}" \
  -d "www.${DOMAIN}" \
  --force-renewal \
  --agree-tos \
  --email "ashbay.interactive@gmail.com" \
  --non-interactive \
  --no-eff-email
