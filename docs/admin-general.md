# General

This page provides a summary of recommended best practices for managing your own deployment of VIAME-Web in the NOAA Fisheries Cloud. Note that these admin options should be evaluated and only used if appropriate to your specific use case.

## Staying up to date

Keeping your deployment up to date is crucial for getting the latest VIAME-Web features and bug fixes, as well as for debugging purposes. It is strongly recommended that you update your images at least once per week.

The DIVE startup scripts that are created on your VMs during deployment provisioning include `docker-compose pull` calls that will update the containers installed on your VM(s) to the `latest` images. Thus, these containers will be updated every time you run the startup script. Depending on your [VM management strategy](vm-management) this may be sufficient, particularly if you turn off your VM(s) at least once per week.

If your VM (default or web) will be on at all times, you should consider the [Production deployment](https://kitware.github.io/dive/Deployment-Docker-Compose/#production-deployment) options.

Note that keeping images up to date will not update canned VIAME addons. See [Addon Management](#addon-management) for details on updating VIAME addons.

## Data backup

Data in GCS Storage buckets are quite [durable](https://cloud.google.com/blog/products/storage-data-transfer/understanding-cloud-storage-11-9s-durability-target). See the [GCS Storage docs](https://cloud.google.com/storage/docs) for more details about data redundancy, versioning, etc.

You can create a GCP [Snapshot Schedule](https://cloud.google.com/compute/docs/disks/scheduled-snapshots) to create snapshot backups of your disk(s). 

[See here](https://drive.google.com/file/d/17JZZZZtXxhGprYY3FbVZ2HzQXszaM3eO/view?usp=sharing) for sample Terraform code and instructions.

## VM management

Your VM schedule, i.e., when your VMs are on (and incurring more costs) and when they are off, will be up to your group. You can use the [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator) to estimate costs.

If you have a split services deployment, an example schedule might be leaving the web VM during the work week, with an [Instance Schedule](https://cloud.google.com/compute/docs/instances/schedule-instance-start-stop) set to turn it off on Friday evening, and turning the worker on and off as needed to run jobs. This would minimize users needing to turn on the web VM (or turning it off while another user is annotating), which also only having the worker VM on when necessary. Recent DIVE [feature additions](https://github.com/Kitware/dive/issues/1260) allow all users to see the status of the job queue so they know if someone else is currently running a job.

[See here](https://drive.google.com/file/d/17JZZZZtXxhGprYY3FbVZ2HzQXszaM3eO/view?usp=sharing) for sample Terraform code and instructions.

## Addon Management

To download and scan for VIAME addons, such as canned pipelines, see the [DIVE Addon Management docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#addon-management).

## Server Branding Config

For information on how to configure the brand and messaging that appears in various places in the DIVE Web UI, see the [DIVE Server Branding Config docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#server-branding-config).

## Storing imagery

Within GCP, storage on Compute Engine disks is much more expensive than storage in [GCS buckets](https://cloud.google.com/storage/docs/introduction). Thus, it is recommended to store your imagery in a GCS bucket and mirror that bucket in your VIAME-Web deployment as a read-only assetstore. See [Cloud Storage Integration](admin-storage.md).

