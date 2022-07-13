# Default Deployment

!!! note

    Be sure to read the [Overview](deployment-overview.md) first.

These instructions will create a single VM with at least one GPU, meaning all operations (annotation, training, etc.) will happen on this VM. For hyprid options, e.g., a low-cost compute VM paired with a worker VM with GPUs, see [Split Services](deployment-split.md).

Unless otherwise specified, these commands are expected to be run from [Cloud Shell](https://cloud.google.com/shell). It is recommended to clone [this repo](https://github.com/smwoodman/viame-web-fisheries-cloud) in the home directory of your Cloud Shell to 1) use the module and 2) so that relateive paths are correct.

## Create GCP VM

To create a single VM for an instance of VIAME-Web, create a VM with at least one GPU using [this dive module](main.tf). Be sure to provide a non-zero value for gpu_count.

## Provision GCP VM

Once the VM is created, download the install script to the VM, make it executable, and then run the install script from within the VM. Respond 'no' to the PAM overwrite question. Note that the install script must be run from within the VM, i.e., after ssh'ing into the VM, to effectively respond to the PAM question.

```shell
ZONE=us-east4-b
INSTANCE_NAME=viame-web-amlr

gcloud compute ssh $INSTANCE_NAME --zone=$ZONE \
  --command="curl -L https://raw.githubusercontent.com/smwoodman/viame-web-fisheries-cloud/scripts/dive_install.sh -o ~/dive_install.sh && chmod +x ~/dive_install.sh"

# ssh into the VM
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE

# From within the VM, run:
./dive_install.sh
exit #to exit the VM, after the script completes
```

Because of installing the NVIDIA drivers and adding your user to the docker group, the VM must now be restarted. While you can restart the VM from the console, it is generally easiest to run the following from Cloud Shell to 1) restart the VM and 2) run the startup script to pull updated files and spin up the VIAME-Web stack:

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