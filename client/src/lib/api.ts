export async function launchApp(appId: string): Promise<{ success: boolean; message?: string; error?: string }> {
  try {
    const response = await fetch(`/api/launch/${appId}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    return await response.json();
  } catch (error) {
    console.error('Failed to launch app:', error);
    return { success: false, error: 'Failed to connect to server' };
  }
}

export async function getSystemStatus(): Promise<{
  status: string;
  uptime: string;
  hostname: string;
  version: string;
}> {
  try {
    const response = await fetch('/api/system/status');
    return await response.json();
  } catch (error) {
    return {
      status: 'unknown',
      uptime: 'unknown',
      hostname: 'nexus-tv',
      version: '1.0.0'
    };
  }
}

export async function systemPower(action: 'shutdown' | 'restart'): Promise<{ success: boolean; message?: string }> {
  try {
    const response = await fetch('/api/system/power', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ action }),
    });
    
    return await response.json();
  } catch (error) {
    return { success: false, message: 'Failed to connect to server' };
  }
}
