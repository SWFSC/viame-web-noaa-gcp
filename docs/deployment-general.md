# General

## Overview

These instructions assume that you manage the configuration of your GCP project through Terraform, and specifically that run your [Terraform commands through Cloud Shell](https://www.hashicorp.com/blog/kickstart-terraform-on-gcp-with-google-cloud-shell). Note also that users must have GCP Project Owner or Administrator privileges (e.g., [roles/owner](https://cloud.google.com/iam/docs/understanding-roles#basic)).  

The subsequent pages will walk you through several steps: creating the virtual machine(s) and other resources in GCP, provisioning the VM(s), and accessing your deployment of VIAME-Web. 

These instructions work and this deployment is (relatively) straightforward because the VIAME team has created [Docker containers](https://www.docker.com/resources/what-container/) for the different services that make up VIAME-Web. Thus, after some VM configuration, we can simply download and run these containers to use spin up our own instance of VIAME-Web. Updating the services is also as simple as pulling down updated versions of the containers.

The steps on this page apply to both deployment scenarios. Unless otherwise specified, these commands (and commands in the scenario-specific instructions) are expected to be run from [Cloud Shell](https://cloud.google.com/shell).

## Before you begin

* Read the [Deployment Options Overview](https://kitware.github.io/dive/Deployment-Overview/) and [Cloud Deployment Guide - Before you begin
](https://kitware.github.io/dive/Deployment-Provision/#before-you-begin). 

* Ensure that the required [network changes](network-changes.md) have been made for your project.

* Ensure that the [Google Cloud CLI](https://cloud.google.com/sdk/gcloud) tools are [installed and configured](https://cloud.google.com/sdk/docs/install) on your local workstation.

## Create GCP Resources

Both scenarios require many of the same resources, including: a GCS bucket in which to store imagery that will be connected to your VIAME-Web deployment, a NMFS-approved image, and a service account with sufficient permissions. [See here](https://drive.google.com/file/d/16vJPK8ikKm5QlPcrcWciJhXOGvGN6jTa/view?usp=sharing) for a Terraform code template for general resources.

Note that there might be a delay between a VM has been created and/or started, and when you can run an install or startup script. If you get an error, please wait a few minutes and try to run the command again.

[See here](https://kitware.github.io/dive/Deployment-Storage/#setting-up-cors) for more information about the required CORS headers for the bucket. 
