# Fiveguard Addon
This resource extends **Fiveguard** by allowing you to manage permissions, bypasses, and advanced security checks for your FiveM server.
---
## 📑 Index
* [Installation](#-installation)
* [Main Features](#%EF%B8%8F-main-features)
  * [Permissions Management](#-permissions-management)
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
3. Check the [documentation](https://gabjeksuper.gitbook.io/fiveguard-configuration/addon/package-addon) for further information and help if needed
---
## ⚙️ Main Features
### 🔒 Permissions Management
Supports:
* **Ace Permissions** (FiveM native)
* **Framework Permissions** (ESX, QBCore, QBox, vRP – also custom)
* **txAdmin** (automatic permissions for admins)
---
### 🚨 Security Systems
* **Heartbeat** → prevents client-side stop attempts
* **Crash Protection** → prevents cheaters from crashing players by blocking specific known exploits
* **Anti Stopper** → prevents resource stopping exploits
* **Anti Carry** → blocks carry exploit (safe zones supported)
* **Anti Ped Manipulation** → prevents ped manipulation
* **Anti Safe Spawn** → safe vehicle spawn checks
* **Anti Spawn Vehicle** → prevents unauthorized spawns (resource whitelist)
* **Weapon Protection** → AntiGiveWeapon & AntiDistanceDamage (range check)
* **Anti Explosions** → blocks unauthorized explosions
* **Blacklisted Models** → prevents banned ped/animal models
---
### 🔰 Anti XSS Injection
Protects against script injection, install in a resource with:
* `fga xss install [resourceName]`
---
### 🛡️ Bypasses & Temporary Permissions
Preconfigured for:
* **rcore\_clothing**
* **lsrp\_lunapark**
* **rtx\_themepark**
* **ik-jobgarage**
* **jg-advancedgarages**
* **jg-dealerships**
* **rcore\_prison**
* **wasabi\_police**
* **qb-police**
---
### 🧰 Natives with integrated bypass
* `exports['addon']:SafeSetEntityCoords` → replaces `SetEntityCoords`
* `exports['addon']:SafeSetEntityVisible` → replaces `SetEntityVisible`
or using the commands:
* `fga help` → shows available commands
* `fga bypass-native [install/uninstall] [resourceName]`
---
### ⛔ Ban Management
Manage bans directly with Fiveguard Addon commands:
* `fga unban all` → unban all players
* `fga unban range [minId - maxId]` → unban a specific range of IDs
---
### 📜 Nickname Management
* Maximum length (default: 25)
* Configurable allowed characters
---
### 📡 Logging with Media Evidence
* **Discord Webhook** support (screenshots or video proofs)
* Configurable `RecordTime` (default: 5s)
---
## 🙌 Credits
Addon developed by **Jeakels** with the support of the community and powered by fiveguard, the best anticheat in the market!
* 🌐 [fiveguard.net](https://fiveguard.net)
* 💬 [Fiveguard Discord](https://discord.gg/fiveguard)
