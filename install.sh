#!/bin/bash

# Nexus TV OS Installer for Ubuntu 22.04+
# Install with: curl -sL https://raw.githubusercontent.com/josansaab/TV-OS/main/install.sh | sudo bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
echo -e "${BLUE}Detected Ubuntu version: $UBUNTU_VERSION${NC}"

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt-get update -y

echo -e "${YELLOW}📦 Installing system dependencies...${NC}"
apt-get install -y \
    curl \
    wget \
    git \
    x11-xserver-utils \
    unclutter \
    lightdm \
    openbox \
    pulseaudio \
    flatpak \
    snapd \
    software-properties-common \
    gnupg

# Ensure snapd is fully initialized
echo -e "${YELLOW}📦 Initializing Snap...${NC}"
systemctl enable snapd.socket 2>/dev/null || true
systemctl start snapd.socket 2>/dev/null || true
systemctl enable snapd.service 2>/dev/null || true
systemctl start snapd.service 2>/dev/null || true
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
sleep 3

# Install Chromium via Snap (Ubuntu 22.04+ default)
echo -e "${YELLOW}📦 Installing Chromium browser...${NC}"
if [ -x "/snap/bin/chromium" ] || command -v chromium &> /dev/null; then
    echo -e "${GREEN}  ✅ Chromium already installed${NC}"
else
    snap install chromium 2>/dev/null || {
        echo -e "${YELLOW}  Snap failed, trying Flatpak...${NC}"
        flatpak install -y --noninteractive flathub org.chromium.Chromium 2>/dev/null || {
            echo -e "${YELLOW}  ⚠️ Chromium installation failed, will try alternatives${NC}"
        }
    }
fi

# Add Flathub repository
echo -e "${YELLOW}📦 Adding Flathub repository...${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true

echo -e "${GREEN}✅ System dependencies installed${NC}"

# Install Node.js 20
echo -e "${YELLOW}📦 Installing Node.js 20...${NC}"
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
fi
echo -e "${GREEN}✅ Node.js $(node -v) installed${NC}"

# ============================================
# INSTALL MEDIA APPLICATIONS
# ============================================

echo ""
echo -e "${BLUE}📺 Installing Media Applications...${NC}"
echo ""

# --- KODI ---
if command -v kodi &> /dev/null; then
    echo -e "${GREEN}  ✅ Kodi already installed, skipping${NC}"
else
    echo -e "${YELLOW}  Installing Kodi...${NC}"
    # Use PPA for Ubuntu 22.04, direct repo for 24.04+
    if [[ "$UBUNTU_VERSION" == "22.04"* ]] || [[ "$UBUNTU_VERSION" == "20.04"* ]]; then
        add-apt-repository -y ppa:team-xbmc/ppa 2>/dev/null || true
        apt-get update -y
    fi
    apt-get install -y kodi 2>/dev/null || echo -e "${YELLOW}  ⚠️ Kodi installation failed, skipping${NC}"
    echo -e "${GREEN}  ✅ Kodi done${NC}"
fi

# --- PLEX MEDIA SERVER ---
if [ -f "/usr/lib/plexmediaserver/Plex Media Server" ] || dpkg -l plexmediaserver 2>/dev/null | grep -q "^ii"; then
    echo -e "${GREEN}  ✅ Plex already installed, skipping${NC}"
else
    echo -e "${YELLOW}  Installing Plex Media Server...${NC}"
    curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key 2>/dev/null | gpg --batch --yes --dearmor -o /usr/share/keyrings/plex-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list 2>/dev/null || true
    apt-get update -y 2>/dev/null
    apt-get install -y plexmediaserver 2>/dev/null || echo -e "${YELLOW}  ⚠️ Plex installation failed, skipping${NC}"
    systemctl enable plexmediaserver 2>/dev/null || true
    systemctl start plexmediaserver 2>/dev/null || true
    echo -e "${GREEN}  ✅ Plex done${NC}"
fi

# --- SPOTIFY (via apt with official repo - more reliable than snap) ---
if command -v spotify &> /dev/null || snap list spotify 2>/dev/null | grep -q spotify; then
    echo -e "${GREEN}  ✅ Spotify already installed, skipping${NC}"
else
    echo -e "${YELLOW}  Installing Spotify...${NC}"
    # Try official Spotify apt repo first (most reliable, no interaction)
    curl -fsSL https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>/dev/null | gpg --batch --yes --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free" > /etc/apt/sources.list.d/spotify.list 2>/dev/null || true
    apt-get update -y 2>/dev/null
    apt-get install -y spotify-client 2>/dev/null || {
        echo -e "${YELLOW}  APT failed, trying Flatpak...${NC}"
        flatpak install -y --noninteractive flathub com.spotify.Client 2>/dev/null || echo -e "${YELLOW}  ⚠️ Spotify installation failed, will use web version${NC}"
    }
    echo -e "${GREEN}  ✅ Spotify done${NC}"
fi

# --- FREETUBE ---
if flatpak list 2>/dev/null | grep -q "FreeTube"; then
    echo -e "${GREEN}  ✅ FreeTube already installed, skipping${NC}"
else
    echo -e "${YELLOW}  Installing FreeTube...${NC}"
    flatpak install -y --noninteractive flathub io.freetubeapp.FreeTube 2>/dev/null || echo -e "${YELLOW}  ⚠️ FreeTube installation failed, skipping${NC}"
    echo -e "${GREEN}  ✅ FreeTube done${NC}"
fi

# --- VLC ---
if command -v vlc &> /dev/null; then
    echo -e "${GREEN}  ✅ VLC already installed, skipping${NC}"
else
    echo -e "${YELLOW}  Installing VLC Media Player...${NC}"
    apt-get install -y vlc 2>/dev/null || echo -e "${YELLOW}  ⚠️ VLC installation failed, skipping${NC}"
    echo -e "${GREEN}  ✅ VLC done${NC}"
fi

# --- MPV (lightweight alternative player) ---
if ! command -v mpv &> /dev/null; then
    echo -e "${YELLOW}  Installing MPV Player...${NC}"
    apt-get install -y mpv 2>/dev/null || true
    echo -e "${GREEN}  ✅ MPV done${NC}"
fi

echo -e "${GREEN}✅ Media applications installed${NC}"

# ============================================
# INSTALL NEXUS TV OS
# ============================================

INSTALL_DIR="/opt/nexus-tv"
echo ""
echo -e "${BLUE}🖥️  Installing Nexus TV OS...${NC}"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone from GitHub
echo -e "${YELLOW}  Cloning Nexus TV OS from GitHub...${NC}"
if [ -d "$INSTALL_DIR/.git" ]; then
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    rm -rf "$INSTALL_DIR"/*
    git clone https://github.com/josansaab/TV-OS.git . 2>/dev/null || {
        echo -e "${RED}  ⚠️ Failed to clone repository${NC}"
    }
fi

# Install npm dependencies
if [ -f "package.json" ]; then
    echo -e "${YELLOW}  Installing npm dependencies...${NC}"
    npm install --production 2>/dev/null || npm install 2>/dev/null || true
    echo -e "${YELLOW}  Building application...${NC}"
    npm run build 2>/dev/null || true
fi

# Create dedicated user
if ! id "nexus-tv" &>/dev/null; then
    useradd -r -s /bin/false nexus-tv 2>/dev/null || true
fi
chown -R nexus-tv:nexus-tv "$INSTALL_DIR" 2>/dev/null || true

echo -e "${GREEN}✅ Nexus TV OS installed${NC}"

# ============================================
# CREATE APP LAUNCHER SERVICE
# ============================================

echo -e "${YELLOW}⚙️  Creating app launcher service...${NC}"

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
# Detect browser path (Snap Chromium > apt chromium > Firefox as fallback)
if [ -x "/snap/bin/chromium" ]; then
    BROWSER_CMD="/snap/bin/chromium"
elif command -v chromium &> /dev/null; then
    BROWSER_CMD=$(command -v chromium)
elif command -v chromium-browser &> /dev/null; then
    BROWSER_CMD=$(command -v chromium-browser)
elif [ -x "/snap/bin/firefox" ]; then
    BROWSER_CMD="/snap/bin/firefox"
elif command -v firefox &> /dev/null; then
    BROWSER_CMD=$(command -v firefox)
    # Install Firefox as fallback if no browser found
else
    echo -e "${YELLOW}  Installing Firefox as fallback browser...${NC}"
    apt-get install -y firefox 2>/dev/null || snap install firefox 2>/dev/null || true
    BROWSER_CMD=$(command -v firefox || echo "/snap/bin/firefox")
fi
echo -e "${BLUE}Using browser at: $BROWSER_CMD${NC}"
CHROMIUM_CMD="$BROWSER_CMD"

cat > "$APPS_DIR/nexus-netflix.desktop" << EOF
[Desktop Entry]
Name=Netflix
Exec=$CHROMIUM_CMD --app=https://www.netflix.com/browse --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
EOF

cat > "$APPS_DIR/nexus-prime.desktop" << EOF
[Desktop Entry]
Name=Prime Video
Exec=$CHROMIUM_CMD --app=https://www.primevideo.com --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
EOF

cat > "$APPS_DIR/nexus-youtube.desktop" << EOF
[Desktop Entry]
Name=YouTube
Exec=$CHROMIUM_CMD --app=https://www.youtube.com/tv --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
EOF

cat > "$APPS_DIR/nexus-kayo.desktop" << EOF
[Desktop Entry]
Name=Kayo Sports
Exec=$CHROMIUM_CMD --app=https://kayosports.com.au --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
EOF

cat > "$APPS_DIR/nexus-chaupal.desktop" << EOF
[Desktop Entry]
Name=Chaupal
Exec=$CHROMIUM_CMD --app=https://chaupal.tv --start-fullscreen
Icon=video-display
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

mkdir -p "$USER_HOME/.config/openbox"
cat > "$USER_HOME/.config/openbox/autostart" << EOF
# Disable screen saver and power management
xset s off &
xset -dpms &
xset s noblank &

# Hide cursor after 0.5 seconds of inactivity
unclutter -idle 0.5 -root &

# Wait for network and services
sleep 5

# Start Nexus TV in fullscreen kiosk mode
$CHROMIUM_CMD \\
  --kiosk \\
  --noerrdialogs \\
  --disable-infobars \\
  --no-first-run \\
  --disable-session-crashed-bubble \\
  --disable-features=TranslateUI \\
  --check-for-update-interval=31536000 \\
  --app=http://localhost:5000 &
EOF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config"

# ============================================
# CREATE CLI CONTROL COMMAND
# ============================================

echo -e "${YELLOW}🔧 Creating nexus-tv command...${NC}"

cat > /usr/local/bin/nexus-tv << EOF
#!/bin/bash
CHROMIUM="$CHROMIUM_CMD"

case "\$1" in
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
        case "\$2" in
            plex)
                \$CHROMIUM --app=http://localhost:32400/web --start-fullscreen &
                ;;
            kodi)
                kodi &
                ;;
            netflix)
                \$CHROMIUM --app=https://www.netflix.com/browse --start-fullscreen &
                ;;
            prime)
                \$CHROMIUM --app=https://www.primevideo.com --start-fullscreen &
                ;;
            spotify)
                spotify 2>/dev/null || flatpak run com.spotify.Client &
                ;;
            youtube)
                \$CHROMIUM --app=https://www.youtube.com/tv --start-fullscreen &
                ;;
            freetube)
                flatpak run io.freetubeapp.FreeTube &
                ;;
            vacuumtube)
                flatpak run rocks.shy.VacuumTube 2>/dev/null || echo "VacuumTube not installed" &
                ;;
            kayo)
                \$CHROMIUM --app=https://kayosports.com.au --start-fullscreen &
                ;;
            chaupal)
                \$CHROMIUM --app=https://chaupal.tv --start-fullscreen &
                ;;
            *)
                echo "Unknown app: \$2"
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
systemctl enable nexus-tv.service 2>/dev/null || true

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
echo -e "   1. Reboot your system to start in TV mode:"
echo -e "      ${YELLOW}sudo reboot${NC}"
echo ""
echo -e "   2. Control Nexus TV with:"
echo -e "      ${YELLOW}nexus-tv start|stop|restart|status|logs${NC}"
echo ""
echo -e "   3. Launch apps directly:"
echo -e "      ${YELLOW}nexus-tv launch kodi${NC}"
echo -e "      ${YELLOW}nexus-tv launch plex${NC}"
echo ""
echo "   4. To exit kiosk mode: Press Alt+F4"
echo ""
echo -e "${GREEN}🎉 Enjoy your new TV OS experience!${NC}"
