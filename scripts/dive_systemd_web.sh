#!/bin/bash

SERVICENAME=viame-web-pull-docker.service

sudo sh -c 'echo "[Unit]
Description=Run VIAME-Web web startup script at startup after all systemd services are loaded
After=default.target
Requires=docker.service

[Service]
Type=simple
RemainAfterExit=no
Restart=on-failure
User=root
Group=docker
SyslogIdentifier=vwa-web
TimeoutStartSec=0

ExecStart=/opt/noaa/dive_startup_web.sh

[Install]
WantedBy=default.target" > /etc/systemd/system/'$SERVICENAME

sudo systemctl enable $SERVICENAME
sudo systemctl daemon-reload

# # if desired
# sudo systemctl start $SERVICENAME
# sudo systemctl status $SERVICENAME
# sudo grep "vwa-web" /var/log/syslog
