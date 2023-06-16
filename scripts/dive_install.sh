#!/bin/bash
#
# dive_install.sh [w]
#
# Provision a NMFS-hardened VM, that has a GPU, to run either 
# a full DIVE server or a dedicated task runner.
# The VM must be restarted for some of these changes to take effect
#
# -w flag: 
# User-specified; internal IP address of the web node.
# If provided, lines for CELERY_BROKER_URL and WORKER_API_URL
# will be written to the dive/.env file

# Process options
while getopts ":w:" option
do
    case "$option" in
    "w")
      echo "-w was triggered, WEB_INTERNAL_IP: $OPTARG"
      WEB_INTERNAL_IP=$OPTARG
      ;;
    "?")
      echo "Invalid option: -$OPTARG"
      exit 1
      ;;
  esac
done

# Default no for PAM override message from nvidia driver installation
# https://askubuntu.com/questions/594573
echo "libpam-runtime libpam-runtime/override boolean false" | sudo debconf-set-selections

# Update VM
sudo apt-get update

# If full deployment, allow TCP forwarding
if [ -z "$WEB_INTERNAL_IP" ]
then
  sudo sed -i \
    's/AllowTcpForwarding no/#AllowTcpForwarding no\nAllowTcpForwarding yes/1' \
    /etc/ssh/sshd_config
fi

# Install latest nvidia driver. Reply 'no' to PAM overwrite prompt
# https://cloud.google.com/compute/docs/gpus/install-drivers-gpu#secure-boot
NVIDIA_DRIVER_VERSION=$(sudo apt-cache search 'linux-modules-nvidia-[0-9]+-gcp$' | awk '{print $1}' | sort | tail -n 1 | head -n 1 | awk -F"-" '{print $4}')
# NVIDIA_DRIVER_VERSION=470
echo -e "\nINSTALLING NVIDIA $NVIDIA_DRIVER_VERSION DRIVER\n"
sudo apt-get -y install linux-modules-nvidia-${NVIDIA_DRIVER_VERSION}-gcp nvidia-driver-${NVIDIA_DRIVER_VERSION}

# Prep directory
DIVE_DIR=/opt/noaa
echo "CREATING $DIVE_DIR AND CLONING DIVE"
sudo mkdir $DIVE_DIR
sudo chown $USER $DIVE_DIR
chmod 755 $DIVE_DIR
cd $DIVE_DIR

# Get startup script
REPO_URL=https://raw.githubusercontent.com/us-amlr/viame-web-noaa-gcp/main/scripts
if [ -z "$WEB_INTERNAL_IP" ]
then
  STARTUP_NAME=dive_startup_full.sh
else
  STARTUP_NAME=dive_startup_worker.sh
fi
curl -L $REPO_URL/$STARTUP_NAME -o $DIVE_DIR/$STARTUP_NAME
chmod 755 $DIVE_DIR/$STARTUP_NAME

# Clone dive
git clone https://github.com/kitware/dive
chmod -R 755 dive
cd dive

# Edit ansible files so they do not attempt to install nvidia drivers
sed -i 's/- src: nvidia.nvidia_driver/ /g' devops/ansible/requirements.yml
sed -i 's/- role: nvidia.nvidia_driver/ /g' devops/ansible/playbook.yml

# Run playbook 
echo "STARTING ANSIBLE RUN"
ansible-galaxy install -r devops/ansible/requirements.yml
ansible-playbook -i devops/inventory.local devops/ansible/playbook.yml \
  --extra-vars "run_server=yes"

# https://docs.docker.com/engine/install/linux-postinstall/ 
sudo usermod -aG docker $USER

# must install docker-compose like this to get v1.29; v2 has bugs still
# Note that `docker-compose --version` will not work until running `export TMPDIR=$HOME/tmp`
sudo rm /usr/local/bin/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod a+rx /usr/local/bin/docker-compose

# Create env file. 
# No edits if only using one VM. If -w (worker) flag, then update the env file
cp .env.default .env
chmod 755 .env

# If worker (-w flag), then update the env file
if [ -z "$WEB_INTERNAL_IP" ]
then
  echo "The -w flag was not provided, and thus not adjusting config file"
else
  echo "Adding CELERY_BROKER_URL and WORKER_API_URL arguments to .env file using internal IP: $WEB_INTERNAL_IP"
  echo "CELERY_BROKER_URL=amqp://guest:guest@$WEB_INTERNAL_IP/default" >> .env
  echo "WORKER_API_URL=http://$WEB_INTERNAL_IP:8010/api/v1" >> .env
fi

echo "SCRIPT FINISHED"
exit 0;
