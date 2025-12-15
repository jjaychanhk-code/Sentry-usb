# TeslaUSB Tools

This directory contains utility scripts for TeslaUSB setup and maintenance.

## Remote Access Setup

### setup-remote-access.sh

Interactive script to configure remote access for customer video viewing.

**Usage:**
```bash
sudo ./setup-remote-access.sh
```

**Options:**
- `tailscale` - Set up Tailscale VPN (recommended, easiest)
- `nginx` - Set up Nginx with SSL certificate (advanced)
- `info` - Display current access information
- (no option) - Interactive menu

**Examples:**
```bash
# Interactive menu
sudo ./setup-remote-access.sh

# Direct Tailscale setup
sudo ./setup-remote-access.sh tailscale

# Show current access info
sudo ./setup-remote-access.sh info
```

For more information, see:
- [Production Deployment Guide](../doc/ProductionDeployment.md)
- [Customer Quick Start Guide](../doc/CustomerQuickStart.md)
