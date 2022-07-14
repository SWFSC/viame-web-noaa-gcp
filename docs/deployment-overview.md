# Deployment Overview

These instructions assume that you manage the configuration of your GCP project through Terraform, and specifically that run your [Terrafom commands through Cloud Shell](https://www.hashicorp.com/blog/kickstart-terraform-on-gcp-with-google-cloud-shell).

## Overview

The deployment pages will walk you through several steps: creating the VM(s) in GCP, provisioning the VM(s), and accessing your deployment of VIAME-Web. See todo for a discussion of configuration options.

## Before you begin

Read the [DIVE Deployment Options Overview](https://kitware.github.io/dive/Deployment-Overview/) and [Cloud Deployment Guide Before you begin
](https://kitware.github.io/dive/Deployment-Provision/#before-you-begin) before you begin.

## Clone Repo

```shell
# from your cloud shell
git clone https://github.com/smwoodman/viame-web-fisheries-cloud.git
```

You will use this repo as a [module](https://www.terraform.io/language/modules/syntax) in the deployment steps.
