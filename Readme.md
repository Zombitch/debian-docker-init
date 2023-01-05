# Debian with Docker & Ansible 

## Installation steps

In commande line terminal, run :

> sudo bash
chmod a+x ./init.sh
./init.sh

## Ansible scripts

Run following ansible script :

* To run json-server :
> ansible-playbook json-server.yml

* To run mongodb :
> ansible-playbook mongo.yml --extra-vars "user=YOUR_MONGO_USER pwd=YOUR_MONGO_PWD network=YOUR_NETWORK_NAME"
