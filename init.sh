#!/usr/bin/env bash
# Bootstrap a Debian 12/13 host: Docker CE (official repo) + Ansible + collections.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo ./init.sh)" >&2
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y ca-certificates curl ansible python3-docker

# Docker official apt repository (deb822 format)
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# shellcheck source=/dev/null
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
cat > /etc/apt/sources.list.d/docker.sources <<REPO
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
REPO
# Remove the legacy one-line source / keyring from older versions of this script
rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Pinned collections, installed next to the playbooks (see ansible.cfg)
ansible-galaxy collection install -r "${REPO_DIR}/requirements.yml" -p "${REPO_DIR}/collections"

echo "Done. Run playbooks from ${REPO_DIR}, e.g.: ansible-playbook docker-playbooks/nginx.yml"
