# Access Instance of VIAME-Web

## Start Docker Containers

If you have just turned on the VM, you must run the startup script again to start the stack. These commands can be run from Cloud Shell or an SDK window. 

Note that for a user to run the startup script, they must have permission to run `docker-compose` on the VM. To allow this, you can add users to the docker group. See [manage docker as a non-root user](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user) for details.

### Default
```shell
ZONE=us-east4-c
INSTANCE_NAME=viame-web
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --command="/opt/noaa/dive_startup_full.sh"
```

### Split Services
```shell
ZONE=us-east4-c
INSTANCE_NAME_WEB=viame-web-web
gcloud compute ssh $INSTANCE_NAME_WEB --zone=$ZONE --command="/opt/noaa/dive_startup_web.sh"
```

If you wish to also start the worker stack:

```shell
INSTANCE_NAME_WORKER=viame-web-worker
gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"
```

## Create SSH Tunnel

Now that you have provisioned and restarted the VM(s), you can almost access the VIAME-Web instance. Assuming the stack is running, you need to tunnel the port (8010) through SSH. The following command needs to be run from your local workstation, ideally from the [Google Cloud SDK Shell](https://cloud.google.com/sdk/docs/install). Note that you may need to define and/or change the variable format.

```shell
gcloud compute ssh $INSTANCE_NAME --zone=$ZONE -- -N -L 8010:localhost:8010
```

You should now be able to access the VIAME-Web instance (the web service) at http://localhost:8010, as described in the [DIVE docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#basic-deployment).
