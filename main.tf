# Based on https://github.com/Kitware/dive/blob/main/devops/main.tf

variable "zone" {
  type    = string
}

variable "machine_type" {
  type    = string
  default = "n1-standard-4"
}

variable "gpu_type" {
  type    = string
  default = "nvidia-tesla-t4"
}

variable "gpu_count" {
  type    = number
  default = 1
}

variable "disk_size" {
  type    = number
  default = 128 # Size in GB
}

variable "tags" {
  type    = list
}

variable "image" {
  type    = string
}

variable "subnetwork_project" {
  type = string
}

variable "subnetwork" {
  type = string
}

variable "network_ip" {
  type = string
  default = ""
}

variable "name" {
  type    = string
}

variable "sa_email" {
  type = string
}

variable "sa_scopes" {
  type = list
  default = ["cloud-platform"]
}

variable "metadata" {
  type = map
  default = {block-project-ssh-keys = true}
}

variable "resource_policies" {
  type = list
  default = []
}

variable "deletion_protection" {
  type = bool
  default = false
}

variable "allow_stopping_for_update" {
  type = bool
  default = true
}

variable "enable_secure_boot" {
  type = bool
  default = true
}



resource "google_compute_instance" "default" {
  zone         = var.zone
  name         = var.name
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size
      type  = "pd-ssd" # regular block device is too slow
    }
  }

  deletion_protection = var.deletion_protection
  tags = var.tags
  metadata = var.metadata
  resource_policies = var.resource_policies
  allow_stopping_for_update = var.allow_stopping_for_update

  guest_accelerator {
    type  = var.gpu_type
    count = var.gpu_count
  }

  network_interface {
    subnetwork_project = var.subnetwork_project
    subnetwork = var.subnetwork
    network_ip = var.network_ip
  }

  service_account {
    email = var.sa_email
    scopes = var.sa_scopes
  }

  shielded_instance_config {
    enable_secure_boot = var.enable_secure_boot
  }

  scheduling {
    preemptible = "false"    

    # Default true, not supported for GPU nodes, causes failure
    # https://groups.google.com/g/gce-discussion/c/e9K3h3fQuJk
    # https://cloud.google.com/compute/docs/instances/live-migration
    automatic_restart   = "${ var.gpu_count >= 1 ? "false" : "true"}"
    
    # Migrate if machine type is cpu, else terminate if gpu
    # https://cloud.google.com/compute/docs/gpus/create-vm-with-gpus
    # > VMs with GPUs cannot live migrate, make sure that you set the --maintenance-policy TERMINATE flag.
    on_host_maintenance = "${ var.gpu_count >= 1 ? "TERMINATE" : "MIGRATE"}"
  }
}

output "name" {
  value = google_compute_instance.default.name
}
