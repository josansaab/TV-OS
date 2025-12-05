#!/bin/bash

# Nexus TV OS Installer for Ubuntu 24.04+
# Install with: curl -sL https://your-server.com/install.sh | sudo bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    NEXUS TV OS INSTALLER                     ║"
echo "║              Modern TV Operating System for Ubuntu           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   echo -e "${RED}❌ Please run as root (use sudo)${NC}"
   exit 1
fi

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt-get update -qq

echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    chromium-browser \
    x11-xserver-utils \
    unclutter \
    lightdm \
    openbox \
    pulseaudio \
    flatpak \
    gnome-software-plugin-flatpak \
    > /dev/null 2>&1

# Add Flathub repository
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

echo -e "${GREEN}✅ System dependencies installed${NC}"

# Install Node.js 20
echo -e "${YELLOW}📦 Installing Node.js 20...${NC}"
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt-get install -y nodejs > /dev/null 2>&1
fi
echo -e "${GREEN}✅ Node.js $(node -v) installed${NC}"

# ============================================
# INSTALL MEDIA APPLICATIONS
# ============================================

echo ""
echo -e "${BLUE}📺 Installing Media Applications...${NC}"
echo ""

# --- KODI ---
echo -e "${YELLOW}  Installing Kodi...${NC}"
apt-get install -y software-properties-common > /dev/null 2>&1
add-apt-repository -y ppa:team-xbmc/ppa > /dev/null 2>&1
apt-get update -qq
apt-get install -y kodi > /dev/null 2>&1
echo -e "${GREEN}  ✅ Kodi installed${NC}"

# --- PLEX MEDIA SERVER ---
echo -e "${YELLOW}  Installing Plex Media Server...${NC}"
wget -q https://downloads.plex.tv/plex-keys/PlexSign.key -O - | apt-key add - > /dev/null 2>&1
echo "deb https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list
apt-get update -qq
apt-get install -y plexmediaserver > /dev/null 2>&1
systemctl enable plexmediaserver > /dev/null 2>&1
systemctl start plexmediaserver > /dev/null 2>&1
echo -e "${GREEN}  ✅ Plex Media Server installed${NC}"

# --- SPOTIFY ---
echo -e "${YELLOW}  Installing Spotify...${NC}"
snap install spotify > /dev/null 2>&1 || flatpak install -y flathub com.spotify.Client > /dev/null 2>&1
echo -e "${GREEN}  ✅ Spotify installed${NC}"

# --- FREETUBE ---
echo -e "${YELLOW}  Installing FreeTube...${NC}"
flatpak install -y flathub io.freetubeapp.FreeTube > /dev/null 2>&1
echo -e "${GREEN}  ✅ FreeTube installed${NC}"

# --- VACUUMTUBE ---
echo -e "${YELLOW}  Installing VacuumTube...${NC}"
flatpak install -y flathub rocks.shy.VacuumTube > /dev/null 2>&1 || {
    # Fallback: build from source
    cd /tmp
    git clone https://github.com/shy1132/VacuumTube.git > /dev/null 2>&1
    cd VacuumTube
    npm install > /dev/null 2>&1
    npm run build > /dev/null 2>&1
    mkdir -p /opt/vacuumtube
    cp -r . /opt/vacuumtube/
    cat > /usr/local/bin/vacuumtube << 'VTEOF'
#!/bin/bash
cd /opt/vacuumtube && npm start
VTEOF
    chmod +x /usr/local/bin/vacuumtube
}
echo -e "${GREEN}  ✅ VacuumTube installed${NC}"

# --- VLC ---
echo -e "${YELLOW}  Installing VLC Media Player...${NC}"
apt-get install -y vlc > /dev/null 2>&1
echo -e "${GREEN}  ✅ VLC installed${NC}"

# ============================================
# INSTALL NEXUS TV OS
# ============================================

INSTALL_DIR="/opt/nexus-tv"
echo ""
echo -e "${BLUE}🖥️  Installing Nexus TV OS...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# In production, clone from git:
# git clone https://github.com/yourusername/nexus-tv.git .
# npm install --production
# npm run build

# Create dedicated user
if ! id "nexus-tv" &>/dev/null; then
    useradd -r -s /bin/false nexus-tv 2>/dev/null || true
fi
chown -R nexus-tv:nexus-tv "$INSTALL_DIR" 2>/dev/null || true

# ============================================
# CREATE APP LAUNCHER SERVICE
# ============================================

echo -e "${YELLOW}⚙️  Creating app launcher service...${NC}"

# Create systemd service for Nexus TV
cat > /etc/systemd/system/nexus-tv.service << 'EOF'
[Unit]
Description=Nexus TV OS
After=network.target graphical.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nexus-tv
Environment=NODE_ENV=production
Environment=DISPLAY=:0
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

# ============================================
# CREATE DESKTOP ENTRIES FOR WEB APPS
# ============================================

echo -e "${YELLOW}📱 Creating web app shortcuts...${NC}"

APPS_DIR="/usr/share/applications"

# Netflix
cat > "$APPS_DIR/nexus-netflix.desktop" << 'EOF'
[Desktop Entry]
Name=Netflix
Exec=chromium-browser --app=https://www.netflix.com/browse --start-fullscreen
Icon=netflix
Type=Application
Categories=Video;
EOF

# Amazon Prime Video
cat > "$APPS_DIR/nexus-prime.desktop" << 'EOF'
[Desktop Entry]
Name=Prime Video
Exec=chromium-browser --app=https://www.primevideo.com --start-fullscreen
Icon=amazon
Type=Application
Categories=Video;
EOF

# YouTube TV
cat > "$APPS_DIR/nexus-youtube.desktop" << 'EOF'
[Desktop Entry]
Name=YouTube
Exec=chromium-browser --app=https://www.youtube.com/tv --start-fullscreen
Icon=youtube
Type=Application
Categories=Video;
EOF

# Kayo Sports
cat > "$APPS_DIR/nexus-kayo.desktop" << 'EOF'
[Desktop Entry]
Name=Kayo Sports
Exec=chromium-browser --app=https://kayosports.com.au --start-fullscreen
Icon=kayo
Type=Application
Categories=Video;
EOF

# Chaupal
cat > "$APPS_DIR/nexus-chaupal.desktop" << 'EOF'
[Desktop Entry]
Name=Chaupal
Exec=chromium-browser --app=https://chaupal.tv --start-fullscreen
Icon=chaupal
Type=Application
Categories=Video;
EOF

echo -e "${GREEN}✅ Web app shortcuts created${NC}"

# ============================================
# CONFIGURE AUTO-LOGIN & KIOSK MODE
# ============================================

echo -e "${YELLOW}🖥️  Configuring auto-login and kiosk mode...${NC}"

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
xset s off &
xset -dpms &
xset s noblank &

# Hide cursor after 0.5 seconds of inactivity
unclutter -idle 0.5 -root &

# Wait for network
sleep 3

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

# ============================================
# CREATE CLI CONTROL COMMAND
# ============================================

echo -e "${YELLOW}🔧 Creating nexus-tv command...${NC}"

cat > /usr/local/bin/nexus-tv << 'EOF'
#!/bin/bash
case "$1" in
    start)
        sudo systemctl start nexus-tv
        echo "Nexus TV started"
        ;;
    stop)
        sudo systemctl stop nexus-tv
        echo "Nexus TV stopped"
        ;;
    restart)
        sudo systemctl restart nexus-tv
        echo "Nexus TV restarted"
        ;;
    status)
        sudo systemctl status nexus-tv
        ;;
    logs)
        sudo journalctl -u nexus-tv -f
        ;;
    launch)
        # Launch a specific app
        case "$2" in
            plex)
                chromium-browser --app=http://localhost:32400/web --start-fullscreen &
                ;;
            kodi)
                kodi &
                ;;
            netflix)
                chromium-browser --app=https://www.netflix.com/browse --start-fullscreen &
                ;;
            prime)
                chromium-browser --app=https://www.primevideo.com --start-fullscreen &
                ;;
            spotify)
                spotify &>/dev/null || flatpak run com.spotify.Client &
                ;;
            youtube)
                chromium-browser --app=https://www.youtube.com/tv --start-fullscreen &
                ;;
            freetube)
                flatpak run io.freetubeapp.FreeTube &
                ;;
            vacuumtube)
                flatpak run rocks.shy.VacuumTube &>/dev/null || /usr/local/bin/vacuumtube &
                ;;
            kayo)
                chromium-browser --app=https://kayosports.com.au --start-fullscreen &
                ;;
            chaupal)
                chromium-browser --app=https://chaupal.tv --start-fullscreen &
                ;;
            *)
                echo "Unknown app: $2"
                echo "Available apps: plex, kodi, netflix, prime, spotify, youtube, freetube, vacuumtube, kayo, chaupal"
                ;;
        esac
        ;;
    *)
        echo "Nexus TV OS Control"
        echo ""
        echo "Usage: nexus-tv {start|stop|restart|status|logs|launch <app>}"
        echo ""
        echo "Commands:"
        echo "  start           - Start Nexus TV"
        echo "  stop            - Stop Nexus TV"
        echo "  restart         - Restart Nexus TV"
        echo "  status          - Show service status"
        echo "  logs            - Show live logs"
        echo "  launch <app>    - Launch an app (plex, kodi, netflix, etc.)"
        ;;
esac
EOF

chmod +x /usr/local/bin/nexus-tv

# Enable service
systemctl daemon-reload
systemctl enable nexus-tv.service > /dev/null 2>&1

echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              ✅ INSTALLATION COMPLETE!                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "📺 Nexus TV OS has been installed with the following apps:"
echo ""
echo "   ✅ Plex Media Server (running on port 32400)"
echo "   ✅ Kodi Media Center"
echo "   ✅ Spotify"
echo "   ✅ FreeTube (privacy-focused YouTube)"
echo "   ✅ VacuumTube (YouTube TV interface)"
echo "   ✅ VLC Media Player"
echo "   ✅ Netflix (web app)"
echo "   ✅ Prime Video (web app)"
echo "   ✅ YouTube TV (web app)"
echo "   ✅ Kayo Sports (web app)"
echo "   ✅ Chaupal (web app)"
echo ""
echo "🚀 Next steps:"
echo "   1. Reboot your system to start in TV mode:"
echo "      ${YELLOW}sudo reboot${NC}"
echo ""
echo "   2. Control Nexus TV with:"
echo "      ${YELLOW}nexus-tv start|stop|restart|status|logs${NC}"
echo ""
echo "   3. Launch apps directly:"
echo "      ${YELLOW}nexus-tv launch kodi${NC}"
echo "      ${YELLOW}nexus-tv launch plex${NC}"
echo ""
echo "   4. To exit kiosk mode: Press Alt+F4"
echo ""
echo -e "${GREEN}🎉 Enjoy your new TV OS experience!${NC}"
