ZONE=us-east4-b
INSTANCE_NAME_WEB=viame-web-amlr-web
INSTANCE_NAME_WORKER=viame-web-amlr-worker
REPO_URL=https://raw.githubusercontent.com/us-amlr/viame-web-noaa-gcp/main/scripts
WEB_INTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME_WEB --zone=$ZONE --format='get(networkInterfaces[0].networkIP)')

gcloud compute instances stop $INSTANCE_NAME_WORKER --zone=$ZONE \
  && gcloud compute instances start $INSTANCE_NAME_WORKER --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE \
  --command="curl -L $REPO_URL/dive_install.sh -o ~/dive_install.sh \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - \
  && chmod +x ~/dive_install.sh \
  && ~/dive_install.sh -w $WEB_INTERNAL_IP"

gcloud compute instances stop $INSTANCE_NAME_WORKER --zone=$ZONE \
  && gcloud compute instances start $INSTANCE_NAME_WORKER --zone=$ZONE

gcloud compute ssh $INSTANCE_NAME_WORKER --zone=$ZONE --command="/opt/noaa/dive_startup_worker.sh"


# Add users to docker group
sudo useradd george_cutter_noaa_gov && sudo usermod -a -G docker george_cutter_noaa_gov
sudo useradd george_watters_noaa_gov && sudo usermod -a -G docker george_watters_noaa_gov
sudo useradd douglas_krause_noaa_gov && sudo usermod -a -G docker douglas_krause_noaa_gov
sudo useradd jefferson_hinke_noaa_gov && sudo usermod -a -G docker jefferson_hinke_noaa_gov
sudo useradd louise_giuseffi_noaa_gov && sudo usermod -a -G docker louise_giuseffi_noaa_gov
sudo useradd victoria_hermanson_noaa_gov && sudo usermod -a -G docker victoria_hermanson_noaa_gov
sudo useradd christian_reiss_noaa_gov && sudo usermod -a -G docker christian_reiss_noaa_gov
sudo useradd jen_walsh_noaa_gov && sudo usermod -a -G docker jen_walsh_noaa_gov
sudo useradd rose_leeger_noaa_gov && sudo usermod -a -G docker rose_leeger_noaa_gov


sudo useradd douglas_krause_noaa_gov \
	# && sudo useradd louise_giuseffi_noaa_gov \
	# && sudo useradd victoria_hermanson_noaa_gov \
	&& sudo useradd christian_reiss_noaa_gov \
	&& sudo useradd jen_walsh_noaa_gov \
	&& sudo useradd rose_leeger_noaa_gov 

sudo usermod -a -G docker george_cutter_noaa_gov \
	&& sudo usermod -a -G docker jefferson_hinke_noaa_gov \
	&& sudo usermod -a -G docker george_watters_noaa_gov \
	&& sudo usermod -a -G docker douglas_krause_noaa_gov \
	&& sudo usermod -a -G docker louise_giuseffi_noaa_gov \
	&& sudo usermod -a -G docker victoria_hermanson_noaa_gov \
	&& sudo usermod -a -G docker christian_reiss_noaa_gov \
	&& sudo usermod -a -G docker jen_walsh_noaa_gov \
	&& sudo usermod -a -G docker rose_leeger_noaa_gov

	for user in userA userB userC; do sudo usermod -a -G mygroup "$user"; done

