import type { Express } from "express";
import { createServer, type Server } from "http";
import { exec, execSync } from "child_process";
import { promisify } from "util";
import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { storage } from "./storage";

const execAsync = promisify(exec);

// Detect the correct browser command
function detectBrowser(): string {
  const browsers = [
    "/snap/bin/chromium",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/snap/bin/firefox",
    "/usr/bin/firefox",
  ];
  
  for (const browser of browsers) {
    if (existsSync(browser)) {
      console.log(`[Browser] Using: ${browser}`);
      return browser;
    }
  }
  
  // Try which command as fallback
  try {
    const result = execSync("which chromium chromium-browser firefox 2>/dev/null | head -1", { encoding: "utf-8" }).trim();
    if (result) {
      console.log(`[Browser] Found via which: ${result}`);
      return result;
    }
  } catch (e) {}
  
  console.log("[Browser] Fallback to firefox");
  return "firefox";
}

const BROWSER = detectBrowser();

const APP_COMMANDS: Record<string, string> = {
  plex: `${BROWSER} --kiosk --app=http://localhost:32400/web`,
  kodi: "kodi",
  netflix: `${BROWSER} --kiosk --app=https://www.netflix.com/browse`,
  prime: `${BROWSER} --kiosk --app=https://www.primevideo.com`,
  spotify: "spotify || flatpak run com.spotify.Client || " + `${BROWSER} --kiosk --app=https://open.spotify.com`,
  youtube: `${BROWSER} --kiosk --app=https://www.youtube.com/tv`,
  freetube: "flatpak run io.freetubeapp.FreeTube",
  vacuumtube: "flatpak run rocks.shy.VacuumTube",
  kayo: `${BROWSER} --kiosk --app=https://kayosports.com.au`,
  chaupal: `${BROWSER} --kiosk --app=https://chaupal.tv`,
};

export async function registerRoutes(
  httpServer: Server,
  app: Express
): Promise<Server> {
  
  // Serve the install script
  app.get("/install.sh", (req, res) => {
    try {
      const scriptPath = join(process.cwd(), "install.sh");
      const script = readFileSync(scriptPath, "utf-8");
      res.setHeader("Content-Type", "text/plain");
      res.setHeader("Content-Disposition", "attachment; filename=install.sh");
      res.send(script);
    } catch (error) {
      res.status(500).send("# Error: Could not load install script");
    }
  });

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
