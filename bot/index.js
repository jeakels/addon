'use strict';
const { Client, GatewayIntentBits, ApplicationFlagsBitField } = require('discord.js');
const bridge = require('./modules/bridge')();
let client;
let cleanupGuild;
let commandRegistration;
let stopping = false;
async function shutdown() {
  if (stopping) return;
  stopping = true;
  const timeout = setTimeout(() => process.exit(0), 5000);
  try {
    await commandRegistration;
    if (cleanupGuild) await require('./modules/commands').register(client, cleanupGuild, false);
  } catch (error) { console.warn('[Discord bot] Could not remove /fgb during shutdown:', error.message); }
  finally {
    try { await client?.destroy(); }
    finally { clearTimeout(timeout); process.exit(0); }
  }
}
bridge.on('init', async ({ config, permissions, sync }) => {
  if (client) return;
  const token = String(config.botToken || '').trim().replace(/^Bot\s+/, '');
  if (!token || /\s/.test(token)) { console.error('[Discord bot] Configure discordBot.botToken.'); process.exit(78); return; }
  const startupTimeout = setTimeout(() => { console.error('[Discord bot] Connection startup timed out.'); process.exit(1); }, 90000);
  const probe = new Client({ intents: [GatewayIntentBits.Guilds] });
  try {
    const problems = [];
    await probe.login(token);
    await new Promise(resolve => { if (probe.isReady()) resolve(); else probe.once('clientReady', resolve); });
    const application = await probe.application.fetch();
    const flags = application.flags;
    const members = flags.has(ApplicationFlagsBitField.Flags.GatewayGuildMembers) || flags.has(ApplicationFlagsBitField.Flags.GatewayGuildMembersLimited);
    const content = flags.has(ApplicationFlagsBitField.Flags.GatewayMessageContent) || flags.has(ApplicationFlagsBitField.Flags.GatewayMessageContentLimited);
    if (config.logsToPunish?.enable) {
      for (const [name, rule] of Object.entries(config.logsToPunish.options || {})) {
        const errors = [];
        if (!rule || typeof rule !== 'object') errors.push('option settings must be a table');
        else {
          if (typeof rule.channelId !== 'string' || !/^\d{1,20}$/.test(rule.channelId)) errors.push('invalid channelId');
          if (rule.punishment !== 'ban' && rule.punishment !== 'kick') errors.push('punishment is required and must be ban or kick');
          if (!Number.isSafeInteger(rule.threshold) || rule.threshold < 1) errors.push('threshold must be a positive integer');
          if (!Number.isFinite(rule.windowSeconds) || rule.windowSeconds <= 0) errors.push('windowSeconds must be a positive number');
        }
        if (errors.length) {
          problems.push(`Invalid logsToPunish option ${name}: ${errors.join('; ')}`);
          console.warn(`[Discord bot] [Logs To Punish] ^3Invalid configuration for ${name}: ${errors.join('; ')}. Option ignored.^0`);
          delete config.logsToPunish.options[name];
        }
      }
    }
    const intents = [GatewayIntentBits.Guilds];
    if (sync && members) intents.push(GatewayIntentBits.GuildMembers);
    if (sync && !members) console.warn('[Discord bot] Enable Server Members Intent in Developer Portal > Bot > Privileged Gateway Intents. Role changes use HTTP fallback.');
    if (config.logsToPunish?.enable && content) intents.push(GatewayIntentBits.GuildMessages, GatewayIntentBits.MessageContent);
    if (config.logsToPunish?.enable && !content) console.warn('[Discord bot] Enable Message Content Intent in Developer Portal > Bot > Privileged Gateway Intents. Logs To Punish disabled; slash commands remain available.');
    if (config.logsToPunish?.enable && !content) problems.push('Logs To Punish requires Message Content Intent');
    const logsToPunish = !!config.logsToPunish?.enable && content && Object.keys(config.logsToPunish.options || {}).length > 0;
    if (config.logsToPunish?.enable && !Object.keys(config.logsToPunish.options || {}).length) problems.push('No valid logsToPunish options configured');
    await probe.destroy();
    client = new Client({ intents });
    client.on('error', error => console.error('[Discord bot]', error.message));
    client.on('shardReconnecting', () => bridge.send({ type: 'unavailable' }));
    client.on('shardDisconnect', event => {
      bridge.send({ type: 'unavailable' });
      if ([4004, 4013, 4014].includes(event.code)) { console.error('[Discord bot] Gateway rejected credentials/intents; check Developer Portal.'); process.exit(78); }
    });
    client.once('clientReady', async () => {
      try {
        const id = config.guildId;
        const automatic = !id || id === 'auto';
        if (automatic && client.guilds.cache.size !== 1) throw new Error('guildId=auto requires exactly one guild; configure its ID.');
        const guild = automatic ? client.guilds.cache.first() : await client.guilds.fetch(id);
        if (stopping) return;
        cleanupGuild = guild;
        if (sync) require('./modules/permissions').attach(client, guild, bridge);
        const commands = require('./modules/commands');
        if (config.commands) commands.attach(client, guild, permissions, bridge);
        if (config.commands) {
          commandRegistration = commands.register(client, guild, true);
          await commandRegistration;
        }
        else {
          try { await commands.register(client, guild, false); }
          catch (error) { console.warn('[Discord bot] Could not remove disabled /fgb:', error.message); }
        }
        if (stopping) return;
        if (logsToPunish) {
          const handle = require('./modules/logsToPunish').create(config.logsToPunish, guild.id, bridge.request);
          client.on('messageCreate', message => handle(message).catch(error => console.error('[Discord bot] [Logs To Punish]', error.message)));
        }
        const ready = { type: 'ready', guildId: guild.id, memberEvents: !!sync && members,
          features: { commands: !!config.commands, logsToPunish, roles: !!sync }, problem: problems.join('; ') || undefined };
        bridge.send(ready);
        clearTimeout(startupTimeout);
        const notifyReady = () => {
          if (!stopping) bridge.send(ready);
        };
        client.on('shardResume', notifyReady);
        client.on('shardReady', notifyReady);
      } catch (error) { console.error('[Discord bot]', error.message); process.exit(78); }
    });
    await client.login(token);
  } catch (error) {
    console.error('[Discord bot] Startup failed:', String(error.message).replaceAll(token, '[redacted]'));
    await probe.destroy(); process.exit(78);
  }
});
process.on('disconnect', shutdown);
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
