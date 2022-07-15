# Migrating to a new server

Within GCP you may need to move to a new project, to resize a disk, or to use a different image. However, these actions require destroying and recreating VMs, and destroying a VM and its associated disk means that all data stored on that VM (e.g., user annotations or trained models) will be lost. This section details how to do this without losing any user data.

## Default and Web VM

The default and web VMs both store user data, and thus care should be taken before destroying these VMs. If these resources do need to be destroyed and recreated, e.g., to move from a Dev to a Prod project, then you can either a) restore a snapshot (link todo) or b) follow the instructions below to avoid losing any user data.

Migrating to a different server should be as easy as copying a few directories from the web server node (web VM).  Everything is in /var/lib/docker/volumes (assuming you haven't modified the "data-root" in /etc/docker/daemon.json).

1) Run (`docker-compose down`) to stop the service.

2) Put the following directories in the same place on the new server.

	* /var/lib/docker/volumes/dive_addons
	* /var/lib/docker/volumes/dive_girder_assetstore
	* /var/lib/docker/volumes/dive_mongo_db

3) Tell the new server's docker metadata about the new volumes:

	* `docker volume create dive_addons`
	* `docker volume create dive_girder_assetstore`
	* `docker volume create dive_mongo_db`

4) Run `docker-compose up` on the new server.

The [docker official docs](https://docs.docker.com/storage/volumes/#backup-restore-or-migrate-data-volumes) have steps for migrating volumes, but they are more complicated because they let you move either named or anonymous volumes. The DIVE volumes are named, so they will likely be easier to move using the steps above.

## Worker VM

If using the [split services deployment](deployment-split.md), no user data are stored on the worker VM and thus the worker VM can safely be destroyed and recreated within your GCP project. Follow the [worker deployment](deployment-split.md/#worker-vm) instructions to deploy and provision the worker. Be sure to provide the correct IP for the web VM. 

Note that if you do destroy and recreate the worker, you will have to re-download any [VIAME addons](https://kitware.github.io/dive/Deployment-Docker-Compose/#addon-management).
