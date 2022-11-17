# Starting Docker Containers Automatically

You can configure your deployment so that the necessary docker containers start automatically when a GCP VM is turned on. This avoids the issue ([fix here](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)) where other users don't have permissions to run the `docker` command.

One option if you don't want to rely on docker is to use a process manager like systemd for the docker-compose command, and have that configured to run on start-up. This is more powerful as it can be heavily customized, but is more involved to implement.

The other option to have the docker containers start automatically is to change the [restart policy](https://docs.docker.com/compose/compose-file/compose-file-v3/#restart). You can do this by adding, for instance, `restart: unless-stopped` to the relevant services. For a default deployment, add the restart policy for each service. For a split deployment you need to add the policy to the traefik, rabbit, mongo, and girder services for the web node, and the girder_worker_default, girder_worker_pipelines, and girder_worker_training services (or just to the base-worker object) for the worker node. For example:

```yml
...
services:
  traefik:
    restart: unless-stopped
    image: traefik:v2.4
...
```

or 

```yml
...
x-worker: &base-worker
  deploy:
    resources:
      reservations:
        devices:
          - capabilities: [gpu]
  ipc: host
  build:
    context: .
    dockerfile: docker/girder_worker.Dockerfile
  restart: unless-stopped
  image: kitware/viame-worker:${TAG:-latest}
  volumes:
...
```

In the future, this will be added as an [option on install](https://github.com/us-amlr/viame-web-noaa-gcp/issues/2). 

NOTE: if you implement this option, then the docker container updates are not pulled each time the VM is started. You must stop the containers, pull the updates, and spin the containers back up:

```bash
# If necessary, handle hardened VM permissions
mkdir $HOMR/tmp #have to run at least once
export TMPDIR=$HOME/tmp
# Shut down the containers
docker-compose -f /opt/noaa/dive/docker-compose.yml down
# The startup script pulls updates and starts the containers
/opt/noaa/dive_startup_web.sh #or, eg /opt/noaa/dive_startup_worker.sh
````
