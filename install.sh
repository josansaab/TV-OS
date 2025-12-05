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
    firefox \
    wmctrl \
    xdotool \
    triggerhappy

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

# Give the actual user ownership of the install directory
chown -R "$ACTUAL_USER:$ACTUAL_USER" "$INSTALL_DIR"

log_ok "Nexus TV OS installed"

# ============================================
# CREATE USER-LEVEL SERVICE (runs as logged-in user)
# ============================================

log_info "Creating user-level launcher service..."

# Create user systemd directory
USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"

# Create user-level service (runs as the user with display access)
cat > "$USER_SYSTEMD_DIR/nexus-tv.service" << SERVICEEOF
[Unit]
Description=Nexus TV OS Launcher
After=graphical-session.target

[Service]
Type=simple
WorkingDirectory=/opt/nexus-tv
Environment=NODE_ENV=production
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
SERVICEEOF

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/systemd"

# Enable linger so user services start at boot (before login)
loginctl enable-linger "$ACTUAL_USER" 2>/dev/null || true

# Enable the user service
su - "$ACTUAL_USER" -c "systemctl --user daemon-reload" 2>/dev/null || true
su - "$ACTUAL_USER" -c "systemctl --user enable nexus-tv.service" 2>/dev/null || true

log_ok "User service created"

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

# Start the Nexus TV backend service (user-level service)
systemctl --user start nexus-tv.service 2>/dev/null &

# Wait for backend to be ready
for i in 1 2 3 4 5 6 7 8 9 10; do
    if curl -s http://localhost:5000 > /dev/null 2>&1; then
        break
    fi
    sleep 1
done

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

log_ok "Kiosk mode configured"

# ============================================
# CREATE APP EXIT/RETURN-TO-TV SHORTCUTS
# ============================================

log_info "Setting up keyboard shortcuts to return to TV OS..."

# Create close-app script that kills active kiosk apps and returns to TV
cat > "$USER_HOME/.config/nexus-tv/close-app.sh" << 'CLOSEEOF'
#!/bin/bash
# Close active app and return to Nexus TV OS

export DISPLAY=:0

NEXUS_PORT="${NEXUS_PORT:-5000}"

# Get active app info from the backend
ACTIVE=$(curl -s "http://localhost:$NEXUS_PORT/api/apps/active" 2>/dev/null)

if echo "$ACTIVE" | grep -q '"active":true'; then
    APP_ID=$(echo "$ACTIVE" | grep -o '"appId":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$APP_ID" ]; then
        # Close the active app via API
        curl -s -X POST "http://localhost:$NEXUS_PORT/api/apps/$APP_ID/close" >/dev/null 2>&1
    fi
fi

# Kill any kiosk browser windows (backup method) - but NOT the main TV OS browser
# Get the TV OS browser PID to exclude it
TV_BROWSER_PID=$(pgrep -f "app=http://localhost:5000" | head -1)

# Kill kiosk browsers for streaming apps
for pid in $(pgrep -f "chromium.*--kiosk"); do
    if [ "$pid" != "$TV_BROWSER_PID" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done

for pid in $(pgrep -f "chromium-browser.*--kiosk"); do
    if [ "$pid" != "$TV_BROWSER_PID" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done

for pid in $(pgrep -f "firefox.*--kiosk"); do
    if [ "$pid" != "$TV_BROWSER_PID" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done

for pid in $(pgrep -f "google-chrome.*--kiosk"); do
    if [ "$pid" != "$TV_BROWSER_PID" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done

# Kill native apps that might be running fullscreen
pkill -f "^kodi" 2>/dev/null || true
pkill -f "spotify --" 2>/dev/null || true
pkill -f "^vlc" 2>/dev/null || true
pkill -f "freetube" 2>/dev/null || true

# Small delay then bring TV OS window back to focus
sleep 0.3
wmctrl -a "Nexus TV" 2>/dev/null || wmctrl -a "localhost:5000" 2>/dev/null || wmctrl -a "Chromium" 2>/dev/null || true
CLOSEEOF

chmod +x "$USER_HOME/.config/nexus-tv/close-app.sh"

# Create a system-level close script that can be called by triggerhappy
cat > /usr/local/bin/nexus-tv-home << HOMESCRIPT
#!/bin/bash
# This runs as root from triggerhappy, so we need to run as the actual user
NEXUS_USER="$ACTUAL_USER"
su - "\$NEXUS_USER" -c "DISPLAY=:0 $USER_HOME/.config/nexus-tv/close-app.sh" 2>/dev/null || $USER_HOME/.config/nexus-tv/close-app.sh
HOMESCRIPT
chmod +x /usr/local/bin/nexus-tv-home

# Set up triggerhappy for hardware-level key capture (works with remotes!)
log_info "Configuring hardware key capture for remotes..."

mkdir -p /etc/triggerhappy/triggers.d

# Create triggerhappy config for various remote/keyboard buttons
cat > /etc/triggerhappy/triggers.d/nexus-tv.conf << 'THEOF'
# Nexus TV OS - Return to TV interface triggers
# These capture keys at the hardware/input level - works with any remote!

# Home button (common on remotes)
KEY_HOMEPAGE    1       /usr/local/bin/nexus-tv-home

# Back button (common on remotes)  
KEY_BACK        1       /usr/local/bin/nexus-tv-home

# Exit button (some remotes have this)
KEY_EXIT        1       /usr/local/bin/nexus-tv-home

# Menu button as alternative
KEY_MENU        1       /usr/local/bin/nexus-tv-home

# F10 key (keyboard)
KEY_F10         1       /usr/local/bin/nexus-tv-home

# Red button on media remotes (commonly used for exit)
KEY_RED         1       /usr/local/bin/nexus-tv-home

# Stop button on media remotes
KEY_STOP        1       /usr/local/bin/nexus-tv-home

# Close/Cancel
KEY_CLOSE       1       /usr/local/bin/nexus-tv-home
KEY_CANCEL      1       /usr/local/bin/nexus-tv-home
THEOF

# Enable and start triggerhappy service
systemctl enable triggerhappy 2>/dev/null || true
systemctl restart triggerhappy 2>/dev/null || true

# Also add udev rule to ensure triggerhappy can access input devices
cat > /etc/udev/rules.d/99-nexus-tv-input.rules << 'UDEVEOF'
# Allow triggerhappy to access all input devices for remote control support
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="event*", GROUP="input", MODE="0660"
UDEVEOF

# Add user to input group
usermod -a -G input "$ACTUAL_USER" 2>/dev/null || true

# Reload udev rules
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/nexus-tv"

log_ok "Hardware key capture configured (Home, Back, Menu, F10, Stop, or Red button to exit apps)"

# ============================================
# CREATE CLI CONTROL COMMAND
# ============================================

log_info "Creating nexus-tv command..."

cat > /usr/local/bin/nexus-tv << CLIEOF
#!/bin/bash
BROWSER="$BROWSER_CMD"

case "\$1" in
    start)
        systemctl --user start nexus-tv.service
        echo "Nexus TV started"
        ;;
    stop)
        systemctl --user stop nexus-tv.service
        echo "Nexus TV stopped"
        ;;
    restart)
        systemctl --user restart nexus-tv.service
        echo "Nexus TV restarted"
        ;;
    close)
        # Close any running app and return to TV
        $USER_HOME/.config/nexus-tv/close-app.sh
        echo "Closed active app, returning to TV"
        ;;
    status)
        systemctl --user status nexus-tv.service
        ;;
    logs)
        journalctl --user -u nexus-tv.service -f
        ;;
    kiosk)
        # Start in kiosk mode
        $USER_HOME/.config/nexus-tv/start-kiosk.sh
        ;;
    launch)
        case "\$2" in
            plex)
                \$BROWSER --kiosk --app=http://localhost:32400/web &
                ;;
            kodi)
                kodi &
                ;;
            netflix)
                \$BROWSER --kiosk --app=https://www.netflix.com/browse &
                ;;
            prime)
                \$BROWSER --kiosk --app=https://www.primevideo.com &
                ;;
            spotify)
                spotify 2>/dev/null || flatpak run com.spotify.Client 2>/dev/null || \$BROWSER --kiosk --app=https://open.spotify.com &
                ;;
            youtube)
                \$BROWSER --kiosk --app=https://www.youtube.com/tv &
                ;;
            freetube)
                flatpak run io.freetubeapp.FreeTube &
                ;;
            kayo)
                \$BROWSER --kiosk --app=https://kayosports.com.au &
                ;;
            chaupal)
                \$BROWSER --kiosk --app=https://chaupal.tv &
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
        echo "Usage: nexus-tv {start|stop|restart|close|status|logs|kiosk|launch <app>}"
        echo ""
        echo "Commands:"
        echo "  start           - Start Nexus TV"
        echo "  stop            - Stop Nexus TV"
        echo "  restart         - Restart Nexus TV"
        echo "  close           - Close active app and return to TV"
        echo "  status          - Show service status"
        echo "  logs            - Show live logs"
        echo "  kiosk           - Start in fullscreen kiosk mode"
        echo "  launch <app>    - Launch an app (plex, kodi, netflix, etc.)"
        echo ""
        echo "Keyboard/Remote shortcuts (exit apps and return to TV):"
        echo "  HOME button     - Return to TV interface"
        echo "  BACK button     - Return to TV interface"
        echo "  MENU button     - Return to TV interface"
        echo "  F10 key         - Return to TV interface"
        echo "  RED button      - Return to TV interface"
        echo "  STOP button     - Return to TV interface"
        ;;
esac
CLIEOF

chmod +x /usr/local/bin/nexus-tv

# Clean up any legacy system-level service (from previous installs)
log_info "Cleaning up legacy services..."
systemctl stop nexus-tv.service 2>/dev/null || true
systemctl disable nexus-tv.service 2>/dev/null || true
rm -f /etc/systemd/system/nexus-tv.service 2>/dev/null || true
systemctl daemon-reload 2>/dev/null || true

log_ok "CLI tool created"

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
echo "  1. Log out and log back in (or reboot)"
echo "  2. Start TV OS: nexus-tv start"
echo "  3. Open kiosk mode: nexus-tv kiosk"
echo "  4. Launch apps: nexus-tv launch kodi"
echo ""
echo "EXIT FROM APPS (works with any remote or keyboard):"
echo "  HOME button  - Return to TV interface"
echo "  BACK button  - Return to TV interface"  
echo "  MENU button  - Return to TV interface"
echo "  F10 key      - Return to TV interface"
echo "  RED button   - Return to TV interface (media remotes)"
echo "  STOP button  - Return to TV interface"
echo ""
echo "The TV OS now runs as YOUR user, so it can launch"
echo "native apps like Kodi directly from the interface!"
echo ""
echo "Enjoy your new TV OS!"
echo ""
