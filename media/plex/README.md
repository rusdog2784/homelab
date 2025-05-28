# Setting Up Plex

## Connect to TrueNAS Plex
Since we are running the plex service in its own VM as a docker container using docker compose, we need to mount the TrueNAS Plex media (i.e., Movies, TV Shows) via NFS.

1. Install NFS Common utilities: `apt install nfs-common`

2. `nano /etc/fstab`

3. Add the following to the bottom of the file.
	```bash
	# Mounting TrueNAS Plex dataset via NFS
	10.10.10.101:/mnt/main/plex /mnt/plex-media nfs ro,noatime,vers=3,hard,proto=tcp,timeo=600,noexec,nosuid,nodev,_netdev 0 0
	```


## Plex Claim Token
Go to this site: https://account.plex.tv/en/claim


## Deploying Plex with GPU Transcoding
Followed this guide: [Guide for Enabling GPU Transcoding with Plex](https://tizutech.com/plex-transcoding-with-docker-nvidia-gpu/)

Plex Pass Subscription is required.


## Create Plex User
1. `useradd -m -s /bin/bash plex`

2. `passwd plex`