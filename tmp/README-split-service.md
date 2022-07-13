# VIAME-Web in NMFS GCP Project - Split Services

The following steps are to run an instance of VIAME-Web (see [here](https://kitware.github.io/dive/#concepts-and-definitions) for a discussion of terms) on two NMFS-hardened VMs in a Fisheries Cloud (Dev) project. These two VMs consist of a compute-only web node for annotations, and a worker node that can be turned on as needed to run jobs. This is a cost-effective solution, as the VM with the GPU(s) is only turned on as needed. See the [docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#splitting-services) for more details.

Unless otherwise specified, these commands are expected to be run from Cloud Shell. You can clone [this repo](https://github.com/us-amlr/amlr-gcp-terraform) in the home directory of your Cloud Shell so that, e.g., the local paths in the `gcloud compute scp` command below are correct.

These steps were developed from [Scenario 1](https://kitware.github.io/dive/Deployment-Provision/) with the extensive help and expertise of the VIAME team, in particular Brandon Davis, and Ed Rodgers.

## Fisheries Cloud Network Changes

Spinning up an instance of VIAME-Web (with split services) requires several configuration changes:

- To be able to access this web service igitn the Fisheries Cloud environment, the SSH server's configuration (/etc/ssh/sshd_config) needs to include AllowTCPForwarding=yes. This config change must be submitted as an [SCR](https://docs.google.com/forms/d/e/1FAIpQLSdafnuc7bxEIFkXrPpHkwgy1VxoiGEkMVkZjbMe1DdMYJ9THw/viewform) and approved by NMFS CCB on an per-instance basis because this is a baseline setting (specifically, "CIS Benchmarks for Ubuntu Linux 20.04 LTS v1.1.0" Server Level 2 - 5.3.20 "Ensure SSH AllowTcpForwarding is disabled"). Once you have received approval, per Ed you should "either put a startup script in a storage bucket to make the change on startup (specified in VM metadata), or create a local image and deploy from that". Because startup scripts cannot (currently) be used with hardened VMs, you likely should [create a local image](https://github.com/us-amlr/amlr-gcp-terraform/blob/main/dev/create_image_sshconfig.sh). Note that when splitting services, only the web node requires this configuration change.

- [Private Google Access](https://cloud.google.com/vpc/docs/configure-private-google-access) must be enabled within the project to allow communication between the a VM and buckets (along with appropriate service account permissions). This should now be turned on by default for every project, but is worth confirming.

- In GCP, networks are software defined, and thus all traffic is blocked unless a VPC firewall rule is created to allow it, even if it's on the same subnet. Thus, traffic between ports 8010 (Web traffic) and 5672 (RabbitMQ) within subnet must be allowed between the web and worker nodes to split services. Submit an [SCR](https://docs.google.com/forms/d/e/1FAIpQLSdafnuc7bxEIFkXrPpHkwgy1VxoiGEkMVkZjbMe1DdMYJ9THw/viewform) to have the network team add a tag that allows traffic between these ports for the IP addresses in your subnet. Apply this network tag to your web and worker VMs.

## Create GCP VMs

The infrastructure of the web and worker VMs should be identical, except that the web node will have no GPU, should have a slightly larger disk capacity, and needs SSH AllowTcpForwarding to be enabled. Use the Terraform module 'dive' to create these VMs. 

## Provision GCP VMs

First, we set the variables in Cloud Shell that will be used throughout. Note that both install scripts require the internal IP of the web node. This IP is used to add uncommented CELERY_BROKER_URL and WORKER_API_URL arguments to the .env file in the dive folder on each VM. Although note that on the web node CELERY_BROKER_URL must use the local path; see the [install script](dive_install_web.sh).

```shell
ZONE=us-east4-b
INSTANCE_NAME_WEB=viame-web-amlr-web
INSTANCE_NAME_WORKER=viame-web-amlr-worker
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE  --format='get(networkInterfaces[0].networkIP)')
```

### Web VM

To provision the web node, download the install script to the VM, make it executable, and then run the install script from within the VM. The web node only needs the dive repo cloned and docker installed.

```shell
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE \
  --command="curl -L https://raw.githubusercontent.com/us-amlr/amlr-gcp-terraform/main/modules/dive/dive_install_web.sh -o ~/dive_install_web.sh \
  && chmod +x ~/dive_install_web.sh \
  && ~/dive_install_web.sh $WEB_INTERNAL_IP"
```

We need to restart the VM to allow permissions changes to take effect, and then we can run the startup script for the web node.

```shell
gcloud compute instances stop $INSTANCE_NAME_WEB --zone=$ZONE && \
  gcloud compute instances start $INSTANCE_NAME_WEB --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

### Worker VM

Next, provision the worker. Download the install script to the VM, make it executable, and then run the install script from within the VM. Respond 'no' to the PAM overwrite question.

For the internal IP of the web node, you can either copy internal IP of the web node and past it into the command, or set the variables from above within the worker VM to be able to use WEB_INTERNAL_IP.

```shell
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE \
  --command="curl -L https://raw.githubusercontent.com/us-amlr/amlr-gcp-terraform/main/modules/dive/dive_install.sh -o ~/dive_install.sh && chmod +x ~/dive_install.sh"

# ssh into the worker VM
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE 

# From within the VM, run:
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE  --format='get(networkInterfaces[0].networkIP)')
~/dive_install.sh -w $WEB_INTERNAL_IP
exit #to exit the VM
```

Now we restart the worker it to apply the changes, and run the startup script to spin up the worker. 

```shell
gcloud compute instances stop $INSTANCE_NAME_WORKER --zone=$ZONE && \
  gcloud compute instances start $INSTANCE_NAME_WORKER --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"
```

## Access VIAME-Web

Now that we have installed everything, we can access the VIAME-Web instance. Note that if you are restarting either VM, you must run the startup script again to start the relevant services.

```shell
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

and/or

```shell
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"
```

For a user to run either of the startup scripts, they must have permission to run `docker-compose` on the relevant VM. To allow this, you can add users to the docker group. See [manage docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user) for details.

At this point, the stack should be running, and you need to tunnel the port (8010) through SSH. The following command need to be run from your local workstation, ideally from the [Google Cloud SDK Shell](https://cloud.google.com/sdk/docs/install). Note that you only need to run this for the web node, and may need to change the variable format if running from the Windows command prompt.

```shell
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE -- -N -L 8010:localhost:8010
```

You should now be able to access the VIAME-Web instance (the web service) at http://localhost:8010, as described in the [docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#basic-deployment). 

To test that the web and worker nodes can communicate, you can issue a `GET /worker/status` request from the swagger UI at http://localhost:8010/api/v1

## Configure VIAME-Web instance

Now that you can access your VIAME-Web instance, you likely will need to attach at least one read-only assetstore, e.g. a GCS bucket with all the imagery data. Instructions for this process can be found [here](https://kitware.github.io/dive/Deployment-Storage). In short, you will need to 1) configure CORS headers for your bucket(s), 2) create an HMAC key for the service account attached to the VM, and 3) create a new assetstore through the Girder admin console.

You will likely want [add VIAME pipelines](https://kitware.github.io/dive/Deployment-Docker-Compose/#addon-management). If desired, you also can configure aspects of the [server branding](https://kitware.github.io/dive/Deployment-Docker-Compose/#server-branding-config).
