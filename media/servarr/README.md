# Servarr Services Stack

A comprehensive Docker-based media management stack featuring automated media acquisition and organization with VPN protection through Gluetun.

## Services

### Core Download Services (VPN Protected)
- **Gluetun** - VPN client container that handles all VPN-connected services
- **qBittorrent** - Torrent client (accessible via VPN)
- **Prowlarr** - Indexer manager and proxy (accessible via VPN)
- **Speedtest Tracker** - Automated internet speed testing with historical data and performance monitoring

### Media Management Services
- **Sonarr** - TV shows management and automation
- **Radarr** - Movies management and automation  
- **Lidarr** - Music management and automation
- **Bazarr** - Subtitle management and automation

### Support Services
- **Byparr** - Proxy server that solves Cloudflare challenges and CAPTCHAs for indexers (https://github.com/ThePhaseless/Byparr)
- **Deunhealth** - Container health monitoring and management service

## Prerequisites

- Docker and Docker Compose installed
- A valid VPN subscription (configured in .env)
- TrueNAS Plex Media storage mounted:
	- Install cifs-utils: `apt install cifs-utils`
	- Edit `/etc/fstab` and add the following to the bottom being sure to change some values: 
		```bash
		# Mounting TrueNAS Plex dataset via CIFS
		//10.10.10.101/plex /mnt/plex-media cifs uid=<user id of host user (e.g., `id plex`)>,gid=<group id of host user (e.g., `id plex`)>,username=<truenas user>,password=<truenas password>,iocharset=utf8 0 0
		```

## Port Mappings

- **Radarr**: 7878
- **Sonarr**: 8989
- **Lidarr**: 8686
- **Bazarr**: 6767
- **Byparr**: 8191

### VPN-Protected Services (via Gluetun)
- **qBittorrent**: 8080
- **Prowlarr**: 9696
- **Speedtest Tracker**: 8888

## Directory Structure

```
servarr-services/
├── docker-compose.yaml
├── .env
├── README.md
├── bazarr/config/
├── gluetun/
├── lidarr/config/
├── prowlarr/config/
├── qbittorrent/config/
├── radarr/config/
├── sonarr/config/
└── speedtest-tracker/config/
```

## Configuration

1. **Create the `.env` file** with the following variables (or copy and modify the `example.env` file):
   ```env
   PUID=1000
   PGID=1000
   TZ=America/Denver
   # Add your VPN provider credentials here
   VPN_SERVICE_PROVIDER=your_provider
   VPN_USERNAME=your_username
   VPN_PASSWORD=your_password
   # Additional VPN settings as needed
   ```

2. **Configure VPN settings** in the `.env` file based on your provider

3. **Ensure proper permissions** are set on `/mnt/plex-media` directory

4. **Start the stack**:
   ```bash
   docker-compose up -d
   ```

## Networking

The stack uses a custom network (`servarrnetwork`) with subnet `192.168.0.0/24` and specific IP assignments:

**Static IP Assignments:**
- **Gluetun**: 192.168.0.2
- **Sonarr**: 192.168.0.3
- **Radarr**: 192.168.0.4
- **Lidarr**: 192.168.0.5
- **Bazarr**: 192.168.0.6
- **Byparr**: 192.168.0.7

**VPN-Routed Services:**
VPN-dependent services (qBittorrent, Prowlarr, Speedtest Tracker) use `network_mode: service:gluetun` and are accessible via Gluetun's IP (192.168.0.2).

## Service Configuration

### Inter-Service Communication
When configuring services to communicate with each other:

**From management services to VPN-protected services:**
- **qBittorrent**: `http://192.168.0.2:8080`
- **Prowlarr**: `http://192.168.0.2:9696`
- **Speedtest Tracker**: `http://192.168.0.2:8888`

**From management services to other management services:**
- Use container names: `http://sonarr:8989`, `http://radarr:7878`, etc.
- Or static IPs: `http://192.168.0.3:8989`, `http://192.168.0.4:7878`, etc.

### Cloudflare Challenge Solvers
Configure in Prowlarr for indexers requiring challenge solving:
- **Byparr**: `http://192.168.0.7:8191`

## Data Storage

- **Media Files**: `/mnt/plex-media` (TrueNAS CIFS mount)
- **Configuration**: Individual `./[service]/config/` directories  
- **Downloads**: Local `./qbittorrent/downloads/` directory
- **Speedtest Data**: `./speedtest-tracker/config/` directory

## Management Commands

```bash
# Start all services
docker-compose up -d

# View logs for specific service
docker-compose logs -f [service-name]

# Restart a specific service
docker-compose restart [service-name]

# Stop all services
docker-compose down

# Update all images
docker-compose pull
docker-compose up -d

# Rebuild custom images (flare-bypasser)
docker-compose build byparr
docker-compose up -d byparr

# Check VPN connection
docker-compose exec gluetun curl ifconfig.me
```

## Optional Services

The following services are available but commented out by default:

- **ytdl-sub**: YouTube subscription downloader (IP: 192.168.0.8) - *Note: IP needs updating*
- **jellyseerr**: Media request management system (IP: 192.168.0.9) - *Note: IP needs updating*

To enable these services, uncomment their sections in the docker-compose.yaml file and update their IP addresses to avoid conflicts.

## Health Checks and Monitoring

- **Gluetun and qBittorrent** include health checks to ensure VPN connectivity
- **Deunhealth service** monitors and manages container health status, automatically restarting unhealthy containers
- **Health check commands** verify internet connectivity through VPN tunnel

## Security Notes

- **Download clients** (qBittorrent, Prowlarr) are protected by VPN tunnel
- **Speedtest Tracker** runs through VPN to test true connection speed
- **Management services** have direct internet access for metadata retrieval
- **All services** run with specified PUID/PGID to avoid permission issues
- **Inter-service communication** stays within the custom Docker network