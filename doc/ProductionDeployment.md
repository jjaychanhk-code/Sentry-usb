# Production Deployment Guide for Customer Video Access

This guide explains how to deploy TeslaUSB in a production environment to allow customers to view their Tesla Sentry and dashcam videos remotely.

> **🇨🇳 中国用户注意 / Note for Chinese Users:** 如果您在中国大陆，建议使用阿里云或腾讯云部署以获得更好的网络性能。请参见 [中国云平台部署指南](ChineseCloudDeployment.md)。
>
> If you're in mainland China, we recommend using Alibaba Cloud or Tencent Cloud for better network performance. See the [Chinese Cloud Platform Deployment Guide](ChineseCloudDeployment.md).

## Overview

TeslaUSB provides a web interface that allows viewing of recorded Sentry clips, SavedClips, and RecentClips. This guide covers how to:

1. Set up secure remote access for customers
2. Configure authentication and security
3. Enable customers to view their videos from anywhere
4. Optionally set up real-time video access (with limitations)

## Prerequisites

- Completed basic TeslaUSB setup (see [OneStepSetup.md](OneStepSetup.md))
- Raspberry Pi with stable WiFi connection
- Static IP address or dynamic DNS service
- SSL certificate (recommended for production)

## Deployment Options

### Option 1: Local Network Access (Simplest)

This option allows customers to view videos when connected to the same WiFi network as the Raspberry Pi.

**Setup:**
1. Note the Pi's IP address: `ssh pi@teslausb.local` and run `hostname -I`
2. Access the web interface at: `http://[PI_IP_ADDRESS]`
3. Share this URL with the customer (only works on local network)

**Pros:**
- Simple setup, no additional configuration needed
- Most secure (no external exposure)

**Cons:**
- Only accessible on local network
- Requires customer to be at home

### Option 2: VPN Access (Recommended for Security)

Set up a VPN server to allow secure remote access to the local network.

**Setup:**
1. Install VPN server on your network (options: WireGuard, OpenVPN, Tailscale)
2. Configure customer devices with VPN client
3. Access TeslaUSB through VPN connection at `http://teslausb.local`

**Pros:**
- Secure encrypted connection
- Access from anywhere
- No port forwarding required

**Cons:**
- Requires VPN setup and configuration
- Customer needs VPN client app

#### Recommended: Tailscale (Easiest VPN Option)

Tailscale provides zero-config VPN:

```bash
# On the Raspberry Pi:
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Share the Tailscale hostname with customers to access from anywhere.

### Option 3: Direct Internet Access (Advanced)

Expose the web interface directly to the internet with proper security measures.

**Requirements:**
- SSL certificate (Let's Encrypt recommended)
- Strong authentication
- Firewall configuration
- Regular security updates

**Setup Steps:**

1. **Configure Static IP or Dynamic DNS:**
   ```bash
   # Install ddclient for dynamic DNS
   sudo apt-get install ddclient
   ```
   Configure your preferred DDNS service (NoIP, DuckDNS, etc.)

2. **Set up port forwarding on your router:**
   - Forward external port 443 (HTTPS) to Pi's port 443
   - Forward external port 80 (HTTP) to Pi's port 80 (for Let's Encrypt verification)

3. **Install and configure nginx with SSL:**
   ```bash
   sudo apt-get install nginx certbot python3-certbot-nginx
   ```

4. **Obtain SSL certificate:**
   ```bash
   sudo certbot --nginx -d yourdomain.com
   ```

5. **Configure nginx reverse proxy** (see nginx configuration section below)

**Pros:**
- Direct access from anywhere
- Professional appearance with custom domain
- No VPN client required

**Cons:**
- More complex setup
- Requires ongoing security maintenance
- Exposed to internet attacks if not properly secured

## Security Configuration

### Basic Authentication

Add password protection to the web interface:

1. **Install Apache utilities:**
   ```bash
   sudo apt-get install apache2-utils
   ```

2. **Create password file:**
   ```bash
   sudo htpasswd -c /etc/nginx/.htpasswd customer_username
   ```

3. **Update nginx configuration** to require authentication (see below)

### Nginx Configuration for Production

Create `/etc/nginx/sites-available/teslausb`:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name yourdomain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name yourdomain.com;
    
    # SSL configuration (managed by certbot)
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Basic authentication
    auth_basic "Tesla Dashcam Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    # Proxy to TeslaUSB web interface
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Increase timeout for video streaming
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
    
    # Optimize video delivery
    location ~* \.(mp4|webm)$ {
        proxy_pass http://localhost:80;
        proxy_buffering off;
        proxy_set_header X-Real-IP $remote_addr;
        add_header Cache-Control "public, max-age=3600";
    }
}
```

Enable the configuration:
```bash
sudo ln -s /etc/nginx/sites-available/teslausb /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Firewall Configuration

Configure the firewall to only allow necessary ports:

```bash
# Install UFW (Uncomplicated Firewall)
sudo apt-get install ufw

# Allow SSH (important - don't lock yourself out!)
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## Customer Access Guide

Once deployed, provide customers with:

### Access Instructions

**For VPN Access:**
1. Install VPN client app
2. Import provided VPN configuration
3. Connect to VPN
4. Navigate to `http://teslausb.local` or `http://[PI_IP]`

**For Direct Internet Access:**
1. Navigate to `https://yourdomain.com`
2. Enter provided username and password
3. Use the "Viewer" tab to watch Sentry events
4. Use the "Recordings" tab to browse all videos

### Using the Web Interface

The TeslaUSB web interface provides several features:

- **Viewer Tab**: Watch Sentry/SavedClips/RecentClips with synchronized multi-angle playback
- **Recordings Tab**: Browse and download individual video files
- **Files Tab**: Access music/LightShow/Boombox files
- **Tools Tab**: System status and diagnostics

## Real-Time Video Streaming (Experimental)

**Important Limitation:** Tesla vehicles do not provide real-time streaming of dashcam footage while parked. The dashcam system only saves video when:
- Sentry Mode is triggered (motion/impact detected)
- Dashcam recording is active while driving
- Manual save button is pressed

### Near-Real-Time Access

The closest to "real-time" viewing available is:

1. **Quick Archive Sync**: Configure frequent archive syncing
   ```bash
   # Edit /root/.teslaCamArchiveScripts
   # Set shorter idle time (default is 30 minutes)
   ARCHIVE_IDLE_WAIT=300  # 5 minutes
   ```

2. **Auto-Refresh Web Interface**: Add auto-refresh to continuously check for new videos
   (Implementation in next section)

3. **Push Notifications**: Configure notifications when new Sentry events are detected
   See [ConfigureNotificationsForArchive.md](ConfigureNotificationsForArchive.md)

## Monitoring and Maintenance

### Regular Maintenance Tasks

1. **Update SSL Certificates** (automated with Let's Encrypt)
   ```bash
   sudo certbot renew --dry-run
   ```

2. **Update System Packages**
   ```bash
   sudo apt-get update && sudo apt-get upgrade
   ```

3. **Monitor Disk Space**
   ```bash
   df -h
   ```

4. **Check Logs**
   ```bash
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

### Security Best Practices

1. **Change default passwords** (both Pi user and web interface)
2. **Keep system updated** with latest security patches
3. **Use strong passwords** for web authentication
4. **Monitor access logs** for suspicious activity
5. **Regular backups** of configuration
6. **Enable fail2ban** to prevent brute force attacks:
   ```bash
   sudo apt-get install fail2ban
   sudo systemctl enable fail2ban
   ```

## Troubleshooting

### Videos not loading
- Check network connection
- Verify nginx is running: `sudo systemctl status nginx`
- Check disk space: `df -h`
- Review error logs: `sudo tail -f /var/log/nginx/error.log`

### Cannot access remotely
- Verify port forwarding is configured correctly
- Check firewall rules: `sudo ufw status`
- Confirm DNS is resolving: `nslookup yourdomain.com`
- Test SSL certificate: `curl -I https://yourdomain.com`

### Authentication not working
- Verify .htpasswd file exists: `ls -l /etc/nginx/.htpasswd`
- Check nginx configuration: `sudo nginx -t`
- Review nginx error log

### Slow video playback
- Check network bandwidth
- Reduce video quality in browser
- Consider local caching
- Optimize nginx proxy settings

## Advanced Features

### Multi-User Support

To support multiple customers/vehicles:

1. **Create separate authentication per user:**
   ```bash
   sudo htpasswd /etc/nginx/.htpasswd customer2
   ```

2. **Organize videos by customer** (custom directory structure)

3. **Use subdirectories** in TeslaCam for different vehicles

### Mobile App Access

The web interface is mobile-responsive and works on:
- iOS Safari
- Android Chrome
- Mobile browsers with HTML5 video support

For best mobile experience:
- Use portrait mode for viewing
- Tap hamburger menu to switch between tabs
- Long-press videos for download options

## Cost Considerations

### Hardware Costs
- Raspberry Pi 4 (4GB+): $55-75
- MicroSD card (64GB+): $10-15
- Power supply: $8-10
- Case: $5-10
**Total: ~$80-110 per installation**

### Service Costs
- Domain name: $10-15/year
- Dynamic DNS (optional): $0-25/year
- VPN service (optional): $0-60/year
- SSL certificate: $0 (Let's Encrypt is free)

## Scaling for Multiple Customers

For deploying to multiple customers:

1. **Standardize Configuration**: Create template configuration files
2. **Automate Deployment**: Use Ansible or similar tools
3. **Central Management**: Consider cloud dashboard for monitoring multiple installations
4. **Documentation**: Provide customer-specific documentation with their unique access details

## Support and Updates

### Staying Updated

Monitor the TeslaUSB project for updates:
- GitHub: https://github.com/marcone/teslausb
- Check releases regularly
- Subscribe to project notifications

### Getting Help

- TeslaUSB Issues: https://github.com/marcone/teslausb/issues
- Community Forums: Reddit r/TeslaLounge, Tesla Motors Club
- Documentation: https://github.com/marcone/teslausb/tree/main-dev/doc

## Conclusion

This deployment guide provides multiple options for enabling customer access to Tesla Sentry and dashcam videos:

- **Simple local access** for home use
- **VPN access** for secure remote viewing
- **Direct internet access** for production deployments

Choose the option that best fits your security requirements, technical capabilities, and customer needs.

Remember: Security should be your top priority when exposing any service to the internet. Always use encryption, strong authentication, and keep your system updated.
