#!/bin/bash 

apt-get install python3-pip python-docker
apt-get update
python3 -m pip install --user ansible
apt-get install ansible
pip3 install docker
ansible-galaxy collection install community.docker