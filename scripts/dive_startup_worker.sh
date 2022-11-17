#!/bin/bash

# Spin up the DIVE worker node

# Deal with hardened image permissions
# https://stackoverflow.com/questions/57796839/docker-compose-error-while-loading-shared-libraries-libz-so-1-failed-to-map-s/58068483#58068483
if [ -d "$HOME/tmp" ]
then
  echo "$HOME/tmp already exists"
else
  mkdir $HOME/tmp 
fi
export TMPDIR=$HOME/tmp #this must be run in each shell process

# docker-compose pull
# docker-compose -f docker-compose.yml up -d --no-deps girder_worker_pipelines girder_worker_training girder_worker_default

DOCKER_FILE=/opt/noaa/dive/docker-compose.yml
docker-compose -f $DOCKER_FILE pull girder_worker_pipelines girder_worker_training girder_worker_default
docker-compose -f $DOCKER_FILE up -d --no-deps girder_worker_pipelines girder_worker_training girder_worker_default
