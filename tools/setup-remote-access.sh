#!/bin/bash
#
# TeslaUSB Remote Access Setup Script
#
# This script helps configure remote access to TeslaUSB for production deployments
# allowing customers to view their Tesla Sentry and dashcam videos from anywhere.
#
# Usage: sudo ./setup-remote-access.sh [method]
# Methods: tailscale, nginx, or interactive
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root. Use: sudo $0"
        exit 1
    fi
}

check_internet() {
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "No internet connection. Please connect to WiFi and try again."
        exit 1
    fi
}

print_banner() {
    echo "================================================"
    echo "  TeslaUSB Remote Access Setup"
    echo "  Enable customer video viewing from anywhere"
    echo "================================================"
    echo ""
}

show_menu() {
    echo "Choose remote access method:"
    echo ""
    echo "1) Tailscale VPN (Recommended)"
    echo "   - Easiest setup"
    echo "   - Free for personal use"
    echo "   - Secure encrypted access"
    echo "   - No port forwarding needed"
    echo ""
    echo "2) Nginx with SSL (Advanced)"
    echo "   - Direct internet access"
    echo "   - Requires domain name"
    echo "   - Requires port forwarding"
    echo "   - Best for professional deployments"
    echo ""
    echo "3) Show access information only"
    echo "   - Display current access URLs"
    echo "   - No configuration changes"
    echo ""
    echo "0) Exit"
    echo ""
    read -p "Enter choice [0-3]: " choice
    echo ""
    echo "$choice"
}

setup_tailscale() {
    log_info "Setting up Tailscale VPN access..."
    echo ""
    
    # Check if already installed
    if command -v tailscale &> /dev/null; then
        log_info "Tailscale is already installed"
        
        # Check if connected
        if tailscale status &> /dev/null; then
            log_info "Tailscale is already connected"
            tailscale status | head -5
            echo ""
            TAILSCALE_HOSTNAME=$(tailscale status --json | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 | head -1)
            log_info "Your Tailscale hostname: ${GREEN}${TAILSCALE_HOSTNAME}${NC}"
            log_info "Access TeslaUSB at: ${GREEN}http://${TAILSCALE_HOSTNAME}${NC}"
            echo ""
            read -p "Do you want to reconnect Tailscale? [y/N]: " reconnect
            if [[ ! $reconnect =~ ^[Yy]$ ]]; then
                return 0
            fi
        fi
    else
        log_info "Installing Tailscale..."
        curl -fsSL https://tailscale.com/install.sh | sh
    fi
    
    echo ""
    log_info "Connecting to Tailscale network..."
    log_warn "A browser window will open for authentication"
    echo ""
    
    tailscale up
    
    echo ""
    log_info "✓ Tailscale setup complete!"
    echo ""
    
    # Get and display the hostname
    sleep 2
    TAILSCALE_HOSTNAME=$(tailscale status --json 2>/dev/null | grep -o '"HostName":"[^"]*"' | cut -d'"' -f4 | head -1)
    
    if [ -z "$TAILSCALE_HOSTNAME" ]; then
        TAILSCALE_HOSTNAME=$(tailscale status | grep -o '[a-z0-9-]*\.tail[a-z0-9]*\.ts\.net' | head -1)
    fi
    
    if [ -n "$TAILSCALE_HOSTNAME" ]; then
        echo "================================================"
        echo "  CUSTOMER ACCESS INFORMATION"
        echo "================================================"
        echo ""
        echo "Share this information with your customer:"
        echo ""
        echo "1. Install Tailscale app on your device:"
        echo "   - iPhone/iPad: App Store"
        echo "   - Android: Google Play"
        echo "   - Computer: https://tailscale.com/download"
        echo ""
        echo "2. Sign in with Google/Microsoft/GitHub"
        echo ""
        echo "3. Access TeslaUSB at:"
        echo "   ${GREEN}http://${TAILSCALE_HOSTNAME}${NC}"
        echo ""
        echo "================================================"
        echo ""
        
        # Save to file
        cat > /boot/tailscale_access_info.txt <<EOF
TeslaUSB Remote Access Information
Generated: $(date)

Access URL: http://${TAILSCALE_HOSTNAME}

Customer Instructions:
1. Install Tailscale app from App Store or Google Play
2. Sign in with the same account used during setup
3. Connect to Tailscale network
4. Open browser and go to: http://${TAILSCALE_HOSTNAME}

For help: See doc/CustomerQuickStart.md
EOF
        log_info "Access information saved to: /boot/tailscale_access_info.txt"
    else
        log_warn "Could not determine Tailscale hostname"
        log_info "Run 'tailscale status' to see connection information"
    fi
    
    echo ""
}

setup_nginx() {
    log_info "Setting up Nginx with SSL..."
    echo ""
    
    # Check prerequisites
    log_warn "This requires:"
    echo "  - A domain name pointing to your public IP"
    echo "  - Port 80 and 443 forwarded to this Pi"
    echo "  - Valid email for Let's Encrypt"
    echo ""
    
    read -p "Have you configured the above? [y/N]: " configured
    if [[ ! $configured =~ ^[Yy]$ ]]; then
        log_warn "Please configure prerequisites first"
        log_info "See doc/ProductionDeployment.md for detailed instructions"
        return 1
    fi
    
    # Get domain name
    read -p "Enter your domain name (e.g., myteslavideos.com): " domain
    if [ -z "$domain" ]; then
        log_error "Domain name is required"
        return 1
    fi
    
    # Get email
    read -p "Enter your email for Let's Encrypt notifications: " email
    if [ -z "$email" ]; then
        log_error "Email is required"
        return 1
    fi
    
    log_info "Installing Nginx and Certbot..."
    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx apache2-utils
    
    # Create basic auth
    log_info "Setting up password protection..."
    read -p "Enter username for web access: " webuser
    if [ -z "$webuser" ]; then
        webuser="customer"
    fi
    
    htpasswd -c /etc/nginx/.htpasswd "$webuser"
    
    # Create nginx config
    log_info "Creating Nginx configuration..."
    cat > /etc/nginx/sites-available/teslausb <<EOF
server {
    listen 80;
    server_name $domain;
    
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name $domain;
    
    # SSL configuration (will be managed by certbot)
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Basic authentication
    auth_basic "Tesla Dashcam Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
    }
    
    location ~* \.(mp4|webm)$ {
        proxy_pass http://localhost:80;
        proxy_buffering off;
        add_header Cache-Control "public, max-age=3600";
    }
}
EOF
    
    # Enable site
    ln -sf /etc/nginx/sites-available/teslausb /etc/nginx/sites-enabled/
    
    # Test config
    nginx -t
    
    log_info "Obtaining SSL certificate..."
    certbot --nginx -d "$domain" --email "$email" --agree-tos --non-interactive
    
    # Reload nginx
    systemctl reload nginx
    
    log_info "✓ Nginx setup complete!"
    echo ""
    echo "================================================"
    echo "  CUSTOMER ACCESS INFORMATION"
    echo "================================================"
    echo ""
    echo "Access URL: ${GREEN}https://$domain${NC}"
    echo "Username: $webuser"
    echo "Password: (as set above)"
    echo ""
    echo "================================================"
    echo ""
}

show_access_info() {
    log_info "Current TeslaUSB access information:"
    echo ""
    
    # Local access
    echo "Local Access (same WiFi network):"
    echo "  http://teslausb.local"
    LOCALIP=$(hostname -I | awk '{print $1}')
    echo "  http://$LOCALIP"
    echo ""
    
    # Tailscale
    if command -v tailscale &> /dev/null; then
        if tailscale status &> /dev/null; then
            TAILSCALE_HOSTNAME=$(tailscale status | grep -o '[a-z0-9-]*\.tail[a-z0-9]*\.ts\.net' | head -1)
            if [ -n "$TAILSCALE_HOSTNAME" ]; then
                echo "Tailscale VPN Access:"
                echo "  http://${TAILSCALE_HOSTNAME}"
                echo ""
            fi
        else
            echo "Tailscale: Installed but not connected"
            echo ""
        fi
    fi
    
    # Nginx
    if systemctl is-active --quiet nginx; then
        echo "Nginx: Running"
        if [ -f /etc/nginx/sites-enabled/teslausb ]; then
            DOMAIN=$(grep server_name /etc/nginx/sites-enabled/teslausb | head -2 | tail -1 | awk '{print $2}' | tr -d ';')
            if [ -n "$DOMAIN" ]; then
                echo "Public Access: https://$DOMAIN"
            fi
        fi
        echo ""
    fi
    
    log_info "For customer instructions, see: doc/CustomerQuickStart.md"
    echo ""
}

# Main script
check_root
check_internet
print_banner

# Get method from command line or show menu
METHOD="${1:-interactive}"

if [ "$METHOD" = "tailscale" ]; then
    setup_tailscale
elif [ "$METHOD" = "nginx" ]; then
    setup_nginx
elif [ "$METHOD" = "info" ]; then
    show_access_info
else
    # Interactive menu
    while true; do
        choice=$(show_menu)
        case $choice in
            1)
                setup_tailscale
                break
                ;;
            2)
                setup_nginx
                break
                ;;
            3)
                show_access_info
                break
                ;;
            0)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice"
                ;;
        esac
    done
fi

echo ""
log_info "Setup complete! Test access from customer device."
log_info "For customer documentation, see: doc/CustomerQuickStart.md"
echo ""
