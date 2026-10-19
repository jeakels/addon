'use strict';
function resolve(config, id, roles, guildId) {
  const list = value => Array.isArray(value) ? value : [];
  if (Object.hasOwn(config.users || {}, id)) return list(config.users[id]);
  const held = new Set([guildId, ...roles]);
  for (const entry of Array.isArray(config.roles) ? config.roles : []) {
    const [roleId, permissions] = Object.entries(entry)[0] || [];
    if (held.has(roleId)) return list(permissions);
  }
  return [];
}
function canCommand(permissions) {
  return permissions.some(value => ['FGCommands', 'Misc', 'Misc.*', '*'].includes(value));
}
function attach(client, guild, bridge) {
  const revisions = new Map();
  const advance = id => { const revision = (revisions.get(id) || 0) + 1; revisions.set(id, revision); return revision; };
  async function publish(id) {
    const revision = advance(id);
    try {
      const member = await guild.members.fetch({ user: id, force: true });
      if (revisions.get(id) !== revision) return;
      bridge.send({ type: 'roles', userId: id, roles: [...member.roles.cache.keys()] });
    } catch (error) {
      if (revisions.get(id) !== revision) return;
      if (error.code === 10007) bridge.send({ type: 'roles', userId: id, roles: [] });
      else console.error('[Discord bot] [Permissions] Member lookup failed:', error.message);
    }
  }
  bridge.on('lookup', message => publish(message.userId));
  client.on('guildMemberUpdate', (_, member) => {
    if (member.guild.id === guild.id) { advance(member.id); bridge.send({ type: 'roles', userId: member.id, roles: [...member.roles.cache.keys()] }); }
  });
  client.on('guildMemberRemove', member => {
    if (member.guild.id === guild.id) { advance(member.id); bridge.send({ type: 'roles', userId: member.id, roles: [] }); }
  });
}
module.exports = { resolve, canCommand, attach };
