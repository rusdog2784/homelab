# Homelab Infrastructure Repository

A comprehensive collection of configuration files, documentation, and setup guides for my Proxmox-based homelab server infrastructure.

![Homelab Status](https://img.shields.io/badge/status-active-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)


## 🏠 Overview

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
|---------|--------|-------------|
| OPNsense | 10.10.1.1 | Router/Firewall (physical device) |
| Pi-hole | 10.10.1.x | Network-wide ad blocking and local DNS |
| Nginx Proxy Manager | 10.10.1.x | Reverse proxy with SSL management (local only) |
| Twingate | 10.10.1.x | Zero-trust network access solution |
| Cloudflare | 10.10.40.x | DNS management, DDoS protection, and reverse proxy |

### Tools & Utilities (Proxmox IDs 200-299)

| Service | Subnet | Description |
|---------|--------|-------------|
| Omada | 10.10.1.x | TP-Link network controller (physical) |
| Vaultwarden | 10.10.40.x | Self-hosted password manager |
| Hoarder | 10.10.40.x | File collection and organization |
| Portainer | 10.10.10.x | Docker/container management |
| Cockpit | 10.10.10.x | Web-based system administration |
| VS Code Server | 10.10.10.x | Web-based code editor |

### Storage (Proxmox IDs 300-399)

| Service | Subnet | Description |
|---------|--------|-------------|
| TrueNAS | 10.10.10.x | Network Attached Storage |
| Nextcloud | 10.10.40.x | File hosting and productivity suite |

### Media (Proxmox IDs 400-499)

| Service | Subnet | Description |
|---------|--------|-------------|
| Immich | 10.10.40.x | Self-hosted photo and video backup |
| Plex | 10.10.40.x | Media server for movies and TV shows |
| Tautulli | 10.10.10.x | Plex monitoring and statistics |

### Media Management (Proxmox IDs 500-599)

| Service | Subnet | Description |
|---------|--------|-------------|
| Homarr | 10.10.40.x | Dashboard for services |
| Overseerr | 10.10.40.x | Media request management |
| Radarr | 10.10.40.x | Movie collection management |
| Sonarr | 10.10.40.x | TV show collection management |
| Bazarr | 10.10.40.x | Subtitle management |
| Prowlarr | 10.10.40.x | Indexer management |
| qBittorrent | 10.10.40.x | Download manager |

### Smart Home & Automation (Proxmox IDs 600-699)

| Service | Subnet | Description |
|---------|--------|-------------|
| Home Assistant | 10.10.40.x | Smart home automation platform |
| Frigate NVR | 10.10.10.x | Network video recorder with object detection |
| Zigbee2MQTT | 10.10.20.x | Zigbee device integration bridge |

### Data & Monitoring (Proxmox IDs 700-799)

| Service | Subnet | Description |
|---------|--------|-------------|
| Grafana | 10.10.10.x | Metrics visualization and dashboards |
| InfluxDB | 10.10.10.x | Time-series database for metrics |
| Prometheus | 10.10.10.x | Metrics collection and alerting |

## 📂 Repository Structure

```
├── README.md               # This file
├── networking/         	# Networking services
├── tools-and-utilities/    # Utility services
├── storage/            	# Storage services
├── media/               	# Media services
├── smart-home/         	# Smart home services
└── monitoring/             # Monitoring services
└── scripts/                # Utility scripts for management
    ├── backup/             # Backup scripts
    ├── monitoring/         # Monitoring scripts
    └── automation/         # Automation scripts
```

## 🚀 Getting Started

### Prerequisites

- Proxmox VE (version 8)
- Basic understanding of networking, virtualization, and containerization
- Network with segmented VLANs (optional but recommended)

### Initial Setup

1. Clone this repository
   ```bash
   git clone https://github.com/rusdog/homelab.git
   ```

2. Review the documentation in the `docs/` directory for specific service setup instructions

3. Customize configurations to match your environment needs

## 🔄 Backup Strategy

- Daily VM backups via Proxmox backup scheduler
- Configuration files backed up to git repository
- Critical data backed up to multiple locations (local and cloud)

See the [backup documentation](docs/backup/README.md) for detailed procedures.

## 🛠️ Maintenance

Regular maintenance tasks:

- OS updates (monthly)
- Application updates (as needed)
- Security audits (quarterly)
- Performance monitoring (continuous)

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📊 Monitoring Dashboard

Access the monitoring dashboard at: http://grafana.local (or use the direct IP: 10.10.10.600)

## 🤝 Contributing

For personal use, but contributions or suggestions are welcome via issues or pull requests.

## 🔗 Useful Links

- [Proxmox Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [Docker Documentation](https://docs.docker.com/)
- [Home Assistant Documentation](https://www.home-assistant.io/docs/)
- [TrueNAS Documentation](https://www.truenas.com/docs/)
