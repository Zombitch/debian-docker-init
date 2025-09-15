#!/bin/bash 

apt-get install python3-pip python-docker
apt-get update
python3 -m pip install --user ansible
apt-get install ansible
pip3 install docker
ansible-galaxy collection install community.docker
install -m 0755 -d /etc/apt/keyrings

apt-get install -y ca-certificates curl gnupg lsb-release

# Download Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

# Add repository (auto-detects codename: bookworm or trixie)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
