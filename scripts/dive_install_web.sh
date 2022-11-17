#!/bin/bash

# Provision a VM to be used as the web node for the DIVE service

WEB_INTERNAL_IP=$1
if [ -z "$WEB_INTERNAL_IP" ]
then
  echo "No WEB_INTERNAL_IP was supplied as argument 1"
  exit 1
fi

sudo apt-get update

# Allow TCP Forwarding
sudo sed -i \
  's/AllowTcpForwarding no/#AllowTcpForwarding no\nAllowTcpForwarding yes/1' \
  /etc/ssh/sshd_config

# Prep directory
DIVE_DIR=/opt/noaa
echo "CREATING $DIVE_DIR AND CLONING DIVE"
sudo mkdir $DIVE_DIR
sudo chown $USER $DIVE_DIR
chmod 755 $DIVE_DIR
cd $DIVE_DIR

REPO_URL=https://raw.githubusercontent.com/us-amlr/viame-web-noaa-gcp/main/scripts
curl -L $REPO_URL/dive_startup_web.sh -o $DIVE_DIR/dive_startup_web.sh
chmod 755 $DIVE_DIR/dive_startup_web.sh

git clone https://github.com/kitware/dive
chmod 755 dive

# Create and run ansible scripts
mkdir ansible
cp dive/devops/inventory.local ansible/
echo '- src: geerlingguy.docker' > ansible/requirements.yml
echo '---
- name: Install docker
  hosts: all
  become: yes
  roles:
    - role: geerlingguy.docker
    ' > ansible/playbook.yml

echo "STARTING ANSIBLE RUN"
ansible-galaxy install -r ansible/requirements.yml
ansible-playbook -i ansible/inventory.local ansible/playbook.yml

# https://docs.docker.com/engine/install/linux-postinstall/ 
sudo usermod -aG docker $USER

# must install docker-compose like this to get v1.29; v2 has bugs still
# Note that `docker-compose --version` will not work until running `export TMPDIR=$HOME/tmp`
# The web server still works with v2; this step is just for consistency
sudo rm /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod a+rx /usr/local/bin/docker-compose

# Create env file and add necessary variables
cd dive
cp .env.default .env
chmod 755 .env

echo "Web VM internal IP: $WEB_INTERNAL_IP"
# docker container can't connect via IP for some reason 
# (hardened VM permsissions feature?), so must use local path
echo "CELERY_BROKER_URL=amqp://guest:guest@rabbit/default" >> .env
echo "WORKER_API_URL=http://$WEB_INTERNAL_IP:8010/api/v1" >> .env

echo "END OF SCRIPT"
