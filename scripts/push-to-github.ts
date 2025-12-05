import { Octokit } from '@octokit/rest';
import * as fs from 'fs';
import * as path from 'path';

let connectionSettings: any;

async function getAccessToken() {
  if (connectionSettings && connectionSettings.settings.expires_at && new Date(connectionSettings.settings.expires_at).getTime() > Date.now()) {
    return connectionSettings.settings.access_token;
  }
  
  const hostname = process.env.REPLIT_CONNECTORS_HOSTNAME;
  const xReplitToken = process.env.REPL_IDENTITY 
    ? 'repl ' + process.env.REPL_IDENTITY 
    : process.env.WEB_REPL_RENEWAL 
    ? 'depl ' + process.env.WEB_REPL_RENEWAL 
    : null;

  if (!xReplitToken) {
    throw new Error('X_REPLIT_TOKEN not found for repl/depl');
  }

  connectionSettings = await fetch(
    'https://' + hostname + '/api/v2/connection?include_secrets=true&connector_names=github',
    {
      headers: {
        'Accept': 'application/json',
        'X_REPLIT_TOKEN': xReplitToken
      }
    }
  ).then(res => res.json()).then(data => data.items?.[0]);

  const accessToken = connectionSettings?.settings?.access_token || connectionSettings.settings?.oauth?.credentials?.access_token;

  if (!connectionSettings || !accessToken) {
    throw new Error('GitHub not connected');
  }
  return accessToken;
}

async function getUncachableGitHubClient() {
  const accessToken = await getAccessToken();
  return new Octokit({ auth: accessToken });
}

async function pushFile(octokit: Octokit, owner: string, repo: string, filePath: string, repoPath: string) {
  const content = fs.readFileSync(filePath);
  const base64Content = content.toString('base64');
  
  let sha: string | undefined;
  try {
    const { data } = await octokit.repos.getContent({
      owner,
      repo,
      path: repoPath,
    });
    if ('sha' in data) {
      sha = data.sha;
    }
  } catch (e: any) {
    if (e.status !== 404) throw e;
  }

  await octokit.repos.createOrUpdateFileContents({
    owner,
    repo,
    path: repoPath,
    message: `Update ${repoPath}`,
    content: base64Content,
    sha,
  });
  
  console.log(`Pushed: ${repoPath}`);
}

async function getAllFiles(dir: string, baseDir: string = dir): Promise<string[]> {
  const files: string[] = [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...await getAllFiles(fullPath, baseDir));
    } else {
      files.push(fullPath);
    }
  }
  
  return files;
}

async function main() {
  const owner = 'josansaab';
  const repo = 'TV-OS';
  
  console.log('Connecting to GitHub...');
  const octokit = await getUncachableGitHubClient();
  
  console.log('Pushing install.sh...');
  await pushFile(octokit, owner, repo, 'install.sh', 'install.sh');
  
  console.log('Pushing dist/ folder...');
  const distFiles = await getAllFiles('dist');
  
  for (const file of distFiles) {
    const repoPath = file;
    await pushFile(octokit, owner, repo, file, repoPath);
  }
  
  console.log('Done! All files pushed to GitHub.');
}

main().catch(console.error);
