# Deployment Overview

## Before you begin

Read the DIVE [Deployment Options Overview](https://kitware.github.io/dive/Deployment-Overview/) and [Cloud Deployment Guide - Before you begin
](https://kitware.github.io/dive/Deployment-Provision/#before-you-begin) before you begin.

Also, ensure that the required [network changes](network-changes.md) have been made for your project.

## Overview

These instructions assume that you manage the configuration of your GCP project through Terraform, and specifically that run your [Terraform commands through Cloud Shell](https://www.hashicorp.com/blog/kickstart-terraform-on-gcp-with-google-cloud-shell).

The subsequent pages will walk you through several steps: creating the virtual machine(s) in GCP, provisioning the VM(s), and accessing your deployment of VIAME-Web. See TODO for a discussion of configuration options.

These instructions work and this deployment is (relatively) straightforward because the VIAME team has created [Docker containers](https://www.docker.com/resources/what-container/) for the different services that make VIAME-Web run. Thus, after some VM configuration, we can simply download and run these containers to use spin up our own instance of VIAME-Web.
