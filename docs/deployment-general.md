# General

NOTE: Be sure to first read the [Deployment Overview](deployment-overview.md).

These steps apply to both deployment scenarios. Unless otherwise specified, these commands (and commands in the scenario-specific instructions) are expected to be run from [Cloud Shell](https://cloud.google.com/shell).

## Clone Repository

It is recommended to clone the [viame-web-fisheries-cloud repo](https://github.com/smwoodman/viame-web-fisheries-cloud) in the home directory of your Cloud Shell to 1) use the module and 2) so that relative paths match these instructions.

```shell
# from your cloud shell
git clone https://github.com/smwoodman/viame-web-fisheries-cloud.git
```

## Create GCP Resources

Both scenarios require many of the same resources, including: a GCS bucket in which to store imagery that will be connected to your VIAME-Web deployment, a NMFS-approved image, and a service account with sufficient permissions. The required CORS headers for the bucket are defined [here](https://kitware.github.io/dive/Deployment-Storage/#setting-up-cors). 

### Sample Terraform Block

Be sure to rename resources and variables as appropriate for your project.

```terraform
# Define variables and provider
variable "project" { 
    type    = string
    default = "gcp_project_id"
}
variable "region" {
    type    = string
    default = "us-east4"
}
variable "zone" {
    type    = string
    default = "us-east4-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
 project = var.project
 region  = var.region
 zone    = var.zone
}


# Create GCS bucket in which to put imagery
resource "google_storage_bucket" "gcs_viame_imagery" {
  name     = "viame-imagery" 
  location = var.region
  force_destroy = false 
  uniform_bucket_level_access = true
  storage_class = "REGIONAL"
  cors {
    origin          = ["http://localhost:8010"]
    method          = ["GET", "PUT", "POST", "DELETE"]
    response_header = ["Content-Type"]
    max_age_seconds = 3600
  }
}

# Create data object for image
data "google_compute_image" "nmfs_hardened_image" {
  name  = "ubuntu-2004pro-cis-hardened-v4"
  project = "nmfs-trusted-images"
}

# Create service account and assign permissions
resource "google_service_account" "vm_sa1" {
  account_id   = "vm-sa1"
  display_name = "vm-sa1"
}

resource "google_project_iam_member" "vm_sa1_roles" {
  project = var.project
  for_each = toset([
  	#todo: refine the roles that are required
    "roles/storage.admin", 
    "roles/compute.admin"
  ])
  role = each.key
  member = "serviceAccount:${google_service_account.vm_sa1.email}"
}
```
