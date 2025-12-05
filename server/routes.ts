import type { Express } from "express";
import { createServer, type Server } from "http";
import { exec } from "child_process";
import { promisify } from "util";
import { storage } from "./storage";

const execAsync = promisify(exec);

const APP_COMMANDS: Record<string, string> = {
  plex: "chromium-browser --app=http://localhost:32400/web --start-fullscreen",
  kodi: "kodi",
  netflix: "chromium-browser --app=https://www.netflix.com/browse --start-fullscreen",
  prime: "chromium-browser --app=https://www.primevideo.com --start-fullscreen",
  spotify: "spotify || flatpak run com.spotify.Client",
  youtube: "chromium-browser --app=https://www.youtube.com/tv --start-fullscreen",
  freetube: "flatpak run io.freetubeapp.FreeTube",
  vacuumtube: "flatpak run rocks.shy.VacuumTube || /usr/local/bin/vacuumtube",
  kayo: "chromium-browser --app=https://kayosports.com.au --start-fullscreen",
  chaupal: "chromium-browser --app=https://chaupal.tv --start-fullscreen",
};

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  
  app.post("/api/launch/:appId", async (req, res) => {
    const { appId } = req.params;
    const command = APP_COMMANDS[appId];
    
    if (!command) {
      return res.status(404).json({ 
        success: false, 
        error: `Unknown app: ${appId}`,
        availableApps: Object.keys(APP_COMMANDS)
      });
    }

    try {
      exec(`DISPLAY=:0 ${command} &`, { 
        detached: true,
        stdio: 'ignore'
      } as any);

      res.json({ 
        success: true, 
        message: `Launching ${appId}...`,
        app: appId 
      });
    } catch (error) {
      console.error(`Failed to launch ${appId}:`, error);
      res.status(500).json({ 
        success: false, 
        error: `Failed to launch ${appId}` 
      });
    }
  });

  app.get("/api/apps", (req, res) => {
    const apps = Object.keys(APP_COMMANDS).map(id => ({
      id,
      name: id.charAt(0).toUpperCase() + id.slice(1),
      available: true
    }));
    
    res.json({ apps });
  });

  app.get("/api/system/status", async (req, res) => {
    try {
      const { stdout: uptime } = await execAsync("uptime -p");
      const { stdout: hostname } = await execAsync("hostname");
      
      res.json({
        status: "running",
        uptime: uptime.trim(),
        hostname: hostname.trim(),
        version: "1.0.0"
      });
    } catch (error) {
      res.json({
        status: "running",
        uptime: "unknown",
        hostname: "nexus-tv",
        version: "1.0.0"
      });
    }
  });

  app.post("/api/system/power", async (req, res) => {
    const { action } = req.body;
    
    if (action === "shutdown") {
      res.json({ success: true, message: "Shutting down..." });
      setTimeout(() => {
        exec("sudo shutdown -h now");
      }, 1000);
    } else if (action === "restart") {
      res.json({ success: true, message: "Restarting..." });
      setTimeout(() => {
        exec("sudo reboot");
      }, 1000);
    } else {
      res.status(400).json({ success: false, error: "Invalid action" });
    }
  });

  return httpServer;
}
