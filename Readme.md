# Debian with Docker & Ansible

Bootstrap a Debian 12/13 host with Docker and deploy self-hosted services behind an nginx reverse proxy (TLS via Let's Encrypt, protected by fail2ban).

## Installation

```bash
sudo ./init.sh
```

This installs Docker CE (official repo), Ansible, `python3-docker`, and the pinned collections from `requirements.yml` into `./collections`.

Run every playbook **from the repository root** so `ansible.cfg`, `inventory.ini` and `group_vars/all.yml` are picked up.

## Configuration

Shared defaults live in `group_vars/all.yml`: docker network (`dmz_network`), timezone, data directory, image references, and `bind_address`.

* Internal services (MongoDB, json-server) publish their port on `127.0.0.1` only. Docker bypasses ufw/nftables for published ports, so never publish to `0.0.0.0` unless you intend to. Expose services through nginx instead (they share the docker network).
* Passwords are prompted for (hidden) when not supplied; they are never echoed and the tasks that carry them use `no_log`. You can also pass them with `-e` or an `ansible-vault` file.

## Playbooks

| Playbook | Purpose | Reverse-proxy target (`docker_host`) |
|---|---|---|
| `nginx.yml` | nginx + ACME/redirect on port 80 + fail2ban + logrotate | – |
| `nginx-add-host.yml` | HTTPS vhost for a domain (validated, rolled back on error) | – |
| `code-server.yml` | VS Code in the browser | `codeserver_host:8443` |
| `neko.yml` | Neko virtual browser (web UI via nginx, WebRTC UDP 52000-52100 published) | `neko_host:8080` |
| `mongodb.yml` | MongoDB | – (`mongodb:27017` on the network) |
| `json-server.yml` | Mock REST API from `/data/db_mock.json` | `json_server_host:80` |

```bash
ansible-playbook docker-playbooks/nginx.yml
ansible-playbook docker-playbooks/mongodb.yml
ansible-playbook docker-playbooks/neko.yml
```

## HTTPS for a new domain

1. Deploy nginx once (`nginx.yml`). It serves the ACME challenge on port 80 and redirects everything else to HTTPS.
2. Request the certificate (add `--www` to include `www.<domain>`):

   ```bash
   CERTBOT_EMAIL=you@example.com ./request-new-certificate.sh app.example.com
   ```

3. Create the vhost:

   ```bash
   ansible-playbook docker-playbooks/nginx-add-host.yml -e domain=app.example.com -e docker_host=codeserver_host:8443
   ```

4. Renewal — certificates must be renewed **and nginx reloaded** (nginx keeps certificates in memory). Add to cron:

   ```cron
   5 3 * * * /opt/debian-docker-init/renew-certificates.sh
   ```

Certificates are stored in `<nginx_data volume>/letsencrypt`; vhosts load them from `/etc/nginx/letsencrypt/live/<domain>/`.

## Updates (always latest)

Every service image follows `:latest` (Node-based ones use `node:lts-alpine`: the newest Node is a non-LTS release). **Re-running a playbook is the update**: it pulls the newest image, recreates the container only if the image or its config changed, waits until it is running and healthy (`docker-playbooks/includes/deploy_container.yml`) and, if it is not, restarts the previous image and fails the run. Nothing updates by itself; run the playbooks (or a cron job) when you want to update.

* `code-server` is built locally: the base image is always pulled and the apt/npm/Angular CLI layers are refreshed once per day (`CACHEBUST`).
* `-e prune_old_images=true` removes dangling images afterwards (host-wide, not just these services).
* To freeze one service, replace `:latest` by a version tag in `group_vars/all.yml`.
* **MongoDB:** data files cannot be downgraded and a new major release may need manual steps (feature compatibility version). A failed start is rolled back, but take a `mongodump` before updating.
* Docker Hub limits anonymous pulls (100 per 6 h per IP). Every run pulls once per image, so `docker login` on busy hosts.
* Not covered by the image tag: the json-server npm package (kept on 0.17, 1.x changed the API) and the nvm installer version.

## Security notes

* fail2ban jails (`nginx-http-auth`, `nginx-limit-req`, `nginx-botsearch`, `nginx-noscript`) ban via nftables on the `forward` hook (needed for Docker traffic), IPv4 and IPv6, with incremental ban times. Set `fail2ban_ignoreip` in `nginx.yml` to your admin IP.
* Only the nginx playbook publishes ports 80/443 publicly.

## Linting

CI runs `yamllint`, `ansible-lint` and `shellcheck` (`.github/workflows/lint.yml`). Locally:

```bash
pip install ansible-core ansible-lint yamllint
yamllint . && ansible-lint docker-playbooks && shellcheck *.sh
```

## FAQ

Q: "websockets closed with close code 1006" when accessing the code editor.
R: Use `nginx-add-host.yml`: the generated vhost already forwards the `Upgrade`/`Connection` headers.

Q: Upgrading from the previous version of these playbooks?
R: `mongdb.yml` is now `mongodb.yml`; `request-new-certificat.sh` is now `request-new-certificate.sh` (email via `CERTBOT_EMAIL`, no more `--force-renewal`); `certbot-init-ssl-cert.sh` was removed (it used a different certificate directory than the rest); the manual certbot.conf step is now done by `nginx.yml`. Existing vhosts must be regenerated with `nginx-add-host.yml` (certificate path moved to `/etc/nginx/letsencrypt/live/...`). `keeweb.yml` and `eva.yml` were removed: delete their containers (`docker rm -f keeweb eva`), images and the orphan `keeweb_data` volume by hand if they are still on the host.

Also: Neko's web UI is no longer published on host port 8080 (use nginx, `docker_host=neko_host:8080`). json-server now reads `/data/json-server/db.json` (move your old `/data/db_mock.json` there). Playbooks need root: run as root, or add `-K` to ask for the sudo password. The certificate scripts default to the volume path `/var/lib/docker/volumes/nginx_data/_data` (override with `NGINX_VOLUME_PATH`, `NGINX_CONTAINER`, `CERTBOT_IMAGE`).
