# Homelab Infrastructure Repository

A comprehensive collection of configuration files, documentation, and setup guides for my Proxmox-based homelab server infrastructure.

![Homelab Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)


## Overview

This repository serves as the central knowledge base and configuration store for my homelab environment. It contains Docker Compose files, configuration templates, setup instructions, and documentation for all services running in my Proxmox environment.


## Network Architecture

The homelab uses a segmented network approach with different subnets for various service types:

| Subnet | Purpose | Description |
|--------|---------|-------------|
| 10.10.1.x | Network | Core networking, DNS, and proxy services |
| 10.10.10.x | Tools and Utilities | Trusted and local administration tools and system monitoring |
| 10.10.20.x | IoT | Smart home devices and automation |
| 10.10.40.x | Public Facing Applications | User-facing services and applications |


## Services

### Networking (Proxmox IDs 100-199)

| Service | Subnet | Description |
|----------|--------|-------------|
| OPNsense | 10.10.1.1 | Router/Firewall (physical device) |
| Pi-hole | 10.10.1.100 | Network-wide ad blocking and local DNS |
| Nginx Proxy Manager (npm) | 10.10.1.101 | Reverse proxy with SSL management (local only) |
| Twingate | 10.10.1.102 | Zero-trust network access solution |
| Omada Controller | 10.10.1.5 | TPLink Omada Controller for Wi-Fi access points and other TPLink devices |
| Cloudflare | 10.10.40.x | DNS management, DDoS protection, and reverse proxy (external only) |

### Storage (Proxmox IDs 200-299)

| Service | Subnet | Description |
|---------|--------|-------------|
| TrueNAS | 10.10.10.101 | Network Attached Storage |
| NextCloud | 10.10.40.x | File hosting and productivity suite |

### Media (Proxmox IDs 300-399)

| Service | Subnet | Description |
|---------|--------|-------------|
| Immich | 10.10.40.x | Self-hosted photo and video backup |
| Plex | 10.10.40.100 | Media server for movies and TV shows |
| Tautulli | 10.10.40.100 | Plex monitoring and statistics |
| Overseerr | 10.40.40.100 | Media request management |
| Radarr | 10.10.40.101 | Movie collection management |
| Sonarr | 10.10.40.101 | TV show collection management |
| Bazarr | 10.10.40.101 | Subtitle management |
| Prowlarr | 10.10.40.101 | Indexer management |
| qBittorrent | 10.10.40.101 | Download manager |

### Tools & Utilities (Proxmox IDs 400-499)

| Service | Subnet | Description |
|---------|--------|-------------|
| Homepage | 10.10.10.102 | A modern, fully static, fast, secure fully proxied, highly customizable application dashboard (https://gethomepage.dev/) |
| Vaultwarden | 10.10.40.x | Self-hosted password manager |
| Hoarder | 10.10.40.x | File collection and organization |
| Portainer | 10.10.10.x | Docker/container management |
| VS Code Server | 10.10.10.x | Web-based code editor |

### Smart Home & Automation (Proxmox IDs 500-599)

| Service | Subnet | Description |
|---------|--------|-------------|
| Home Assistant | 10.10.40.x | Smart home automation platform |
| Frigate NVR | 10.10.10.x | Network video recorder with object detection |
| Zigbee2MQTT | 10.10.20.x | Zigbee device integration bridge |

### Data & Monitoring (Proxmox IDs 600-699)

| Service | Subnet | Description |
|---------|--------|-------------|
| Grafana | 10.10.10.x | Metrics visualization and dashboards |
| InfluxDB | 10.10.10.x | Time-series database for metrics |
| Prometheus | 10.10.10.x | Metrics collection and alerting |
| Cockpit | 10.10.10.x | Web-based system administration |

### VM Clones (Proxmox IDs 1000-1099)

| VM Name | VM ID | Description |
|---------|-------|-------------|
| debian12 | 1001 | Debian 12 VM w/ initial-debian-12-setup.sh installed |

## Repository Structure

```
├── README.md               # This file
├── documentation/			# Written documentation for homelab things
│   ├── GPU Passthrough.md  # Guide for GPU passthrough setup
│   └── PiHole Automated Backup Setup Guide.md # Guide for setting up Pi-hole automated backups
├── networking/         	# Networking services
├── tools-and-utilities/    # Utility services
├── storage/            	# Storage services
├── media/               	# Media services
│   ├── plex/               # Plex media server configuration
│   └── servarr/            # Media management stack (Radarr, Sonarr, etc.)
├── smart-home/         	# Smart home services
├── monitoring/             # Monitoring services
└── scripts/                # Utility scripts for management
    ├── initial-debian-12-setup.sh    # Initial setup script for Debian 12 VMs
    ├── pihole-backup-script.sh       # Automated backup script for Pi-hole
    ├── resize-vm-partition.sh        # Script to resize VM partitions
    └── user-creation-script.sh       # Script to create users with customizable settings
```

## Backup Strategy

- Daily VM backups via Proxmox backup scheduler
- Configuration files backed up to git repository
- Critical data backed up to multiple locations (local and cloud)
- Automated Pi-hole backups to TrueNAS (see [Pi-hole Backup Guide](documentation/PiHole%20Automated%20Backup%20Setup%20Guide.md))

See the [backup documentation](docs/backup/README.md) for detailed procedures.

## Maintenance

Regular maintenance tasks:

- OS updates (monthly)
- Application updates (as needed)
- Security audits (quarterly)
- Performance monitoring (continuous)

### Utility Scripts

The repository includes several utility scripts to help with maintenance and setup:

- **initial-debian-12-setup.sh**: Initial setup script for Debian 12 VMs
- **user-creation-script.sh**: Creates users with SSH access and Docker group membership
- **pihole-backup-script.sh**: Automates Pi-hole configuration backups to TrueNAS
- **resize-vm-partition.sh**: Helps resize VM partitions when needed

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

For personal use, but contributions or suggestions are welcome via issues or pull requests.

## Useful Links

- [Proxmox Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Docker Documentation](https://docs.docker.com/)
- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [TrueNAS Documentation](https://www.truenas.com/docs/)
