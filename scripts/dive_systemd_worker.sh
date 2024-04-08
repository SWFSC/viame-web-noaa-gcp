#!/bin/bash

SERVICENAME=viame-worker-pull-docker.service

sudo sh -c 'echo "[Unit]
Description=Run VIAME-Web worker startup script at startup after all systemd services are loaded
After=default.target
Requires=docker.service

[Service]
Type=simple
RemainAfterExit=no
Restart=on-failure
User=root
Group=docker
SyslogIdentifier=vwa-worker
TimeoutStartSec=0

ExecStart=/opt/noaa/dive_startup_worker.sh

[Install]
WantedBy=default.target" > /etc/systemd/system/'$SERVICENAME

sudo systemctl enable $SERVICENAME
sudo systemctl daemon-reload

# # if desired
# sudo systemctl start $SERVICENAME
# sudo systemctl status $SERVICENAME
# sudo grep "vwa-worker" /var/log/syslog
