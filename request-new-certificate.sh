#!/usr/bin/env bash
# Issue (or extend) a Let's Encrypt certificate through nginx's ACME webroot.
# Usage: CERTBOT_EMAIL=you@example.com ./request-new-certificate.sh example.com [--www]
set -euo pipefail

DOMAIN="${1:-}"
if [[ -z "${DOMAIN}" ]]; then
  echo "Usage: CERTBOT_EMAIL=you@example.com $0 <domain> [--www]" >&2
  exit 1
fi
: "${CERTBOT_EMAIL:?Set CERTBOT_EMAIL to the contact address for Lets Encrypt}"

NGINX_CONTAINER="${NGINX_CONTAINER:-nginx}"
CERTBOT_IMAGE="${CERTBOT_IMAGE:-certbot/certbot:v5.8.0}"
NGINX_VOLUME_PATH="${NGINX_VOLUME_PATH:-/var/lib/docker/volumes/nginx_data/_data}"

LE_DIR="${NGINX_VOLUME_PATH}/letsencrypt"
LE_LIB="${NGINX_VOLUME_PATH}/letsencrypt-lib"
WEBROOT="${NGINX_VOLUME_PATH}/www/certbot"

DOMAINS=(-d "${DOMAIN}")
[[ "${2:-}" == "--www" ]] && DOMAINS+=(-d "www.${DOMAIN}")

mkdir -p "${LE_DIR}" "${LE_LIB}" "${WEBROOT}/.well-known/acme-challenge"

docker run --rm \
  -v "${LE_DIR}:/etc/letsencrypt" \
  -v "${LE_LIB}:/var/lib/letsencrypt" \
  -v "${WEBROOT}:/etc/nginx/www/certbot" \
  "${CERTBOT_IMAGE}" certonly \
  --webroot -w /etc/nginx/www/certbot \
  --cert-name "${DOMAIN}" \
  "${DOMAINS[@]}" \
  --keep-until-expiring \
  --expand \
  --agree-tos \
  --email "${CERTBOT_EMAIL}" \
  --non-interactive \
  --no-eff-email

docker exec "${NGINX_CONTAINER}" nginx -t
docker exec "${NGINX_CONTAINER}" nginx -s reload
