# VIAME Web in the NOAA Fisheries Cloud

The following steps are to run an instance of VIAME-Web (see [here](https://kitware.github.io/dive/#concepts-and-definitions) for a discussion of terms) on a NMFS-hardened VM in a NMFS Dev GCP project. These will create a single VM with at least one GPU, meaning all operations (annotation, training, etc.) will happen on this VM. For hyprid options, e.g., a low-cost compute VM paired with a worker VM with GPUs, see [these docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#splitting-services) and [this readme](readme-split-service.md).

Unless otherwise specified, these commands are expected to be run from Cloud Shell. You can clone [this repo](https://github.com/us-amlr/amlr-gcp-terraform) in the home directory of your Cloud Shell so that, e.g., the local paths in the `gcloud compute scp` command below are correct.

These steps were developed from [Scenario 1](https://kitware.github.io/dive/Deployment-Provision/) with the extensive help and expertise of the VIAME team, in particular Brandon Davis, and Ed Rodgers.

## Fisheries Cloud Network Changes

Spinning up an instance of VIAME-Web requires several configuration changes:

- To be able to access this web service in the Fisheries Cloud environment, the SSH server's configuration (/etc/ssh/sshd_config) needs to include AllowTCPForwarding=yes. This config change must be submitted as an [SCR](https://docs.google.com/forms/d/e/1FAIpQLSdafnuc7bxEIFkXrPpHkwgy1VxoiGEkMVkZjbMe1DdMYJ9THw/viewform) and approved by NMFS CCB on an per-instance basis because this is a baseline setting (specifically, "CIS Benchmarks for Ubuntu Linux 20.04 LTS v1.1.0" Server Level 2 - 5.3.20 "Ensure SSH AllowTcpForwarding is disabled"). Once you have received approval, per Ed you should "either put a startup script in a storage bucket to make the change on startup (specified in VM metadata), or create a local image and deploy from that". Because startup scripts cannot (currently) be used with hardened VMs, you likely should [create a local image](https://github.com/us-amlr/amlr-gcp-terraform/blob/main/dev/create_image_sshconfig.sh).

- [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access) must be enabled within the project to allow communication between the a VM and buckets (along wiht appropriate service account permissions). This should now be turned on by default for every project, but is worth confirming.

## Create GCP VM

To create a single VM for an instance of VIAME-Web, create a VM with at least one GPU using [this dive module](main.tf). Note that you could also clone [this repo](https://github.com/us-amlr/amlr-gcp-terraform) on the VM and run the scripts from there. Be sure to provide a non-zero value for gpu_count.

## Provision GCP VM

Once the VM is created, download the install script to the VM, make it executable, and then run the install script from within the VM. Respond 'no' to the PAM overwrite question.

```shell
ZONE=us-east4-b
INSTANCE_NAME=viame-web-amlr

gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
  --command="curl -L https://raw.githubusercontent.com/us-amlr/amlr-gcp-terraform/main/modules/dive/dive_install.sh -o ~/dive_install.sh && chmod +x ~/dive_install.sh"

# ssh into the VM
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE

# From within the VM, run:
./dive_install.sh
exit #to exit the VM
```

This install script must be run from within the VM, i.e., it cannot be passed as a command like the `curl` line, to effectively respond to the PAM question.

To be able to access this VM in the Fisheries Cloud environment, the SSH server's configuration (/etc/ssh/sshd_config) needs to include AllowTCPForwarding=yes. HOWEVER, note that this config change must be approved by [NMFS CCB](https://docs.google.com/forms/d/e/1FAIpQLSdafnuc7bxEIFkXrPpHkwgy1VxoiGEkMVkZjbMe1DdMYJ9THw/viewform) on an per-instance basis because this is a baseline setting (specifically, "CIS Benchmarks for Ubuntu Linux 20.04 LTS v1.1.0" Server Level 2 - 5.3.20 "Ensure SSH AllowTcpForwarding is disabled"). 

Once you have received approval, you should "either put a startup script in a storage bucket to make the change on startup (specified in VM metadata), or create a local image and deploy from that". Because startup scripts cannot (currently) be used with hardened VMs, you likely should [create a local image](https://github.com/us-amlr/amlr-gcp-terraform/blob/main/dev/create_image_sshconfig.sh). 

Because of installing the NVIDIA drivers and adding your user to the docker group, the VM must be restarted. While you can restart the VM from the console, it is generally easiest to run the following from Cloud Shell to 1) restart the VM and 2) run the startup script to pull updated files and spin up the VIAME-Web stack:

```shell
gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE && \
  gcloud compute instances start $INSTANCE_NAME --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="/opt/noaa/dive_startup_full.sh"
```

## Access VIAME-Web

Now that we have installed everything, we can access the VIAME-Web instance. Note that if you are restarting a VM that has previously been provisioned, you must run the startup script again to start the stack.

```shell
# From SDK or Cloud Shell
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="/opt/noaa/dive_startup_full.sh"
```

For a user to run the startup script, they must have permission to run `docker-compose` on the VM. To allow this, you can add users to the docker group. See [manage docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user) for details.

At this point, the stack should be running, and you need to tunnel the port (8010) through SSH. The following command need to be run from your local workstation, ideally from the [Google Cloud SDK Shell](https://cloud.google.com/sdk/docs/install). Note that you may need to change the variable format if running from the Windows command prompt.

```shell
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE -- -N -L 8010:localhost:8010
```

You should now be able to access the VIAME-Web instance (the web service) at http://localhost:8010, as described in the [docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#basic-deployment).

## Configure VIAME-Web instance

Now that you can access your VIAME-Web instance, you likely will need to attach at least one read-only assetstore, e.g. a GCS bucket with all the imagery data. Instructions for this process can be found [here](https://kitware.github.io/dive/Deployment-Storage). In short, you will need to 1) configure CORS headers for your bucket(s), 2) create an HMAC key for the service account attached to the VM, and 3) create a new assetstore through the Girder admin console.

You also will likely want [add VIAME pipelines](https://kitware.github.io/dive/Deployment-Docker-Compose/#addon-management). 

