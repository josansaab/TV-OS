# Nexus TV OS

A modern, cinematic TV operating system interface for Ubuntu. Transform your PC or NUC into a smart TV experience with support for Plex, Kodi, Netflix, and more.

![Nexus TV OS](https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-orange?style=for-the-badge&logo=ubuntu)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

## Features

- 🎬 **Modern TV Interface** - Cinematic design with smooth animations
- 📺 **App Launcher** - Quick access to streaming apps and media centers
- 🌤️ **Live Widgets** - Weather and clock displayed on home screen
- ⌨️ **Remote-Ready** - Full keyboard and gamepad navigation support
- 🚀 **Auto-Start** - Boots directly into TV mode on startup
- 🎮 **Kiosk Mode** - Fullscreen experience with no distractions

## Supported Apps

| Native Apps | Web Apps |
|-------------|----------|
| Plex Media Server | Netflix |
| Kodi Media Center | Amazon Prime Video |
| Spotify | YouTube TV |
| FreeTube | Kayo Sports |
| VacuumTube | Chaupal |
| VLC Media Player | |

## Quick Install

Install Nexus TV OS with a single command:

```bash
curl -sL https://raw.githubusercontent.com/josansaab/TV-OS/main/install.sh | sudo bash
```

After installation, reboot your system:

```bash
sudo reboot
```

Your system will boot directly into Nexus TV OS in fullscreen kiosk mode.

## System Requirements

- **OS**: Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
- **RAM**: 2GB minimum, 4GB recommended
- **CPU**: Dual-core processor or better
- **Display**: 1920x1080 or higher recommended
- **Network**: Broadband internet for streaming

## What Gets Installed

The installer automatically sets up:

- **Kodi** - Full media center with add-on support
- **Plex Media Server** - Stream your media library (runs on port 32400)
- **Spotify** - Music streaming (via Snap or Flatpak)
- **FreeTube** - Privacy-focused YouTube client
- **VacuumTube** - YouTube TV interface for desktop
- **VLC** - Universal media player
- **Web Apps** - Netflix, Prime Video, YouTube, Kayo, Chaupal

## Usage

### Control Commands

```bash
nexus-tv start      # Start Nexus TV service
nexus-tv stop       # Stop Nexus TV service
nexus-tv restart    # Restart Nexus TV service
nexus-tv status     # Show service status
nexus-tv logs       # Show live logs
nexus-tv launch <app>  # Launch a specific app
```

### Launch Apps Directly

```bash
nexus-tv launch kodi
nexus-tv launch plex
nexus-tv launch netflix
nexus-tv launch spotify
nexus-tv launch youtube
nexus-tv launch freetube
nexus-tv launch prime
nexus-tv launch kayo
nexus-tv launch chaupal
```

### Navigation

- **Arrow Keys** - Navigate between items
- **Enter/Space** - Select item
- **Tab** - Cycle through focusable elements
- **Alt + F4** - Exit kiosk mode
- **F11** - Toggle fullscreen (when not in kiosk mode)

## Manual Installation

### Prerequisites

- Ubuntu 22.04 or 24.04
- Sudo access
- Internet connection

### Steps

1. Clone the repository:
```bash
git clone https://github.com/josansaab/TV-OS.git
cd TV-OS
```

2. Run the installer:
```bash
sudo bash install.sh
```

3. Reboot:
```bash
sudo reboot
```

## Development

### Run in Development Mode

```bash
npm install
npm run dev
```

Access the interface at `http://localhost:5000`

### Project Structure

```
TV-OS/
├── client/              # Frontend React application
│   ├── src/
│   │   ├── components/  # React components
│   │   │   └── tv/      # TV-specific components
│   │   └── pages/       # Page components
│   └── index.html
├── server/              # Express backend
│   ├── index.ts         # Server entry point
│   ├── routes.ts        # API routes (app launcher)
│   └── storage.ts       # Data storage layer
├── shared/              # Shared types and schemas
├── install.sh           # System installer script
└── package.json
```

## Configuration

### Custom Apps

Edit `client/src/pages/Home.tsx` to add or modify apps in the launcher.

### Theme Customization

Modify colors and styling in `client/src/index.css`.

## Troubleshooting

### Service won't start

```bash
# Check service status
nexus-tv status

# View logs
nexus-tv logs

# Restart service
nexus-tv restart
```

### Kiosk mode not starting on boot

Check LightDM configuration:
```bash
cat /etc/lightdm/lightdm.conf.d/50-nexus-tv.conf
```

### Apps not launching

Make sure the apps are installed:
```bash
which kodi
which vlc
flatpak list
```

## Uninstall

```bash
# Stop the service
sudo systemctl stop nexus-tv
sudo systemctl disable nexus-tv

# Remove files
sudo rm -rf /opt/nexus-tv
sudo rm /etc/systemd/system/nexus-tv.service
sudo rm /usr/local/bin/nexus-tv

# Remove auto-login (optional)
sudo rm /etc/lightdm/lightdm.conf.d/50-nexus-tv.conf

# Reload systemd
sudo systemctl daemon-reload
```

## License

MIT License - See LICENSE file for details

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please visit our [GitHub Issues](https://github.com/josansaab/TV-OS/issues) page.

---

**Made with ❤️ for the home theater community**
