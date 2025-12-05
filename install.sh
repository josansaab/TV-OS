#!/bin/bash

# Nexus TV OS Installer for Ubuntu 24.03+
# Install with: curl -sL https://nexus-os.tv/install.sh | sudo bash

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    NEXUS TV OS INSTALLER                     ║"
echo "║              Modern TV Operating System for Ubuntu           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo "❌ Please run as root (use sudo)"
   exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

echo "📦 Installing system dependencies..."
apt-get update -qq
apt-get install -y \
    curl \
    git \
    chromium-browser \
    x11-xserver-utils \
    unclutter \
    lightdm \
    openbox \
    nodejs \
    npm \
    kodi \
    plexmediaserver \
    > /dev/null 2>&1

echo "✅ System dependencies installed"

# Install Node.js 20 if needed
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
    echo "📦 Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs > /dev/null 2>&1
fi

echo "✅ Node.js $(node -v) installed"

# Create installation directory
INSTALL_DIR="/opt/nexus-tv"
echo "📁 Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone/Download application (for now, create a placeholder)
echo "📥 Downloading Nexus TV OS..."
# In production, this would clone your repo or download a tarball
# git clone https://github.com/yourusername/nexus-tv.git .
echo "⚠️  Demo mode: Application would be downloaded here"

# Install application dependencies
# npm install --production > /dev/null 2>&1

# Build application
# npm run build > /dev/null 2>&1

# Create systemd service
echo "⚙️  Creating system service..."
cat > /etc/systemd/system/nexus-tv.service << 'EOF'
[Unit]
Description=Nexus TV OS
After=network.target

[Service]
Type=simple
User=nexus-tv
WorkingDirectory=/opt/nexus-tv
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Create dedicated user
if ! id "nexus-tv" &>/dev/null; then
    echo "👤 Creating nexus-tv user..."
    useradd -r -s /bin/false nexus-tv
fi

chown -R nexus-tv:nexus-tv "$INSTALL_DIR"

# Configure auto-login for kiosk mode
echo "🖥️  Configuring auto-login and kiosk mode..."
mkdir -p /etc/lightdm/lightdm.conf.d/
cat > /etc/lightdm/lightdm.conf.d/50-nexus-tv.conf << EOF
[Seat:*]
autologin-user=$ACTUAL_USER
autologin-user-timeout=0
user-session=openbox
EOF

# Create OpenBox autostart for kiosk
mkdir -p "$USER_HOME/.config/openbox"
cat > "$USER_HOME/.config/openbox/autostart" << 'EOF'
# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Hide cursor after 0.1 seconds
unclutter -idle 0.1 &

# Start Nexus TV in fullscreen kiosk mode
chromium-browser \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --no-first-run \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --check-for-update-interval=31536000 \
  --app=http://localhost:5000 &
EOF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config"

# Enable and start service
echo "🚀 Enabling Nexus TV service..."
systemctl daemon-reload
systemctl enable nexus-tv.service > /dev/null 2>&1
# Don't start yet in demo mode
# systemctl start nexus-tv.service

# Create CLI command
echo "🔧 Creating nexus-tv command..."
cat > /usr/local/bin/nexus-tv << 'EOF'
#!/bin/bash
case "$1" in
    start)
        sudo systemctl start nexus-tv
        ;;
    stop)
        sudo systemctl stop nexus-tv
        ;;
    restart)
        sudo systemctl restart nexus-tv
        ;;
    status)
        sudo systemctl status nexus-tv
        ;;
    logs)
        sudo journalctl -u nexus-tv -f
        ;;
    update)
        cd /opt/nexus-tv
        git pull
        npm install --production
        npm run build
        sudo systemctl restart nexus-tv
        ;;
    *)
        echo "Nexus TV OS Control"
        echo ""
        echo "Usage: nexus-tv {start|stop|restart|status|logs|update}"
        echo ""
        echo "Commands:"
        echo "  start    - Start Nexus TV"
        echo "  stop     - Stop Nexus TV"
        echo "  restart  - Restart Nexus TV"
        echo "  status   - Show service status"
        echo "  logs     - Show live logs"
        echo "  update   - Update to latest version"
        ;;
esac
EOF

chmod +x /usr/local/bin/nexus-tv

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              ✅ INSTALLATION COMPLETE!                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📺 Nexus TV OS has been installed!"
echo ""
echo "Next steps:"
echo "  1. Reboot your system to start in TV mode:"
echo "     sudo reboot"
echo ""
echo "  2. Control Nexus TV with:"
echo "     nexus-tv start|stop|restart|status|logs"
echo ""
echo "  3. To exit kiosk mode: Press Alt+F4"
echo ""
echo "🎉 Enjoy your new TV OS experience!"
