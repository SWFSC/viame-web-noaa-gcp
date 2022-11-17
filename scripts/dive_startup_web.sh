#!/bin/bash

# Spin up the DIVE web node

# Deal with hardened image permissions
# https://stackoverflow.com/questions/57796839/docker-compose-error-while-loading-shared-libraries-libz-so-1-failed-to-map-s/58068483#58068483
if [ -d "$HOME/tmp" ]
then
  echo "$HOME/tmp already exists"
else
  mkdir $HOME/tmp 
fi
export TMPDIR=$HOME/tmp #this must be run in each shell process


DOCKER_FILE=/opt/noaa/dive/docker-compose.yml
docker-compose -f $DOCKER_FILE pull --include-deps girder rabbit #watchtower
docker-compose -f $DOCKER_FILE up -d girder rabbit
