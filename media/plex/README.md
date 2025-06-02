# Setting Up VM
Before we can go ahead and deploy the Plex Media Server, we first need to setup a VM with Docker and your TrueNAS media files mounted. This guide assumes you know how to provision a VM with Docker installed (e.g., https://community-scripts.github.io/ProxmoxVE/scripts?id=docker-vm).

## Create Plex User
After initial VM configuration, we'll create a dedicated `plex` user that we can assign to the Plex Media Server container.

1. `useradd -m -s /bin/bash plex`

2. `passwd plex`


## Mount TrueNAS Plex Media
Since we are running the plex service in its own VM as a docker container using docker compose, we need to mount the TrueNAS Plex media (i.e., Movies, TV Shows) via NFS.

1. Install NFS Common utilities: `apt install nfs-common`

2. `nano /etc/fstab`

3. Add the following to the bottom of the file.
	```bash
	# Mounting TrueNAS Plex dataset via NFS
	10.10.10.101:/mnt/main/plex /mnt/plex-media nfs ro,noatime,vers=3,hard,proto=tcp,timeo=600,noexec,nosuid,nodev,_netdev 0 0
	```


# Media Services Stack
In this section, we are going through the Docker Compose stack for running a complete Plex media server with request management (Overseerr) and analytics (Tautulli).

## Services

- **Plex Media Server** - Core media streaming server with NVIDIA GPU acceleration
- **Overseerr** - User-friendly request management for movies and TV shows
- **Tautulli** - Analytics and monitoring for Plex usage

## Prerequisites

- Docker and Docker Compose installed
- Plex media files mounted at `/mnt/plex-media`
- If using GPU Transcoding,
	- VM needs GPU Passthrough. See [documentation](../../documentation/GPU%20Passthrough.md).
	- NVIDIA Container Toolkit (for GPU acceleration).
	- Plex Pass Subscription is required.
	- Check out the helpful [Guide for Enabling GPU Transcoding with Plex](https://tizutech.com/plex-transcoding-with-docker-nvidia-gpu/).

## Setup

1. **Get your Plex Claim Token**
   - Visit: https://account.plex.tv/en/claim
   - Copy the claim token and update the `PLEX_CLAIM` value in `docker-compose.yaml`

2. **Create the directory structure** (if not already present):
   ```
   ├── README.md
   ├── docker-compose.yaml
   ├── overseerr
   │   └── config
   ├── plex
   │   ├── config
   │   └── transcode
   └── tautulli
       └── config
   ```

3. **Start the stack**:
   ```bash
   docker-compose up -d
   ```

## Access URLs

- **Plex**: http://your-server-ip:32400
- **Overseerr**: http://your-server-ip:5055
- **Tautulli**: http://your-server-ip:8181

## Configuration

### Connecting Overseerr to Plex
In Overseerr settings, use one of these URLs for your Plex server:
- `http://host.docker.internal:32400` (preferred)
- `http://172.17.0.1:32400` (fallback)
- `http://your-actual-host-ip:32400` (most reliable)

### Connecting Tautulli to Plex
Use the same Plex server URLs as above in Tautulli's settings.

## Storage

- **Plex Config**: `./plex/config/` (database, metadata, logs)
- **Plex Transcode**: `./plex/transcode/` (temporary transcoding files)
- **Media Files**: `/mnt/plex-media` (your media library, e.g., TrueNAS)
- **Overseerr Config**: `./overseerr/config/`
- **Tautulli Config**: `./tautulli/config/`

## Management

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down

# Update images
docker-compose pull
docker-compose up -d
```

## Notes

- Plex uses host networking for better performance and DLNA support
- NVIDIA GPU acceleration is enabled for hardware transcoding
- All services restart automatically unless manually stopped
- Configuration files are persisted in local directories