# Nexus TV OS

A modern, cinematic TV operating system interface for Ubuntu. Transform your PC into a smart TV experience with support for Plex, Kodi, Netflix, and more.

## Features

- 🎬 **Modern TV Interface** - Cinematic design with smooth animations
- 📺 **App Launcher** - Quick access to streaming apps and media centers
- 🌤️ **Live Widgets** - Weather and clock displayed on home screen
- ⌨️ **Remote-Ready** - Full keyboard and gamepad navigation support
- 🚀 **Auto-Start** - Boots directly into TV mode on startup
- 🎮 **Kiosk Mode** - Fullscreen experience with no distractions

## Supported Apps

- Plex Media Server
- Kodi Media Center
- Netflix
- Amazon Prime Video
- Spotify
- YouTube
- Kayo Sports
- FreeTube
- VacuumTube
- Chaupal

## Quick Install (Ubuntu 24.03+)

Install Nexus TV OS with a single command:

```bash
curl -sL https://nexus-os.tv/install.sh | sudo bash
```

After installation, reboot your system:

```bash
sudo reboot
```

Your system will boot directly into Nexus TV OS in fullscreen kiosk mode.

## Manual Installation

### Prerequisites

- Ubuntu 24.03 or later
- Node.js 20+
- 2GB RAM minimum
- Internet connection

### Steps

1. Clone the repository:
```bash
git clone https://github.com/yourusername/nexus-tv.git
cd nexus-tv
```

2. Install dependencies:
```bash
npm install
```

3. Build the application:
```bash
npm run build
```

4. Run the installer:
```bash
sudo bash install.sh
```

5. Reboot:
```bash
sudo reboot
```

## Usage

### Control Commands

```bash
nexus-tv start      # Start Nexus TV
nexus-tv stop       # Stop Nexus TV
nexus-tv restart    # Restart Nexus TV
nexus-tv status     # Show service status
nexus-tv logs       # Show live logs
nexus-tv update     # Update to latest version
```

### Navigation

- **Arrow Keys** - Navigate between items
- **Enter/Space** - Select item
- **Tab** - Cycle through focusable elements
- **Alt + F4** - Exit kiosk mode
- **F11** - Toggle fullscreen (when not in kiosk mode)

### Exiting Kiosk Mode

Press `Alt + F4` to exit the kiosk mode and return to desktop.

## Development

### Run in Development Mode

```bash
npm run dev
```

Access the interface at `http://localhost:5000`

### Project Structure

```
nexus-tv/
├── client/              # Frontend React application
│   ├── src/
│   │   ├── components/  # React components
│   │   │   └── tv/      # TV-specific components
│   │   └── pages/       # Page components
│   └── index.html
├── server/              # Express backend
│   ├── index.ts         # Server entry point
│   ├── routes.ts        # API routes
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

### Weather Widget

The weather widget uses mock data. To add real weather:

1. Get an API key from a weather service
2. Update `client/src/components/tv/Widgets.tsx`
3. Add API integration in the backend

## System Requirements

- **OS**: Ubuntu 24.03 or later
- **RAM**: 2GB minimum, 4GB recommended
- **CPU**: Dual-core processor or better
- **Display**: 1920x1080 or higher
- **Network**: Broadband internet for streaming

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

### Apps not opening

Some apps require separate installation:
- **Plex**: Install from https://www.plex.tv/downloads/
- **Kodi**: `sudo apt install kodi`
- **Others**: Web-based apps open in browser

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

For issues and questions, please visit our GitHub Issues page.

---

**Made with ❤️ for the home theater community**
