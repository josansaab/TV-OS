#!/bin/bash

# Nexus TV OS Installer for Ubuntu 22.04+
# Install with: curl -sL https://raw.githubusercontent.com/josansaab/TV-OS/main/install.sh | sudo bash

set -e

# Simple logging without colors (works better with curl pipe)
log_info() { echo "[INFO] $1"; }
log_ok() { echo "[OK] $1"; }
log_warn() { echo "[WARN] $1"; }
log_err() { echo "[ERROR] $1"; }

echo ""
echo "=============================================="
echo "        NEXUS TV OS INSTALLER"
echo "   Modern TV Operating System for Ubuntu"
echo "=============================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
   log_err "Please run as root (use sudo)"
   exit 1
fi

# Detect Ubuntu version
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "22.04")
log_info "Detected Ubuntu version: $UBUNTU_VERSION"

# Get the actual user who invoked sudo
ACTUAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

log_info "Updating system packages..."
apt-get update -y -qq

log_info "Installing system dependencies..."
apt-get install -y -qq \
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
    gnupg \
    firefox

log_ok "System dependencies installed"

# Ensure snapd is fully initialized
log_info "Initializing Snap..."
systemctl enable snapd.socket 2>/dev/null || true
systemctl start snapd.socket 2>/dev/null || true
systemctl enable snapd.service 2>/dev/null || true
systemctl start snapd.service 2>/dev/null || true
ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
sleep 5

# Install Chromium via Snap
log_info "Installing Chromium browser..."
if [ -x "/snap/bin/chromium" ] || command -v chromium &> /dev/null; then
    log_ok "Chromium already installed"
else
    snap install chromium 2>&1 || log_warn "Chromium snap failed, will use Firefox"
fi

# Add Flathub repository
log_info "Adding Flathub repository..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

log_ok "System dependencies installed"

# Install Node.js 20
log_info "Installing Node.js 20..."
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 20 ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x 2>/dev/null | bash - 2>/dev/null
    apt-get install -y -qq nodejs
fi
log_ok "Node.js $(node -v) installed"

# ============================================
# INSTALL MEDIA APPLICATIONS
# ============================================

echo ""
log_info "Installing Media Applications..."
echo ""

# --- KODI ---
if command -v kodi &> /dev/null; then
    log_ok "Kodi already installed"
else
    log_info "Installing Kodi..."
    if [[ "$UBUNTU_VERSION" == "22.04"* ]] || [[ "$UBUNTU_VERSION" == "20.04"* ]]; then
        add-apt-repository -y ppa:team-xbmc/ppa 2>/dev/null || true
        apt-get update -y -qq
    fi
    apt-get install -y -qq kodi 2>/dev/null || log_warn "Kodi installation failed"
    log_ok "Kodi done"
fi

# --- PLEX MEDIA SERVER ---
if [ -f "/usr/lib/plexmediaserver/Plex Media Server" ] || dpkg -l plexmediaserver 2>/dev/null | grep -q "^ii"; then
    log_ok "Plex already installed"
else
    log_info "Installing Plex Media Server..."
    curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key 2>/dev/null | gpg --batch --yes --dearmor -o /usr/share/keyrings/plex-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" > /etc/apt/sources.list.d/plexmediaserver.list 2>/dev/null || true
    apt-get update -y -qq 2>/dev/null
    apt-get install -y -qq plexmediaserver 2>/dev/null || log_warn "Plex installation failed"
    systemctl enable plexmediaserver 2>/dev/null || true
    systemctl start plexmediaserver 2>/dev/null || true
    log_ok "Plex done"
fi

# --- SPOTIFY ---
if command -v spotify &> /dev/null || [ -f "/snap/bin/spotify" ]; then
    log_ok "Spotify already installed"
else
    log_info "Installing Spotify..."
    curl -fsSL https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg 2>/dev/null | gpg --batch --yes --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg 2>/dev/null || true
    echo "deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free" > /etc/apt/sources.list.d/spotify.list 2>/dev/null || true
    apt-get update -y -qq 2>/dev/null
    apt-get install -y -qq spotify-client 2>/dev/null || {
        log_warn "Spotify APT failed, trying Flatpak..."
        flatpak install -y --noninteractive flathub com.spotify.Client 2>/dev/null || log_warn "Spotify installation failed, will use web version"
    }
    log_ok "Spotify done"
fi

# --- FREETUBE ---
if flatpak list 2>/dev/null | grep -q "FreeTube"; then
    log_ok "FreeTube already installed"
else
    log_info "Installing FreeTube..."
    flatpak install -y --noninteractive flathub io.freetubeapp.FreeTube 2>/dev/null || log_warn "FreeTube installation failed"
    log_ok "FreeTube done"
fi

# --- VLC ---
if command -v vlc &> /dev/null; then
    log_ok "VLC already installed"
else
    log_info "Installing VLC Media Player..."
    apt-get install -y -qq vlc 2>/dev/null || log_warn "VLC installation failed"
    log_ok "VLC done"
fi

# --- MPV ---
if ! command -v mpv &> /dev/null; then
    log_info "Installing MPV Player..."
    apt-get install -y -qq mpv 2>/dev/null || true
    log_ok "MPV done"
fi

log_ok "Media applications installed"

# ============================================
# INSTALL NEXUS TV OS
# ============================================

INSTALL_DIR="/opt/nexus-tv"
echo ""
log_info "Installing Nexus TV OS..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Clone from GitHub
log_info "Cloning Nexus TV OS from GitHub..."
if [ -d "$INSTALL_DIR/.git" ]; then
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
else
    rm -rf "$INSTALL_DIR"/* 2>/dev/null || true
    git clone https://github.com/josansaab/TV-OS.git . 2>/dev/null || {
        log_err "Failed to clone repository"
    }
fi

# Install npm dependencies
if [ -f "package.json" ]; then
    log_info "Installing npm dependencies..."
    npm install --production 2>/dev/null || npm install 2>/dev/null || true
    log_info "Building application..."
    npm run build 2>/dev/null || true
fi

# Create dedicated user
if ! id "nexus-tv" &>/dev/null; then
    useradd -r -s /bin/false nexus-tv 2>/dev/null || true
fi
chown -R nexus-tv:nexus-tv "$INSTALL_DIR" 2>/dev/null || true

log_ok "Nexus TV OS installed"

# ============================================
# CREATE APP LAUNCHER SERVICE
# ============================================

log_info "Creating app launcher service..."

cat > /etc/systemd/system/nexus-tv.service << 'SERVICEEOF'
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
SERVICEEOF

# ============================================
# CREATE DESKTOP ENTRIES FOR WEB APPS
# ============================================

log_info "Creating web app shortcuts..."

APPS_DIR="/usr/share/applications"

# Detect browser path
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
else
    BROWSER_CMD="/usr/bin/firefox"
fi
log_info "Using browser at: $BROWSER_CMD"

cat > "$APPS_DIR/nexus-netflix.desktop" << DESKTOPEOF
[Desktop Entry]
Name=Netflix
Exec=$BROWSER_CMD --app=https://www.netflix.com/browse --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
DESKTOPEOF

cat > "$APPS_DIR/nexus-prime.desktop" << DESKTOPEOF
[Desktop Entry]
Name=Prime Video
Exec=$BROWSER_CMD --app=https://www.primevideo.com --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
DESKTOPEOF

cat > "$APPS_DIR/nexus-youtube.desktop" << DESKTOPEOF
[Desktop Entry]
Name=YouTube
Exec=$BROWSER_CMD --app=https://www.youtube.com/tv --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
DESKTOPEOF

cat > "$APPS_DIR/nexus-kayo.desktop" << DESKTOPEOF
[Desktop Entry]
Name=Kayo Sports
Exec=$BROWSER_CMD --app=https://kayosports.com.au --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
DESKTOPEOF

cat > "$APPS_DIR/nexus-chaupal.desktop" << DESKTOPEOF
[Desktop Entry]
Name=Chaupal
Exec=$BROWSER_CMD --app=https://chaupal.tv --start-fullscreen
Icon=video-display
Type=Application
Categories=Video;
DESKTOPEOF

log_ok "Web app shortcuts created"

# ============================================
# CONFIGURE AUTO-LOGIN & KIOSK MODE
# ============================================

log_info "Configuring auto-login and kiosk mode..."

# Create Openbox session file if it doesn't exist
log_info "Creating Openbox session..."
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/openbox.desktop << SESSIONEOF
[Desktop Entry]
Name=Openbox
Comment=Log in using the Openbox window manager
Exec=/usr/bin/openbox-session
TryExec=/usr/bin/openbox-session
Type=Application
SESSIONEOF

# Detect which display manager is installed and configure accordingly
if systemctl is-enabled gdm3 2>/dev/null || [ -f "/etc/gdm3/custom.conf" ]; then
    # Ubuntu Desktop with GDM3 - configure gdm3 for autologin
    log_info "Configuring GDM3 for autologin..."
    
    # Backup existing config
    cp /etc/gdm3/custom.conf /etc/gdm3/custom.conf.backup 2>/dev/null || true
    
    cat > /etc/gdm3/custom.conf << GDMEOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$ACTUAL_USER

[security]

[xdmcp]

[chooser]

[debug]
GDMEOF

    log_ok "GDM3 autologin configured"
    
elif systemctl is-enabled lightdm 2>/dev/null || [ -f "/etc/lightdm/lightdm.conf" ]; then
    # LightDM is installed - configure it
    log_info "Configuring LightDM for autologin..."
    
    mkdir -p /etc/lightdm/lightdm.conf.d/
    cat > /etc/lightdm/lightdm.conf.d/50-nexus-tv.conf << LIGHTDMEOF
[Seat:*]
autologin-user=$ACTUAL_USER
autologin-user-timeout=0
user-session=openbox
LIGHTDMEOF

    groupadd -f autologin 2>/dev/null || true
    usermod -a -G autologin "$ACTUAL_USER" 2>/dev/null || true
    
    log_ok "LightDM autologin configured"
    
else
    # No display manager - install lightdm with greeter
    log_info "Installing LightDM display manager..."
    apt-get install -y -qq lightdm lightdm-gtk-greeter 2>/dev/null || true
    
    mkdir -p /etc/lightdm/lightdm.conf.d/
    cat > /etc/lightdm/lightdm.conf.d/50-nexus-tv.conf << LIGHTDMEOF
[Seat:*]
autologin-user=$ACTUAL_USER
autologin-user-timeout=0
user-session=openbox
greeter-session=lightdm-gtk-greeter
LIGHTDMEOF

    groupadd -f autologin 2>/dev/null || true
    usermod -a -G autologin "$ACTUAL_USER" 2>/dev/null || true
    systemctl enable lightdm 2>/dev/null || true
    systemctl set-default graphical.target
    
    log_ok "LightDM installed and configured"
fi

# Create user autostart for GNOME/GDM session (runs after login)
mkdir -p "$USER_HOME/.config/autostart"
cat > "$USER_HOME/.config/autostart/nexus-tv-kiosk.desktop" << AUTOSTARTEOF
[Desktop Entry]
Type=Application
Name=Nexus TV Kiosk
Exec=$USER_HOME/.config/nexus-tv/start-kiosk.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=3
AUTOSTARTEOF

# Create the kiosk startup script
mkdir -p "$USER_HOME/.config/nexus-tv"
cat > "$USER_HOME/.config/nexus-tv/start-kiosk.sh" << KIOSKEOF
#!/bin/bash

# Disable screen saver and power management
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Hide cursor after inactivity
unclutter -idle 0.5 -root 2>/dev/null &

# Start the Nexus TV backend service
sudo systemctl start nexus-tv 2>/dev/null &

# Wait for backend to be ready
sleep 5

# Start browser in fullscreen kiosk mode
$BROWSER_CMD \
  --kiosk \
  --noerrdialogs \
  --disable-infobars \
  --no-first-run \
  --disable-session-crashed-bubble \
  --disable-features=TranslateUI \
  --start-fullscreen \
  --app=http://localhost:5000 &
KIOSKEOF

chmod +x "$USER_HOME/.config/nexus-tv/start-kiosk.sh"

# Also create Openbox autostart for Openbox sessions
mkdir -p "$USER_HOME/.config/openbox"
cat > "$USER_HOME/.config/openbox/autostart" << OPENBOXEOF
#!/bin/bash
$USER_HOME/.config/nexus-tv/start-kiosk.sh &
OPENBOXEOF

chmod +x "$USER_HOME/.config/openbox/autostart"
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config"

# Allow the user to run systemctl commands without password
echo "$ACTUAL_USER ALL=(ALL) NOPASSWD: /bin/systemctl start nexus-tv, /bin/systemctl stop nexus-tv, /bin/systemctl restart nexus-tv, /bin/systemctl status nexus-tv" > /etc/sudoers.d/nexus-tv
chmod 440 /etc/sudoers.d/nexus-tv

# Enable nexus-tv service to start on boot
systemctl enable nexus-tv 2>/dev/null || true

log_ok "Kiosk mode configured"

# ============================================
# CREATE CLI CONTROL COMMAND
# ============================================

log_info "Creating nexus-tv command..."

cat > /usr/local/bin/nexus-tv << CLIEOF
#!/bin/bash
BROWSER="$BROWSER_CMD"

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
                \$BROWSER --app=http://localhost:32400/web --start-fullscreen &
                ;;
            kodi)
                kodi &
                ;;
            netflix)
                \$BROWSER --app=https://www.netflix.com/browse --start-fullscreen &
                ;;
            prime)
                \$BROWSER --app=https://www.primevideo.com --start-fullscreen &
                ;;
            spotify)
                spotify 2>/dev/null || flatpak run com.spotify.Client 2>/dev/null || \$BROWSER --app=https://open.spotify.com --start-fullscreen &
                ;;
            youtube)
                \$BROWSER --app=https://www.youtube.com/tv --start-fullscreen &
                ;;
            freetube)
                flatpak run io.freetubeapp.FreeTube &
                ;;
            kayo)
                \$BROWSER --app=https://kayosports.com.au --start-fullscreen &
                ;;
            chaupal)
                \$BROWSER --app=https://chaupal.tv --start-fullscreen &
                ;;
            *)
                echo "Unknown app: \$2"
                echo "Available apps: plex, kodi, netflix, prime, spotify, youtube, freetube, kayo, chaupal"
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
CLIEOF

chmod +x /usr/local/bin/nexus-tv

# Enable service
systemctl daemon-reload
systemctl enable nexus-tv.service 2>/dev/null || true

echo ""
echo "=============================================="
echo "       INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "Nexus TV OS has been installed with:"
echo ""
echo "  - Plex Media Server (port 32400)"
echo "  - Kodi Media Center"
echo "  - Spotify"
echo "  - FreeTube"
echo "  - VLC Media Player"
echo "  - Netflix (web app)"
echo "  - Prime Video (web app)"
echo "  - YouTube TV (web app)"
echo "  - Kayo Sports (web app)"
echo "  - Chaupal (web app)"
echo ""
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. Control: nexus-tv start|stop|restart|status|logs"
echo "  3. Launch apps: nexus-tv launch kodi"
echo "  4. Exit kiosk mode: Alt+F4"
echo ""
echo "Enjoy your new TV OS!"
echo ""
