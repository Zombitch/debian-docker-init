# Debian with Docker & Ansible

Bootstrap a Debian 12/13 host with Docker and deploy self-hosted services behind an nginx reverse proxy (TLS via Let's Encrypt, protected by fail2ban).

## Installation

```bash
sudo ./init.sh
```

This installs Docker CE (official repo), Ansible, `python3-docker`, and the pinned collections from `requirements.yml` into `./collections`.

Run every playbook **from the repository root** so `ansible.cfg`, `inventory.ini` and `group_vars/all.yml` are picked up.

## Configuration

Shared defaults live in `group_vars/all.yml`: docker network (`dmz_network`), timezone, data directory, **pinned image versions**, and `bind_address`.

* Internal services (MongoDB, json-server, eva) publish their port on `127.0.0.1` only. Docker bypasses ufw/nftables for published ports, so never publish to `0.0.0.0` unless you intend to. Expose services through nginx instead (they share the docker network).
* Passwords are prompted for (hidden) when not supplied; they are never echoed and the tasks that carry them use `no_log`. You can also pass them with `-e` or an `ansible-vault` file.

## Playbooks

| Playbook | Purpose | Reverse-proxy target (`docker_host`) |
|---|---|---|
| `nginx.yml` | nginx + ACME/redirect on port 80 + fail2ban + logrotate | – |
| `nginx-add-host.yml` | HTTPS vhost for a domain (validated, rolled back on error) | – |
| `keeweb.yml` | KeeWeb | `keeweb_host:80` |
| `code-server.yml` | VS Code in the browser | `codeserver_host:8443` |
| `neko.yml` | Neko virtual browser (web UI via nginx, WebRTC UDP 52000-52100 published) | `neko_host:8080` |
| `mongodb.yml` | MongoDB | – (`mongodb:27017` on the network) |
| `json-server.yml` | Mock REST API from `/data/db_mock.json` | `json_server_host:80` |
| `eva.yml` | eva (Angular dev server) | `eva_host:4200` |

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
   ansible-playbook docker-playbooks/nginx-add-host.yml -e domain=app.example.com -e docker_host=keeweb_host:80
   ```

4. Renewal — certificates must be renewed **and nginx reloaded** (nginx keeps certificates in memory). Add to cron:

   ```cron
   5 3 * * * /opt/debian-docker-init/renew-certificates.sh
   ```

Certificates are stored in `<nginx_data volume>/letsencrypt`; vhosts load them from `/etc/nginx/letsencrypt/live/<domain>/`.

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
R: `mongdb.yml` is now `mongodb.yml`; `request-new-certificat.sh` is now `request-new-certificate.sh` (email via `CERTBOT_EMAIL`, no more `--force-renewal`); `certbot-init-ssl-cert.sh` was removed (it used a different certificate directory than the rest); the manual certbot.conf step is now done by `nginx.yml`. Existing vhosts must be regenerated with `nginx-add-host.yml` (certificate path moved to `/etc/nginx/letsencrypt/live/...`). The orphan `keeweb_data` volume can be removed.
