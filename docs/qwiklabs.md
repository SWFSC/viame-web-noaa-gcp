# Qwiklabs deployment

These instructions are for users of the 'GCP IaC with Terraform and Cloud Foundation Toolkit' Qwiklab. Note that Qwiklabs does not allow for GPU deployment, and thus Qwiklabs users will only be able to deploy the web VM of a split services deployment.

## Create GCP Resources

[Click here](https://drive.google.com/u/0/uc?id=1PAVHQowrbEUKVxUMIY2XttfcwZ9EYljD&export=download) to download the Terraform code template for the Qwiklabs deployment. Copy this code into your Terraform config file (e.g., main.tf) and update project-specific values as needed. In the Cloud Shell Terminal, run `terraform init`, and then `terraform apply` to create the resources.

## Provision GCP VM

Once you have created the VM, set variables in your Cloud Shell session that will be used throughout. 

``` bash
ZONE=us-east4-c
INSTANCE_NAME_WEB=viame-web-web
REPO_URL=https://raw.githubusercontent.com/us-amlr/viame-web-noaa-gcp/main/scripts
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
```

Install [ansible](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html#installing-ansible-on-ubuntu).

``` bash
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE \
  --command="sudo apt-get update \\
  && sudo apt-get install software-properties-common \\
  && sudo add-apt-repository --yes --update ppa:ansible/ansible \\
  && sudo apt-get -y install ansible"
```

Now, run a command to download the install script to the VM, make it executable, and then run the install script on the VM.

``` bash
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE \
  --command="curl -L $REPO_URL/dive_install_web.sh -o ~/dive_install_web.sh \
  && chmod +x ~/dive_install_web.sh \
  && ~/dive_install_web.sh $WEB_INTERNAL_IP"
```

You still need to restart the VM to allow permissions changes to take effect. Then, run the startup script for the web node.

``` bash
gcloud compute instances stop $INSTANCE_NAME_WEB --zone=$ZONE && \
  gcloud compute instances start $INSTANCE_NAME_WEB --zone=$ZONE
```
``` bash
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

## Access VIAME-Web deployment

See [Access VIAME-Web](deployment-access.md)
