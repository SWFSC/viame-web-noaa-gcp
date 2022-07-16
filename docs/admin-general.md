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

### Sample Terraform Block

``` terraform
# NOTE: to add disk to this snapshot schedule:
#   1) Create the snapshot schedule as here
#   a) Add the disk to the snapshot schedule using gcloud commands or the Console
resource "google_compute_resource_policy" "viame_web_web_snapshot" {
  name   = "viame-web-web-snapshot"
  region = "us-east4"
  snapshot_schedule_policy {
    schedule {
      weekly_schedule {
        day_of_weeks {
          day        = "MONDAY"
          start_time = "06:00" #GMT, so 1am pdt and 4am edt
        }
      }
    }
    retention_policy {
      max_retention_days    = 60
      on_source_disk_delete = "KEEP_AUTO_SNAPSHOTS"
    }
    snapshot_properties {
      labels = {
        vm = "viame-web-web"
      }
      storage_locations = ["us-east4"]
      guest_flush       = true
    }
  }
}
```

## VM management

Your VM schedule, i.e., when your VMs are on (and incurring more costs) and when they are off, will be up to your group. You can use the [Google Cloud Pricing Calculator](https://cloud.google.com/products/calculator) to estimate costs.

If you have a split services deployment, an example schedule might be leaving the web VM during the work week, with an [Instance Schedule](https://cloud.google.com/compute/docs/instances/schedule-instance-start-stop) set to turn it off on Friday evening, and turning the worker on and off as needed to run jobs. This would minimize users needing to turn on the web VM (or turning it off while another user is annotating), which also only having the worker VM on when necessary. Recent DIVE [feature additions](https://github.com/Kitware/dive/issues/1260) allow all users to see the status of the job queue so they know if someone else is currently running a job.

### Sample Terraform Block

This block creates an instance schedule to stop an instance at 2300, LA time, every Friday.

``` terraform
# NOTE: To add a VM to this schedule without destroying and recreating them:
#   1) create the google_compute_resource_policy resource
#   2) Add the VM to the instance schedule using gcloud or the Console
#   3) Add the resource_policies line to the google_compute_instance resource
#   4) Test that state and code match with `terraform plan`
resource "google_compute_resource_policy" "viame_web_stop" {
  name   = "viame-web-stop"
  region = "us-east4"

  instance_schedule_policy {
    vm_stop_schedule {
      schedule = "0 23 * * 5"
    }
    time_zone = "America/Los_Angeles"
  }
}
```

## Addon Management

To download and scan for VIAME addons, such as canned pipelines, see the [DIVE Addon Management docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#addon-management).

## Server Branding Config

For information on how to configure the brand and messaging that appears in various places in the DIVE Web UI, see the [DIVE Server Branding Config docs](https://kitware.github.io/dive/Deployment-Docker-Compose/#server-branding-config).

## Storing imagery

Within GCP, storage on Compute Engine disks is much more expensive than storage in [GCS buckets](https://cloud.google.com/storage/docs/introduction). Thus, it is recommended to store your imagery in a GCS bucket and mirror that bucket in your VIAME-Web deployment as a read-only assetstore. See [Cloud Storage Integration](admin-storage.md).

