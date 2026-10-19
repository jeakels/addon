const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

if (process.argv[2] === '--install-mode') {
  installMode();
} else {
  fivemMode();
}

function escapeRegExp(str) {
  return String(str).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeLF(content) {
  return String(content)
    .replace(/^\uFEFF/, '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n')
    .replace(/\n*$/, '\n');
}

function readStdinJson() {
  return new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf8');
    process.stdin.on('data', chunk => {
      data += chunk;
    });
    process.stdin.on('end', () => {
      try {
        resolve(JSON.parse(data || '{}'));
      } catch (err) {
        reject(err);
      }
    });
  });
}

async function installMode() {
  const action = process.argv[3];
  const currentResource = process.argv[4];
  const defModule = process.argv[5];

  try {
    if (!['install', 'uninstall'].includes(action)) {
      console.log('Invalid action:', action);
      process.exit(1);
    }
    if (!currentResource || !defModule) {
      console.log('Missing currentResource or defModule.');
      process.exit(1);
    }

    const payload = await readStdinJson();
    const resources = Array.isArray(payload.resources) ? payload.resources : [];

    let changedCount = 0;
    let skippedCount = 0;
    let failedCount = 0;

    for (const resource of resources) {
      try {
        let result;

        if (action === 'install') {
          result = installer(resource, currentResource, defModule);
        } else {
          result = uninstaller(resource, currentResource, defModule);
        }
        if (result.changed) {
          changedCount++;
          if (action === 'install') {
            console.log(`\x1b[32mInstalled ${defModule} to ${resource.name} successfully.\x1b[0m`);
          } else {
            console.log(`\x1b[32mRemoved ${defModule} reference from ${resource.name}.\x1b[0m`);
          }
        } else {
            skippedCount++;
            console.log(`\x1b[33mSkipped ${resource.name}. Reason: ${result.skippedReason}.\x1b[0m`);
        }
      } catch (err) {
        failedCount++;
        console.log(`\x1b[31mFailed ${resource.name}. Reason: ${err.message}.\x1b[0m`);
      }
    }
    if (action === 'install') {
      console.log(
        `Installed ${defModule} to (${changedCount}), ${skippedCount} skipped, ${failedCount} failed.`
      );
    } else {
      console.log(
        `Uninstalled ${defModule} from (${changedCount}), ${skippedCount} skipped, ${failedCount} failed.`
      );
    }
    process.exit(0);
  } catch (err) {
    console.log('Fatal error:', err.message);
    process.exit(1);
  }
}

function isInstalled(manifest, currentResource, defModule) {
  const pattern = new RegExp(
    String.raw`^\s*shared_script\s+["']@${escapeRegExp(currentResource)}/${escapeRegExp(defModule)}["']\s*(?:--.*)?\n?`,
    'm'
  );
  return pattern.test(normalizeLF(manifest));
}

function ignoreResource(manifest) {
  if (/^\s*author\s+['"]Cfx\.re <root@cfx\.re>['"]/mi.test(manifest)) {
    return 'cfx default resource';
  }

  if (/^\s*ac\s*['"]fg['"]/mi.test(manifest)) {
    return 'fiveguard resource';
  }

  if (/^\s*addon\s*['"]yes['"]/mi.test(manifest)) {
    return 'addon resource';
  }
  return null;
}

function installer(resource, currentResource, defModule) {
  if (!resource || !resource.path || !resource.name) {
    return { changed: false, skippedReason: 'invalid resource data' };
  }
  const manifestPath = path.join(resource.path, 'fxmanifest.lua');
  if (!fs.existsSync(manifestPath)) {
    return { changed: false, skippedReason: 'no fxmanifest.lua' };
  }
  let manifest = fs.readFileSync(manifestPath, 'utf8');
  const ignored = ignoreResource(manifest);
  if (ignored) {
    return {
      changed: false,
      skippedReason: ignored
    };
  }
  if (isInstalled(manifest, currentResource, defModule)) {
    return { changed: false, skippedReason: 'already installed' };
  }
  manifest = normalizeLF(manifest);
  const insertion = `shared_script '@${currentResource}/${defModule}'\n`;
  const newContent = insertion + manifest;
  fs.writeFileSync(manifestPath, newContent, 'utf8');
  return { changed: true };
}

function uninstaller(resource, currentResource, defModule) {
  if (!resource || !resource.path || !resource.name) {
    return { changed: false, skippedReason: 'invalid resource data' };
  }
  const manifestPath = path.join(resource.path, 'fxmanifest.lua');
  if (!fs.existsSync(manifestPath)) {
    return { changed: false, skippedReason: 'no fxmanifest.lua' };
  }
  const manifest = fs.readFileSync(manifestPath, 'utf8');
  const lineRegex = new RegExp(
    String.raw`^\s*shared_script\s+["']@${escapeRegExp(currentResource)}/${escapeRegExp(defModule)}["']\s*(?:--.*)?\r?\n?`,
    'mg'
  );
  if (!lineRegex.test(manifest)) {
    return { changed: false, skippedReason: 'not installed' };
  }
  const newContent = manifest.replace(lineRegex, '');
  fs.writeFileSync(manifestPath, newContent, 'utf8');
  return { changed: true };
}

function fivemMode() {
  let botChild = null;
  let botStopping = false;
  let botStarting = false;
  let botRetry = null;
  let botInstaller = null;
  let botFailures = 0;
  const resourceName = GetCurrentResourceName();
  const botPath = path.join(GetResourcePath(resourceName), 'bot');
  let botPayload;
  async function removeDisabledCommands(config) {
    const token = String(config.botToken || '').trim().replace(/^Bot\s+/, '');
    if (!token || /\s/.test(token)) return;
    const https = require('https');
    async function api(method, route, retries = 0) {
      const result = await new Promise((resolve, reject) => {
        const request = https.request({ hostname: 'discord.com', path: '/api/v10' + route, method,
          headers: { Authorization: 'Bot ' + token, 'User-Agent': 'FiveguardAddon Discord bot' } }, response => {
          let body = '';
          response.setEncoding('utf8');
          response.on('data', chunk => { body += chunk; });
          response.on('error', reject);
          response.on('end', () => {
            try { resolve({ status: response.statusCode, data: body ? JSON.parse(body) : null }); }
            catch { reject(new Error('Invalid Discord response')); }
          });
        });
        request.setTimeout(15000, () => request.destroy(new Error('Discord request timed out')));
        request.on('error', reject); request.end();
      });
      if (result.status === 429 && retries < 2) {
        const delay = Math.min(30000, Math.max(1000, Number(result.data?.retry_after || 1) * 1000));
        await new Promise(resolve => setTimeout(resolve, delay));
        if (botStopping) throw new Error('Resource stopped');
        return api(method, route, retries + 1);
      }
      if (result.status < 200 || result.status >= 300) throw new Error(`Discord HTTP ${result.status}`);
      return result.data;
    }
    try {
      let guildId = config.guildId;
      if (!guildId || guildId === 'auto') {
        const guilds = await api('GET', '/users/@me/guilds?limit=2');
        if (!Array.isArray(guilds) || guilds.length !== 1) throw new Error('guildId=auto requires exactly one guild');
        guildId = guilds[0].id;
      }
      if (!/^\d{1,20}$/.test(guildId)) throw new Error('Invalid guildId');
      const application = await api('GET', '/oauth2/applications/@me');
      const route = `/applications/${application.id}/guilds/${guildId}/commands`;
      const commands = await api('GET', route);
      for (const command of commands) {
        if (command.name === 'fgb' && !botStopping) {
          await api('DELETE', `${route}/${command.id}`);
          botLog('/fgb removed; all bot features are disabled.');
        }
      }
    } catch (error) { botLog(`Could not remove disabled /fgb: ${error.message}`); }
  }
  function botLog(data) {
    let value = String(data).trim();
    const token = botPayload?.config?.botToken;
    if (token) value = value.split(token).join('[redacted]');
    if (value) {
      if (value.startsWith('[Discord bot]')) console.log(value);
      else console.log('[Discord bot]', value);
    }
  }
  function runTool(command, args) {
    return new Promise((resolve, reject) => {
      const child = spawn(command, args, { cwd: botPath, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
      botInstaller = child;
      const timeout = setTimeout(() => { child.kill(); reject(new Error('Dependency check/install timed out')); }, 180000);
      child.stdout.on('data', botLog); child.stderr.on('data', botLog);
      child.once('error', error => { clearTimeout(timeout); botInstaller = null; reject(error); });
      child.once('close', code => { clearTimeout(timeout); botInstaller = null; code === 0 ? resolve() : reject(new Error(`Dependency check/install exited with code ${code}`)); });
    });
  }
  async function startBot() {
    if (botStopping || botStarting || botChild || !botPayload?.run) return;
    botStarting = true;
    try {
      await runTool('node', ['-e', 'if(Number(process.versions.node.split(".")[0])<22 || (Number(process.versions.node.split(".")[0])===22 && Number(process.versions.node.split(".")[1])<12)) process.exit(1)']);
      try {
        await runTool('node', ['-e', 'const fs=require("fs"); const p=require("./package.json"); const lock=require("./package-lock.json"); for(const [n,v] of Object.entries(p.dependencies)) { const expected=lock.packages["node_modules/"+n]; if(lock.packages[""].dependencies[n]!==v || !expected) process.exit(1); require(n); if(JSON.parse(fs.readFileSync("./node_modules/"+n+"/package.json","utf8")).version!==expected.version) process.exit(1); }']);
      } catch {
        if (botStopping) return;
        if (process.platform === 'win32') await runTool('cmd.exe', ['/d', '/s', '/c', 'npm ci --omit=dev --ignore-scripts --no-audit --no-fund']);
        else await runTool('npm', ['ci', '--omit=dev', '--ignore-scripts', '--no-audit', '--no-fund']);
      }
      if (botStopping) return;
      const child = spawn('node', [path.join(botPath, 'index.js')], { cwd: botPath, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe', 'ipc'] });
      botChild = child;
      child.stdout.on('data', botLog); child.stderr.on('data', botLog);
      child.on('error', error => botLog(error.message));
      child.on('message', message => {
        if (botChild !== child || !message || typeof message !== 'object') return;
        if (message.type === 'request') emit('fg:addon:bot:request', JSON.stringify(message));
        else if (message.type === 'roles') emit('fg:addon:bot:roles', JSON.stringify(message));
        else if (message.type === 'ready') { botFailures = 0; emit('fg:addon:bot:ready', JSON.stringify(message)); }
        else if (message.type === 'unavailable') emit('fg:addon:bot:unavailable');
      });
      child.on('close', code => {
        if (botChild === child) botChild = null;
        emit('fg:addon:bot:unavailable');
        if (botStopping) return;
        if (code === 78) { emit('fg:addon:bot:failed', 'Discord startup failed; see bot errors above.'); return; }
        if (++botFailures > 5) {
          botLog('Repeated crashes; automatic restart stopped. Restart addon after fixing the error.');
          emit('fg:addon:bot:failed', 'Repeated crashes; automatic restart stopped.');
          return;
        }
        botRetry = setTimeout(startBot, Math.min(30000, botFailures * 5000));
      });
      child.send({ type: 'init', ...botPayload });
    } catch (error) {
      botLog(`Cannot start: ${error.message}. Check Node.js >=22.12, npm and registry connectivity.`);
      emit('fg:addon:bot:failed', 'Cannot start Discord bot; check Node.js, npm and registry connectivity.');
    }
    finally { botStarting = false; }
  }
  on('fg:addon:bot:start', payload => {
    botPayload = JSON.parse(payload);
    if (botPayload.run) startBot();
    else removeDisabledCommands(botPayload.config);
  });
  on('fg:addon:bot:send', payload => {
    if (botChild?.connected) botChild.send(JSON.parse(payload));
  });
  on('onResourceStop', name => {
    if (name !== resourceName) return;
    botStopping = true;
    clearTimeout(botRetry);
    botInstaller?.kill();
    if (botChild?.connected) botChild.disconnect();
    else botChild?.kill();
  });
  let FiveguardName = null;
  let imBusy = false;

  function readBans() {
    if (!FiveguardName) getResourceEntries();
    if (!FiveguardName) {
      console.log('Fiveguard resource not found!');
      return null;
    }
    try {
      const resourcePath = GetResourcePath(FiveguardName);
      if (!resourcePath) return null;
      const filePath = path.join(resourcePath, 'bans.json');
      if (!fs.existsSync(filePath)) return null;
      const content = fs.readFileSync(filePath, 'utf8');
      try {
        return JSON.parse(content);
      } catch (e) {
        console.log('bans.json parse error:', e.message);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  function getResourceEntries(optionalTarget) {
    const out = [];
    if (optionalTarget) {
      const resourcePath = GetResourcePath(optionalTarget);
      if (resourcePath) {
        out.push({
          name: optionalTarget,
          path: resourcePath
        });
      } else {
        console.log(`Resource not found: ${optionalTarget}`);
      }
      return out;
    }
    const count = GetNumResources();
    for (let i = 0; i < count; i++) {
      const name = GetResourceByFindIndex(i);
      if (!name) continue;
      const resourcePath = GetResourcePath(name);
      if (!resourcePath) continue;
      out.push({
        name,
        path: resourcePath
      });
      if (FiveguardName === null) {
        const ac = GetResourceMetadata(name, 'ac');
        if (ac === 'fg') {
          FiveguardName = name;
        }
      }
    }
    return out;
  }

  function runInstallMode(action, defModule, optionalTarget) {
    return new Promise((resolve) => {
      const currentResource = GetCurrentResourceName();
      const currentResourcePath = GetResourcePath(currentResource);
      const scriptPath = path.join(currentResourcePath, 'server', 'sv_resourceManager.js');
      const resources = getResourceEntries(optionalTarget);
      if (!resources.length) {
        console.log('No target resources found.');
        resolve(false);
        return;
      }
      try {
        const child = spawn(
          'node',
          [
            scriptPath,
            '--install-mode',
            action,
            currentResource,
            defModule
          ],
          {
            cwd: currentResourcePath,
            windowsHide: true,
            stdio: ['pipe', 'pipe', 'pipe']
          }
        );
        child.stdin.write(JSON.stringify({ resources }));
        child.stdin.end();
  
        child.stdout.on('data', (data) => {
          const text = data.toString().trim();
          if (text) console.log(text);
        });
        child.stderr.on('data', (data) => {
          const text = data.toString().trim();
          if (text) console.log(text);
        });
        child.on('error', (err) => {
          console.log(`Error: ${err.message}`);
          resolve(false);
        });
        child.on('close', (code) => {
          if (code === 0) {
            resolve(true);
          } else {
            console.log(`Warning, exit with code ${code}`);
            resolve(false);
          }
        });
      } catch (err) {
        console.log(`\x1b[31mError: ${err.message}\x1b[0m`);
        resolve(false);
        return;
      }
    });
  }

  RegisterCommand('fga', async (source, args) => {
    if (source !== 0) return;
    if (imBusy) {
      console.log('Command already running, please wait...');
      return;
    }
    imBusy = true;
    try {
      switch (args[0]) {
        case 'help': {
          console.log('fiveguard documentation: https://docs.fiveguard.net');
          console.log('FIVEGUARD ADDON COMMANDS');
          console.log('         fga help');
          console.log('         fga unban <all|range> [range: <minId> <maxId>]');
          console.log('         fga bypass-native <install|uninstall> [optional: resourceName]');
          console.log('         fga xss <install|uninstall> [optional: resourceName]');
          break;
        }
        case 'bypass-native': {
          const target = args[2];
          switch (args[1]) {
            case 'install': {
              const ok = await runInstallMode('install', 'bypassNative.lua', target);
              if (ok) console.log('\x1b[31mRestart Server to apply the changes\x1b[0m');
              break;
            }
            case 'uninstall': {
              const ok = await runInstallMode('uninstall', 'bypassNative.lua', target);
              if (ok) console.log('\x1b[31mRestart Server to apply the changes\x1b[0m');
              break;
            }
            default: {
              console.log('Usage: fga bypass-native <install|uninstall> [resourceName]');
              break;
            }
          }
          break;
        }
        case 'xss': {
          const target = args[2];
          switch (args[1]) {
            case 'install': {
              const ok = await runInstallMode('install', 'xss.lua', target);
              if (ok) console.log('\x1b[31mRestart Server to apply the changes\x1b[0m');
              break;
            }
            case 'uninstall': {
              const ok = await runInstallMode('uninstall', 'xss.lua', target);
              if (ok) console.log('\x1b[31mRestart Server to apply the changes\x1b[0m');
              break;
            }
            default: {
              console.log('Usage: fga xss <install|uninstall> [resourceName]');
              break;
            }
          }
          break;
        }
        case 'unban': {
          switch (args[1]) {
            case 'all': {
              const bans = readBans();
              if (!bans) {console.log('No bans found!'); break;}
              let executed = 0;
              for (const banId in bans) {
                if (Number.isInteger(Number(banId))) {
                  exports[FiveguardName].UnbanId(banId);
                  executed++;
                }
              }
              console.log(`Successfully unbanned all users (${executed})`);
              break;
            }
            case 'range': {
              const bans = readBans();
              if (!bans) {console.log('No bans found!'); break;}
              if (args.length < 4) {
                console.log('Usage: fga unban range <minId> <maxId>');
                return;
              }
              const a = Number(args[2]);
              const b = Number(args[3]);
              if (!Number.isFinite(a) || !Number.isFinite(b)) {
                console.log('Invalid range. Use integers: fga unban range <minId> <maxId>');
                return;
              }
              const min = Math.min(a, b);
              const max = Math.max(a, b);
              let executed = 0;
              for (const key in bans) {
                const id = Number(key);
                if (Number.isInteger(id) && id >= min && id <= max) {
                  exports[FiveguardName].UnbanId(id);
                  executed++;
                }
              }
              console.log(`Successfully unbanned ${executed} users`);
              break;
            }
            default: {
              console.log('Specified command does not exists, use command fga help to get more information');
              break;
            }
          }
          break;
        }
        default: {
          console.log('Specified command does not exists, use command fga help to get more information');
          break;
        }
      }
    } finally {
      imBusy = false;
    }
  }, true);
}
