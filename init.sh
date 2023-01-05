#!/bin/bash 

apt-get install python3-pip
apt-get update
python3 -m pip install --user ansible
apt-get install ansible
pip3 install docker