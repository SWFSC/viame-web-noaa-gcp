# Split Services Deployment

NOTE: Be sure to first read the [General](deployment-general.md) deployment instructions.

These instructions are for splitting VIAME-Web web and worker services across two VMs: a compute-only web VM for annotations, and a worker VM with one or more GPUs that can be turned on as needed to run jobs. This is a cost-effective solution, as the (expensive) worker VM is only turned on as needed. See the DIVE [docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#splitting-services) for more details. For running VIAME-Web on s single VM, see the [Default Deployment](deployment-default.md).

## Create GCP Resources

To create two VMs for a split services instance of VIAME-Web, create two VMs: a web and a worker. The infrastructure of the web and worker VMs should be identical, except that the web node will have no GPU, should have a slightly larger disk capacity, and needs SSH AllowTcpForwarding to be enabled. Use the 'viame-web-fisheries-cloud' module to create these VMs. 

### Sample Terraform Block

Your Terraform code for the VMs may look similar to the below. Be sure to rename resources and variables as appropriate for your project.

``` terraform
module "gce-viame-web-web" {
  source = "~/viame-web-fisheries-cloud"

  name = "viame-web-web"
  zone = var.zone

  machine_type = "e2-standard-2"
  image = data.google_compute_image.nmfs_hardened_image.self_link
  disk_size = 300
  gpu_count = 0
  deletion_protection = true

  subnetwork_project = var.subnetwork_project
  subnetwork = var.subnetwork
  tags = ["allow-ssh", "allow-outbound-nat-primary", "allow-outbound-nat-secondary", "viame-tag"]
  sa_email = google_service_account.vm_sa1.email
}

module "gce-viame-web-worker" {
  source = "~/viame-web-fisheries-cloud"

  name = "viame-web-worker"
  zone = var.zone

  machine_type = "n1-standard-4"
  image = data.google_compute_image.nmfs_hardened_image.self_link
  disk_size = 200
  gpu_type  = "nvidia-tesla-t4"
  gpu_count = 1
  deletion_protection = true

  subnetwork_project = var.subnetwork_project
  subnetwork = var.subnetwork
  tags = ["allow-ssh", "allow-outbound-nat-primary", "allow-outbound-nat-secondary", "viame-tag"]
  sa_email = google_service_account.vm_sa1.email
}
```

## Provision GCP VMs

First, we set the variables in Cloud Shell that will be used throughout. Note that both install scripts require the internal IP of the web node.

``` bash
ZONE=us-east4-b
INSTANCE_NAME_WEB=viame-web-amlr-web
INSTANCE_NAME_WORKER=viame-web-amlr-worker
REPO_URL=https://raw.githubusercontent.com/smwoodman/viame-web-fisheries-cloud/scripts
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')
```

### Web VM

Once the VMs have been created, download the install script to the VM, make it executable, and then run the install script from within the VM. Respond 'no' to the PAM overwrite question. This install script does not install GPU drivers, and thus all commands can be passed to the VM from Cloud Shell.

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

gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

### Worker VM

Next, provision the worker. Download the install script to the VM, make it executable, and then run the install script from within the VM. Respond 'no' to the PAM overwrite question.

For the internal IP of the web node, you can either copy internal IP of the web node and past it into the command, or set the variables from above within the worker VM to be able to use WEB_INTERNAL_IP.

``` bash
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE \
  --command="curl -L $REPO_URL/dive_install.sh -o ~/dive_install.sh && chmod +x ~/dive_install.sh"

# ssh into the worker VM
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE 

# From within the VM, after assigning relevant variables run:
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE  --format='get(networkInterfaces[0].networkIP)')
~/dive_install.sh -w $WEB_INTERNAL_IP
exit #to exit the VM
```

Because of permissions changes and installing the NVIDIA drivers, the VM must now be restarted. Restart the VM and run the startup script to pull updated files and spin up the VIAME-Web stack:

``` bash
gcloud compute instances stop $INSTANCE_NAME_WORKER --zone=$ZONE && \
  gcloud compute instances start $INSTANCE_NAME_WORKER --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"
```

## Access VIAME-Web deployment

See [Access VIAME-Web](deployment-access.md)

## Web and Worker VM Communication

For the split services to be able to work, the web and worker VMs must be able to communicate. You can confirm this either through either the DIVE API (recommended) or the VMs directly. Before testing the connection, be sure both the web and worker VMs are on and the services have been started (i.e., the startup scripts have been run). 

### DIVE API

1. Open the swagger UI at `http://{server_url}:{server_port}/api/v1` (likely <http://localhost:8010/api/v1>).
1. Under the 'worker' endpoint, issue a `GET /worker/status` request. 
1. The 'Response Body' section should be a long list of successful connection attempts. If the 'Response Body' values are `null`, then there is a communication issue.

### Other

SSH into the web VM and check that the VM is listening on at least ports 8010 and 5672. Note that you must have root access to run these commands.

``` bash
# check if VM is listening on any ports - should be at least 8010 and 5672 
sudo apt install net-tools #install if necessary 
netstat -plaunt

# Get the internal IP of the web VM from the third block in the output
ifconfig
```

SSH into the worker VM and check if the VM can make a connection to the web VM on the expected ports. These commands should output a string like `Connection to ##.##.##.## 8010 port [tcp/*] succeeded!`. If the worker VM cannot make a connection to the web VM, then you will get a 'operation timed out' message.

``` bash
WEB_IP=##.##.##.##
nc -v -w3 $WEB_IP 8010
nc -v -w3 $WEB_IP 5672

```
