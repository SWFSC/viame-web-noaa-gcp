#!/bin/bash

# Prep

INSTANCE_NAME=instance-image
ZONE=us-east4-c
REGION=us-east4
IMAGE_NAME_SOURCE=ubuntu-2004pro-cis-hardened-v4
IMAGE_NAME_OUT=ubuntu-2004pro-cis-hardened-v4-allowtcpforwarding

# Create VM using NMFS hardened image
gcloud compute instances create $INSTANCE_NAME \
  --zone=$ZONE --machine-type=n1-standard-1 \
  --network-interface=subnet=projects/nmfs-vpc-host/regions/us-east4/subnetworks/nmfs-usamlr-dev-priv-subnet,no-address \
	--no-service-account --no-scopes --tags=allow-ssh \
	--create-disk=auto-delete=yes,boot=yes,image=projects/nmfs-trusted-images/global/images/$IMAGE_NAME_SOURCE,size=200 \
  --shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring

# Edit config, then stop instance
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
  --command="sudo sed -i \
      's/AllowTcpForwarding no/#AllowTcpForwarding no\nAllowTcpForwarding yes/1' \
      /etc/ssh/sshd_config"

gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
  --command="sudo cat /etc/ssh/sshd_config"

gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE

# Save image
gcloud compute images create $IMAGE_NAME_OUT \
  --source-disk=$INSTANCE_NAME --source-disk-zone=$ZONE --storage-location=$REGION \
  --description=Created\ using\ create_image_sshconfig.sh

# Clean up
gcloud compute instances delete instance-image --zone=$ZONE --quiet
