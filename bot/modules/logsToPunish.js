'use strict';
function create(config, guildId, request, now = Date.now) {
  const counts = new Map();
  function prune(time) {
    for (const [key, entry] of counts) {
      entry.times = entry.times.filter(t => time - t < entry.window);
      if (!entry.times.length && !entry.busy) counts.delete(key);
    }
  }
  return async function handle(message) {
    if (!config?.enable || message.guildId !== guildId || !message.webhookId) return;
    const time = now(); prune(time);
    for (const embed of message.embeds || []) {
      if (embed.title !== 'Logs' || embed.author?.name !== 'Fiveguard.net') continue;
      try { if (new URL(embed.url).hostname !== 'fiveguard.net') continue; } catch { continue; }
      const fields = Object.fromEntries((embed.fields || []).map(f => [f.name, f.value]));
      const option = fields['Additional Info']?.match(/(?:^|\n)Config Option:\s*([\w.]+)/)?.[1];
      const rule = config.options?.[option];
      if (!rule || rule.channelId !== message.channelId) continue;
      if (rule.punishment !== 'ban' && rule.punishment !== 'kick') continue;
      if (!Number.isSafeInteger(rule.threshold) || rule.threshold < 1 || !Number.isFinite(rule.windowSeconds) || rule.windowSeconds <= 0) continue;
      const license = fields.License?.trim().replace(/^`+|`+$/g, '');
      const reason = fields.Violation?.trim();
      if (!/^license:[a-fA-F0-9]+$/.test(license || '') || !reason) continue;
      const key = `${license}/${option}`;
      const entry = counts.get(key) || { times: [], window: rule.windowSeconds * 1000, busy: false };
      counts.set(key, entry);
      if (entry.busy) continue;
      entry.times.push(time);
      if (entry.times.length < rule.threshold) continue;
      entry.busy = true;
      try {
        await request('logsToPunish', { identifier: license, reason, option });
      } catch (error) { console.error('[Discord bot] [Logs To Punish]', error.message); }
      finally { counts.delete(key); }
    }
  };
}
module.exports = { create };
