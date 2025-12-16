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
    python3-evdev

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
# Start the Nexus TV kiosk
$USER_HOME/.config/nexus-tv/start-kiosk.sh &

# Start the floating back button overlay (appears when apps are running)
sleep 3 && /usr/local/bin/nexus-tv-back-button &
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

# Close active app via API (uses the correct endpoint)
curl -s -X POST "http://localhost:$NEXUS_PORT/api/apps/close" >/dev/null 2>&1

# Kill any kiosk browser windows (backup method) - but NOT the main TV OS browser
# Get PIDs of the main TV OS browser to exclude
TV_PIDS=$(pgrep -f "app=http://localhost:5000" 2>/dev/null || echo "")

# Function to kill process if not TV OS
kill_if_not_tv() {
    local pid=$1
    for tv_pid in $TV_PIDS; do
        if [ "$pid" = "$tv_pid" ]; then
            return
        fi
    done
    kill -9 "$pid" 2>/dev/null || true
}

# Kill kiosk browsers - match various patterns for Chromium/Chrome/Firefox
for pid in $(pgrep -f "kiosk.*netflix\|kiosk.*prime\|kiosk.*youtube\|kiosk.*kayo\|kiosk.*chaupal\|kiosk.*plex\|kiosk.*spotify" 2>/dev/null); do
    kill_if_not_tv "$pid"
done

# Also kill any browser with --kiosk that's NOT showing localhost:5000
for pid in $(pgrep -f "\-\-kiosk" 2>/dev/null); do
    # Check if this PID is in TV_PIDS
    is_tv=0
    for tv_pid in $TV_PIDS; do
        if [ "$pid" = "$tv_pid" ]; then
            is_tv=1
            break
        fi
    done
    if [ "$is_tv" = "0" ]; then
        kill -9 "$pid" 2>/dev/null || true
    fi
done

# Kill native apps that might be running fullscreen
pkill -9 -f "kodi" 2>/dev/null || true
pkill -9 -f "spotify" 2>/dev/null || true
pkill -9 -f "vlc" 2>/dev/null || true
pkill -9 -f "FreeTube" 2>/dev/null || true
pkill -9 -f "io.freetubeapp" 2>/dev/null || true

# Small delay then bring TV OS window back to focus
sleep 0.3
wmctrl -a "Nexus TV" 2>/dev/null || wmctrl -a "localhost:5000" 2>/dev/null || wmctrl -a "Chromium" 2>/dev/null || true
CLOSEEOF

chmod +x "$USER_HOME/.config/nexus-tv/close-app.sh"

# Create a system-level close script
cat > /usr/local/bin/nexus-tv-home << HOMESCRIPT
#!/bin/bash
# This runs as root, so we need to run as the actual user
NEXUS_USER="$ACTUAL_USER"
su - "\$NEXUS_USER" -c "DISPLAY=:0 $USER_HOME/.config/nexus-tv/close-app.sh" 2>/dev/null || $USER_HOME/.config/nexus-tv/close-app.sh
HOMESCRIPT
chmod +x /usr/local/bin/nexus-tv-home

# Set up Python evdev listener for hardware-level key capture
# This grabs the input device BEFORE Chromium can, ensuring remote buttons work
log_info "Configuring hardware key capture for remotes..."

# Create the Python evdev listener script
cat > /usr/local/bin/nexus-tv-input-listener << 'PYEOF'
#!/usr/bin/env python3
"""
Nexus TV OS Input Listener
Captures remote control buttons at the evdev level, bypassing Chromium's input grab.
This runs as a system service. For remotes, it grabs the device. For keyboards, it
listens passively and uses uinput to re-inject non-exit keys.
"""

import os
import sys
import time
import subprocess
import signal
from pathlib import Path

try:
    import evdev
    from evdev import InputDevice, UInput, ecodes, list_devices
except ImportError:
    print("python3-evdev not installed, exiting")
    sys.exit(1)

# Key codes that should trigger "go home" action
# Includes many variations since remotes report different codes
HOME_KEYS = {
    ecodes.KEY_HOMEPAGE,    # Home button on remotes (172)
    ecodes.KEY_HOME,        # Alternative home key (102)
    ecodes.KEY_BACK,        # Back button (158)
    ecodes.KEY_EXIT,        # Exit button (174)
    ecodes.KEY_MENU,        # Menu button (139)
    ecodes.KEY_F10,         # F10 on keyboard (68)
    ecodes.KEY_RED,         # Red button on media remotes (398)
    ecodes.KEY_STOP,        # Stop button (128)
    ecodes.KEY_CLOSE,       # Close key (206)
    ecodes.KEY_CANCEL,      # Cancel key (223)
    ecodes.KEY_ESC,         # Escape key (1)
    ecodes.KEY_PROG1,       # Some remotes use PROG keys (148)
    ecodes.KEY_PROG2,       # (149)
    ecodes.KEY_INFO,        # Info button sometimes used as back (358)
    ecodes.KEY_CONTEXT_MENU,# Context menu (438)
    ecodes.KEY_LAST,        # Last/Previous button (405)
    ecodes.KEY_PREVIOUS,    # Previous (412)
}

# Enable verbose logging of all key events for debugging
VERBOSE_LOGGING = True

# Debounce - prevent multiple triggers
last_trigger = 0
DEBOUNCE_SECONDS = 0.5

# Virtual keyboards for re-injecting keys (one per grabbed device)
uinput_devices = {}

def create_uinput_for_device(dev):
    """Create a virtual input device that mirrors the grabbed device's capabilities"""
    try:
        ui = UInput.from_device(dev, name=f'nexus-tv-passthrough-{dev.name[:20]}')
        print(f"Created virtual device for: {dev.name}")
        return ui
    except Exception as e:
        print(f"Could not create uinput for {dev.name}: {e}")
        return None

def inject_event(uinput, event):
    """Re-inject an event to the system via uinput"""
    if uinput:
        try:
            uinput.write_event(event)
            uinput.syn()
        except Exception as e:
            pass

def trigger_home():
    """Call the nexus-tv-home script to close current app and return to TV"""
    global last_trigger
    now = time.time()
    if now - last_trigger < DEBOUNCE_SECONDS:
        return
    last_trigger = now
    
    print(f"[{time.strftime('%H:%M:%S')}] HOME triggered - returning to TV interface")
    try:
        subprocess.Popen(['/usr/local/bin/nexus-tv-home'], 
                        stdout=subprocess.DEVNULL, 
                        stderr=subprocess.DEVNULL)
    except Exception as e:
        print(f"Error calling nexus-tv-home: {e}")

def is_remote_device(dev):
    """Check if device looks like a remote control (not a regular keyboard)"""
    name = dev.name.lower()
    # Keywords that suggest a remote/media controller
    remote_keywords = ['remote', 'cec', 'ir', 'mce', 'rc', 'media', 'consumer', 'flirc']
    # Keywords that suggest a regular keyboard
    keyboard_keywords = ['keyboard', 'kbd']
    
    is_remote = any(kw in name for kw in remote_keywords)
    is_keyboard = any(kw in name for kw in keyboard_keywords)
    
    # If it has CEC capabilities, it's a remote
    caps = dev.capabilities()
    if ecodes.EV_KEY in caps:
        key_caps = caps[ecodes.EV_KEY]
        # CEC remotes typically have media keys
        has_media_keys = any(k in key_caps for k in [
            ecodes.KEY_PLAYPAUSE, ecodes.KEY_PLAY, ecodes.KEY_PAUSE,
            ecodes.KEY_RECORD, ecodes.KEY_REWIND, ecodes.KEY_FASTFORWARD,
            ecodes.KEY_CHANNELUP, ecodes.KEY_CHANNELDOWN,
            ecodes.KEY_RED, ecodes.KEY_GREEN, ecodes.KEY_YELLOW, ecodes.KEY_BLUE
        ])
        if has_media_keys:
            is_remote = True
    
    return is_remote and not is_keyboard

def find_input_devices():
    """Find all input devices that might be remotes or keyboards"""
    devices = []
    for path in list_devices():
        try:
            dev = InputDevice(path)
            caps = dev.capabilities()
            # Check if device has key events
            if ecodes.EV_KEY in caps:
                key_caps = caps[ecodes.EV_KEY]
                # Check if any of our home keys are supported
                has_home_keys = any(k in key_caps for k in HOME_KEYS)
                # Also include devices with navigation keys (remotes)
                has_nav_keys = any(k in key_caps for k in [
                    ecodes.KEY_UP, ecodes.KEY_DOWN, ecodes.KEY_LEFT, ecodes.KEY_RIGHT,
                    ecodes.KEY_ENTER, ecodes.KEY_OK, ecodes.KEY_SELECT
                ])
                if has_home_keys or has_nav_keys:
                    is_remote = is_remote_device(dev)
                    print(f"Found: {dev.name} ({dev.path}) - {'REMOTE' if is_remote else 'KEYBOARD'}")
                    devices.append((dev, is_remote))
        except Exception as e:
            print(f"Error checking device {path}: {e}")
    return devices

def main():
    print("Nexus TV OS Input Listener starting...")
    print(f"Listening for keys: HOME, BACK, EXIT, MENU, F10, RED, STOP")
    
    # Handle signals for clean shutdown
    def signal_handler(sig, frame):
        print("\nShutting down input listener...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    while True:
        devices = find_input_devices()
        
        if not devices:
            print("No suitable input devices found, waiting...")
            time.sleep(5)
            continue
        
        print(f"Monitoring {len(devices)} input device(s)")
        
        # Create a selector for multiple devices
        try:
            from selectors import DefaultSelector, EVENT_READ
            selector = DefaultSelector()
            
            device_info = {}  # Track device state: {path: (is_grabbed, uinput)}
            
            for dev, is_remote in devices:
                should_grab = is_remote  # Only grab remotes, not keyboards
                uinput = None
                is_grabbed = False
                
                if should_grab:
                    try:
                        # Create uinput BEFORE grabbing so we can passthrough events
                        uinput = create_uinput_for_device(dev)
                        dev.grab()
                        print(f"SUCCESS: Grabbed remote exclusively: {dev.name} ({dev.path})")
                        is_grabbed = True
                    except OSError as e:
                        if e.errno == 16:  # EBUSY
                            print(f"FAILED: Device already grabbed by another process (EBUSY): {dev.name}")
                            print(f"  -> This means Chromium or another app grabbed the device first!")
                            print(f"  -> Try restarting nexus-tv-input.service BEFORE starting Chromium")
                        else:
                            print(f"FAILED: Could not grab {dev.name}: {e}")
                        if uinput:
                            try:
                                uinput.close()
                            except:
                                pass
                            uinput = None
                    except Exception as e:
                        print(f"FAILED: Could not grab {dev.name}: {e}")
                        if uinput:
                            try:
                                uinput.close()
                            except:
                                pass
                            uinput = None
                else:
                    print(f"PASSIVE: Listening to keyboard (no grab): {dev.name}")
                
                device_info[dev.path] = (is_grabbed, uinput)
                selector.register(dev, EVENT_READ, data=(is_remote, is_grabbed, uinput))
            
            while True:
                for key, mask in selector.select(timeout=1):
                    device = key.fileobj
                    is_remote, is_grabbed, uinput = key.data
                    try:
                        for event in device.read():
                            # Verbose logging of all key events for debugging
                            if VERBOSE_LOGGING and event.type == ecodes.EV_KEY and event.value == 1:
                                key_name = ecodes.KEY.get(event.code, f"UNKNOWN_{event.code}")
                                print(f"[KEY] code={event.code} name={key_name} from={device.name}")
                            
                            # Check if this is a home/exit key press
                            if event.type == ecodes.EV_KEY and event.code in HOME_KEYS and event.value == 1:
                                key_name = ecodes.KEY.get(event.code, f"KEY_{event.code}")
                                print(f"*** HOME KEY DETECTED: {key_name} (code={event.code}) from {device.name} ***")
                                trigger_home()
                            elif is_grabbed and uinput:
                                # For grabbed devices, re-inject ALL events (passthrough)
                                inject_event(uinput, event)
                    except Exception as e:
                        print(f"Error reading from {device.name}: {e}")
                        try:
                            selector.unregister(device)
                        except:
                            pass
                        break
                else:
                    continue
                break  # Re-enumerate devices
                
        except Exception as e:
            print(f"Selector error: {e}")
        
        # Cleanup: release devices and close uinput
        for dev, is_remote in devices:
            try:
                dev.ungrab()
            except:
                pass
            try:
                dev.close()
            except:
                pass
        
        for path, (is_grabbed, uinput) in device_info.items():
            if uinput:
                try:
                    uinput.close()
                except:
                    pass
        
        time.sleep(2)

if __name__ == '__main__':
    main()
PYEOF
chmod +x /usr/local/bin/nexus-tv-input-listener

# Create systemd service for the input listener (runs as root to access /dev/input)
# CRITICAL: Must start BEFORE display-manager so we grab the remote BEFORE Chromium does
cat > /etc/systemd/system/nexus-tv-input.service << 'SVCEOF'
[Unit]
Description=Nexus TV OS Input Listener
After=systemd-udevd.service local-fs.target
Before=display-manager.service lightdm.service graphical.target

[Service]
Type=simple
ExecStartPre=/sbin/modprobe uinput
ExecStart=/usr/local/bin/nexus-tv-input-listener
Restart=always
RestartSec=2
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

# Load uinput kernel module (needed for key re-injection)
modprobe uinput 2>/dev/null || true
echo "uinput" >> /etc/modules-load.d/nexus-tv.conf 2>/dev/null || true

# Enable and start the input listener service
systemctl daemon-reload
systemctl enable nexus-tv-input.service 2>/dev/null || true
systemctl restart nexus-tv-input.service 2>/dev/null || true

# Add udev rule to ensure proper input device permissions
cat > /etc/udev/rules.d/99-nexus-tv-input.rules << 'UDEVEOF'
# Allow Nexus TV input listener to access all input devices
SUBSYSTEM=="input", GROUP="input", MODE="0660"
KERNEL=="event*", GROUP="input", MODE="0660"
UDEVEOF

# Add user to input group
usermod -a -G input "$ACTUAL_USER" 2>/dev/null || true

# Reload udev rules
udevadm control --reload-rules 2>/dev/null || true
udevadm trigger 2>/dev/null || true

chown -R "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/nexus-tv"

log_ok "Hardware key capture configured (Home, Back, Menu, F10, Stop, ESC, or Red button to exit apps)"

# ============================================
# CREATE FLOATING BACK BUTTON OVERLAY
# ============================================

log_info "Creating floating back button overlay..."

# Install GTK dependencies for the overlay
apt-get install -y -qq python3-gi python3-gi-cairo gir1.2-gtk-3.0 2>/dev/null || true

# Create the floating back button script
cat > /usr/local/bin/nexus-tv-back-button << 'BACKBTNEOF'
#!/usr/bin/env python3
"""
Nexus TV OS - Floating Back Button
A small overlay button that appears in the corner when apps are running.
Click it to return to the TV interface.
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import os
import time
import urllib.request
import json

class BackButton(Gtk.Window):
    def __init__(self):
        super().__init__(title="")
        
        # Make window transparent and always on top
        self.set_decorated(False)
        self.set_keep_above(True)
        self.set_skip_taskbar_hint(True)
        self.set_skip_pager_hint(True)
        self.set_type_hint(Gdk.WindowTypeHint.UTILITY)
        
        # Enable transparency
        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual:
            self.set_visual(visual)
        self.set_app_paintable(True)
        
        # Create the back button
        self.button = Gtk.Button()
        self.button.set_size_request(60, 60)
        self.button.connect("clicked", self.on_back_clicked)
        
        # Style the button
        css = b'''
        button {
            background: rgba(0, 0, 0, 0.7);
            border: 2px solid rgba(138, 43, 226, 0.8);
            border-radius: 30px;
            color: white;
            font-size: 24px;
            font-weight: bold;
            min-width: 60px;
            min-height: 60px;
        }
        button:hover {
            background: rgba(138, 43, 226, 0.9);
            border-color: white;
        }
        '''
        
        style_provider = Gtk.CssProvider()
        style_provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_screen(
            screen,
            style_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        
        # Add arrow icon
        self.button.set_label("←")
        
        self.add(self.button)
        
        # Position in top-left corner with padding
        self.move(20, 20)
        
        # Start hidden
        self.hide()
        
        # Check for active app periodically
        GLib.timeout_add(1000, self.check_active_app)
    
    def check_active_app(self):
        """Check if an app is running and show/hide the button accordingly"""
        try:
            port = os.environ.get('NEXUS_PORT', '5000')
            url = f"http://localhost:{port}/api/apps/active"
            req = urllib.request.Request(url, method='GET')
            req.add_header('Content-Type', 'application/json')
            
            with urllib.request.urlopen(req, timeout=1) as response:
                data = json.loads(response.read().decode())
                if data.get('active', False):
                    self.show_all()
                else:
                    self.hide()
        except Exception as e:
            # If we can't connect, hide the button
            self.hide()
        
        return True  # Continue the timeout
    
    def on_back_clicked(self, widget):
        """Handle back button click"""
        try:
            # Call the close-app script
            home = os.path.expanduser("~")
            script = os.path.join(home, ".config/nexus-tv/close-app.sh")
            if os.path.exists(script):
                subprocess.Popen([script], env={**os.environ, 'DISPLAY': ':0'})
            else:
                # Fallback: call API directly
                port = os.environ.get('NEXUS_PORT', '5000')
                url = f"http://localhost:{port}/api/apps/close"
                req = urllib.request.Request(url, method='POST')
                req.add_header('Content-Type', 'application/json')
                urllib.request.urlopen(req, timeout=2)
        except Exception as e:
            print(f"Error closing app: {e}")
        
        self.hide()

def main():
    # Set display
    os.environ.setdefault('DISPLAY', ':0')
    
    win = BackButton()
    win.connect("destroy", Gtk.main_quit)
    
    Gtk.main()

if __name__ == '__main__':
    main()
BACKBTNEOF
chmod +x /usr/local/bin/nexus-tv-back-button

# Create autostart entry for the back button
mkdir -p "$USER_HOME/.config/autostart"
cat > "$USER_HOME/.config/autostart/nexus-tv-back-button.desktop" << AUTOBACKEOF
[Desktop Entry]
Type=Application
Name=Nexus TV Back Button
Exec=/usr/local/bin/nexus-tv-back-button
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOBACKEOF
chown "$ACTUAL_USER:$ACTUAL_USER" "$USER_HOME/.config/autostart/nexus-tv-back-button.desktop"

# Also add to Openbox autostart
if [ -f "$USER_HOME/.config/openbox/autostart" ]; then
    if ! grep -q "nexus-tv-back-button" "$USER_HOME/.config/openbox/autostart"; then
        echo "/usr/local/bin/nexus-tv-back-button &" >> "$USER_HOME/.config/openbox/autostart"
    fi
fi

log_ok "Floating back button overlay created"

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
