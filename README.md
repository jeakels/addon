# Fiveguard Addon
This resource extends **Fiveguard** by allowing you to manage permissions, bypasses, and advanced security checks for your FiveM server.
---
## 📑 Index
* [Installation](#-installation)
* [Main Features](#%EF%B8%8F-main-features)
  * [Permissions Management](#-permissions-management)
  * [Discord Bot](#-discord-bot)
  * [Security Systems](#-security-systems)
  * [Anti XSS Injection](#-anti-xss-injection)
  * [Bypasses & Temporary Permissions](#%EF%B8%8F-bypasses--temporary-permissions)
  * [Natives with bypass](#-natives-with-integrated-bypass)
  * [Ban Management](#-ban-management)
  * [Nickname Management](#-nickname-management)
  * [Logging & Media Evidence](#-logging-with-media-evidence)
* [Credits](#-credits)
---
## 📥 Installation
1. [Download](https://github.com/jeakels/addon/releases/latest/download/addon.zip) the script
2. Configure the `config.lua` file as needed
3. Add `ensure addon` after Fiveguard in `server.cfg`, then restart the server
4. Check the [documentation](https://gabjeksuper.gitbook.io/fiveguard-configuration/addon/package-addon) for further information and help if needed
---
## ⚙️ Main Features
### 🔒 Permissions Management
Supports:
* **Ace** (FiveM native permission system using server.cfg)
* **txAdmin** (txAdmin admins)
* **Discord** (users by Discord IDs or guild roles)
* **Frameworks** (ESX, QBCore, QBox, vRP and custom frameworks)
---
### 🤖 Discord Bot
Manage your server directly from Discord with a command to:
* Ban, kick and unban players
* Check ban details
* Clear vehicles, peds and objects
* Request screenshots and screen recordings

The bot can also **automatically ban or kick after repeated Fiveguard logs**, with configurable log counts and time windows through `logsToPunish`.
---
### 🚨 Security Systems
* **Heartbeat** → prevents client-side stop attempts
* **Crash Protection** → prevents cheaters from crashing players by blocking specific known exploits
* **Anti Stopper** → prevents resource stopping exploits
* **Anti Safe Spawn** → safe vehicle spawn checks
* **Weapon Protection** → blocks weapons not owned by the player and damage from excessive distances
* **Inventory Sync** → disarms players holding a weapon missing from their inventory
---
### 🔰 Anti XSS Injection
Protects against script injection, install in a resource with:
* `fga xss install [resourceName]`
---
### 🛡️ Bypasses & Temporary Permissions
Preconfigured for:
* **rcore\_clothing**
* **rcore\_prison**
* **lsrp\_lunapark**
* **rtx\_themepark**
* **rtx\_mazebank\_themepark**
* **rtx\_waterpark**
* **rtx\_waterpark\_roxwood**
* **rtx\_spawnableattractions**
* **ik-jobgarage**
* **jg-advancedgarages**
* **jg-dealerships**
* **jg-mechanic**
* **wasabi\_police**
* **qb-prison**
---
### 🧰 Natives with integrated bypass
* `exports['addon']:SafeSetEntityCoords` → replaces `SetEntityCoords`
* `exports['addon']:SafeSetEntityVisible` → replaces `SetEntityVisible`
* `exports['addon']:SafeSetPedComponentVariation` → bypass for clothing changes

or installing directly in the resource using the command:
* `fga bypass-native [install/uninstall] [resourceName]`
---
### ⛔ Ban Management
Manage bans directly with Fiveguard Addon commands:
* `fga unban all` → unban all players
* `fga unban range [minId - maxId]` → unban a specific range of IDs
---
### 📜 Nickname Management
* Minimum and maximum length
* Configurable allowed characters
---
### 📡 Logging with Media Evidence
* Video from fiveguard API
* Screenshot from fiveguard API
---
## 🙌 Credits
Addon developed by **Jeakels** with the support of the community and powered by fiveguard, the best anticheat in the market!
* 🌐 [fiveguard Site](https://fiveguard.net)
* 💬 [Fiveguard Discord](https://discord.gg/fiveguard)
* 💬 [Fiveguard Documentation](https://docs.fiveguard.net)
