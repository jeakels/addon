const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

if (process.argv[2] === "--install-mode") {
  installMode();
} else {
  fivemMode();
}

function escapeRegExp(str) {
  return String(str).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeLF(content) {
  return String(content)
    .replace(/^\uFEFF/, "")
    .replace(/\r\n/g, "\n")
    .replace(/\r/g, "\n")
    .replace(/\n*$/, "\n");
}

function readStdinJson() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", chunk => {
      data += chunk;
    });
    process.stdin.on("end", () => {
      try {
        resolve(JSON.parse(data || "{}"));
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
    if (!["install", "uninstall"].includes(action)) {
      console.log("Invalid action:", action);
      process.exit(1);
    }
    if (!currentResource || !defModule) {
      console.log("Missing currentResource or defModule.");
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

        if (action === "install") {
          result = installer(resource, currentResource, defModule);
        } else {
          result = uninstaller(resource, currentResource, defModule);
        }
        if (result.changed) {
          changedCount++;
          if (action === "install") {
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
    if (action === "install") {
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
    console.log("Fatal error:", err.message);
    process.exit(1);
  }
}

function isInstalled(manifest, currentResource, defModule) {
  const pattern = new RegExp(
    String.raw`^\s*shared_script\s+["']@${escapeRegExp(currentResource)}/${escapeRegExp(defModule)}["']\s*(?:--.*)?\n?`,
    "m"
  );
  return pattern.test(normalizeLF(manifest));
}

function ignoreResource(manifest) {
  if (/^\s*author\s+['"]Cfx\.re <root@cfx\.re>['"]/mi.test(manifest)) {
    return "cfx default resource";
  }

  if (/^\s*ac\s*['"]fg['"]/mi.test(manifest)) {
    return "fiveguard resource";
  }

  if (/^\s*addon\s*['"]yes['"]/mi.test(manifest)) {
    return "addon resource";
  }
  return null;
}

function installer(resource, currentResource, defModule) {
  if (!resource || !resource.path || !resource.name) {
    return { changed: false, skippedReason: "invalid resource data" };
  }
  const manifestPath = path.join(resource.path, "fxmanifest.lua");
  if (!fs.existsSync(manifestPath)) {
    return { changed: false, skippedReason: "no fxmanifest.lua" };
  }
  let manifest = fs.readFileSync(manifestPath, "utf8");
  const ignored = ignoreResource(manifest);
  if (ignored) {
    return {
      changed: false,
      skippedReason: ignored
    };
  }
  if (isInstalled(manifest, currentResource, defModule)) {
    return { changed: false, skippedReason: "already installed" };
  }
  manifest = normalizeLF(manifest);
  const insertion = `shared_script "@${currentResource}/${defModule}"\n`;
  const newContent = insertion + manifest;
  fs.writeFileSync(manifestPath, newContent, "utf8");
  return { changed: true };
}

function uninstaller(resource, currentResource, defModule) {
  if (!resource || !resource.path || !resource.name) {
    return { changed: false, skippedReason: "invalid resource data" };
  }
  const manifestPath = path.join(resource.path, "fxmanifest.lua");
  if (!fs.existsSync(manifestPath)) {
    return { changed: false, skippedReason: "no fxmanifest.lua" };
  }
  const manifest = fs.readFileSync(manifestPath, "utf8");
  const lineRegex = new RegExp(
    String.raw`^\s*shared_script\s+["']@${escapeRegExp(currentResource)}/${escapeRegExp(defModule)}["']\s*(?:--.*)?\r?\n?`,
    "mg"
  );
  if (!lineRegex.test(manifest)) {
    return { changed: false, skippedReason: "not installed" };
  }
  const newContent = manifest.replace(lineRegex, "");
  fs.writeFileSync(manifestPath, newContent, "utf8");
  return { changed: true };
}

function fivemMode() {
  let FiveguardName = null;
  let imBusy = false;

  function readBans() {
    if (!FiveguardName) getResourceEntries();
    if (!FiveguardName) {
      console.log("Fiveguard resource not found!");
      return null;
    }
    try {
      const resourcePath = GetResourcePath(FiveguardName);
      if (!resourcePath) return null;
      const filePath = path.join(resourcePath, "bans.json");
      if (!fs.existsSync(filePath)) return null;
      const content = fs.readFileSync(filePath, "utf8");
      try {
        return JSON.parse(content);
      } catch (e) {
        console.log("bans.json parse error:", e.message);
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
        const ac = GetResourceMetadata(name, "ac");
        if (ac === "fg") {
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
      const scriptPath = path.join(currentResourcePath, "server", "sv_resourceManager.js");
      const resources = getResourceEntries(optionalTarget);
      if (!resources.length) {
        console.log("No target resources found.");
        resolve(false);
        return;
      }
      try {
        const child = spawn(
          "node",
          [
            scriptPath,
            "--install-mode",
            action,
            currentResource,
            defModule
          ],
          {
            cwd: currentResourcePath,
            windowsHide: true,
            stdio: ["pipe", "pipe", "pipe"]
          }
        );
        child.stdin.write(JSON.stringify({ resources }));
        child.stdin.end();
  
        child.stdout.on("data", (data) => {
          const text = data.toString().trim();
          if (text) console.log(text);
        });
        child.stderr.on("data", (data) => {
          const text = data.toString().trim();
          if (text) console.log(text);
        });
        child.on("error", (err) => {
          console.log(`Error: ${err.message}`);
          resolve(false);
        });
        child.on("close", (code) => {
          if (code === 0) {
            resolve(true);
          } else {
            console.log(`Warning, exit with code ${code}`);
            resolve(false);
          }
        });
      } catch (err) {
        if (err.message.includes("Access to this API has been restricted. Use --allow-child-process to manage permissions.")) {
            console.log(`\x1b[31mError: Add \x1b[0madd_unsafe_child_process_permission ${currentResource}\x1b[31m to your server.cfg before starting this resource!\x1b[0m`);
        } else console.log(`\x1b[31mError: ${err.message}\x1b[0m`);
          resolve(false);
          return;
      }
    });
  }

  RegisterCommand("fga", async (source, args) => {
    if (source !== 0) return;
    if (imBusy) {
      console.log("Command already running, please wait...");
      return;
    }
    imBusy = true;
    try {
      switch (args[0]) {
        case "help": {
          console.log("fiveguard documentation: https://docs.fiveguard.net");
          console.log("FIVEGUARD ADDON COMMANDS");
          console.log("         fga help");
          console.log("         fga unban <all|range> [range: <minId> <maxId>]");
          console.log("         fga bypass-native <install|uninstall> [optional: resourceName]");
          console.log("         fga xss <install|uninstall> [optional: resourceName]");
          break;
        }
        case "bypass-native": {
          const target = args[2];
          switch (args[1]) {
            case "install": {
              const ok = await runInstallMode("install", "bypassNative.lua", target);
              if (ok) console.log("\x1b[31mRestart Server to apply the changes\x1b[0m");
              break;
            }
            case "uninstall": {
              const ok = await runInstallMode("uninstall", "bypassNative.lua", target);
              if (ok) console.log("\x1b[31mRestart Server to apply the changes\x1b[0m");
              break;
            }
            default: {
              console.log("Usage: fga bypass-native <install|uninstall> [resourceName]");
              break;
            }
          }
          break;
        }
        case "xss": {
          const target = args[2];
          switch (args[1]) {
            case "install": {
              const ok = await runInstallMode("install", "xss.lua", target);
              if (ok) console.log("\x1b[31mRestart Server to apply the changes\x1b[0m");
              break;
            }
            case "uninstall": {
              const ok = await runInstallMode("uninstall", "xss.lua", target);
              if (ok) console.log("\x1b[31mRestart Server to apply the changes\x1b[0m");
              break;
            }
            default: {
              console.log("Usage: fga xss <install|uninstall> [resourceName]");
              break;
            }
          }
          break;
        }
        case "unban": {
          switch (args[1]) {
            case "all": {
              const bans = readBans();
              if (!bans) {console.log("No bans found!"); break;}
              let executed = 0;
              for (const banId in bans) {
                if (Number.isInteger(Number(banId))) {
                  ExecuteCommand(`fg unban ${banId}`);
                  executed++;
                }
              }
              console.log(`Successfully unbanned all users (${executed})`);
              break;
            }
            case "range": {
              const bans = readBans();
              if (!bans) {console.log("No bans found!"); break;}
              if (args.length < 4) {
                console.log("Usage: fga unban range <minId> <maxId>");
                return;
              }
              const a = Number(args[2]);
              const b = Number(args[3]);
              if (!Number.isFinite(a) || !Number.isFinite(b)) {
                console.log("Invalid range. Use integers: fga unban range <minId> <maxId>");
                return;
              }
              const min = Math.min(a, b);
              const max = Math.max(a, b);
              let executed = 0;
              for (const key in bans) {
                const id = Number(key);
                if (Number.isInteger(id) && id >= min && id <= max) {
                  ExecuteCommand(`fg unban ${id}`);
                  executed++;
                }
              }
              console.log(`Successfully unbanned ${executed} users`);
              break;
            }
            default: {
              console.log("Specified command does not exists, use command fga help to get more information");
              break;
            }
          }
          break;
        }
        default: {
          console.log("Specified command does not exists, use command fga help to get more information");
          break;
        }
      }
    } finally {
      imBusy = false;
    }
  }, true);
}
