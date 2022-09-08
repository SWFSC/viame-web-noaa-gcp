# Access Instance of VIAME-Web

If you have [configured the containers to start when the VM is started](admin-docker-autostart.md), then skip to [Create SSH Tunnel](deployment-access.md/create-ssh-tunnel). Otherwise, run the startup scripts first.

## Run Startup Scripts

The services (Docker containers) installed on the VM(s) must be running to access the VIAME-Web instance, and thus unless you have [configured the containers to start when the VM is started](admin-docker-autostart.md), it is not enough just to turn on the VMs. These commands to start the services can be run from Cloud Shell or a local shell with [Google Cloud CLI installed](deployment-general.md/before-you-begin) (i.e., a Cloud SDK shell).

Note that for other users to run the startup script, they must have permission to run `docker-compose` on the VM. To allow this, you can add users to the docker group. See [manage docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user) for details.

### Default
``` bash
ZONE=us-east4-c
INSTANCE_NAME=viame-web
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="/opt/noaa/dive_startup_full.sh"
```

### Split Services
``` bash
ZONE=us-east4-c
INSTANCE_NAME_WEB=viame-web-web
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

If you wish to also start the worker services:

``` bash
INSTANCE_NAME_WORKER=viame-web-worker
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"
```

## Create SSH Tunnel

Now that you have provisioned and restarted the VM(s), you can almost access the VIAME-Web instance. Assuming the stack is running, you need to tunnel the 8010 port through SSH. The following command needs to be run from a Cloud SDK shell on your local workstation. Note that you may need to define variables and/or change the variable format.

``` bash
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE -- -N -L 8010:localhost:8010
```

If on a Windows, the first time you run this command you likely will get a PuTTY Security Alert popup window asking if you trust the host. Click either 'Accept' (recommended) or 'Connect Once' to be able to access the server.

You should now be able to access the VIAME-Web instance (the web service) at <http://localhost:8010>, as described in the [DIVE docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#basic-deployment).
