'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { SlashCommandBuilder, MessageFlags } = require('discord.js');
const { resolve, canCommand } = require('./permissions');
const commands = fs.readdirSync(path.join(__dirname, '../commands')).filter(f => f.endsWith('.js')).map(f => require(`../commands/${f}`));
const definition = new SlashCommandBuilder().setName('fgb').setDescription('FiveGuard administration');
for (const command of commands) definition.addSubcommand(sub => command.build(sub.setName(command.name).setDescription(command.description)));
async function register(client, guild, enabled = true) {
  const existing = await guild.commands.fetch();
  const current = existing.find(c => c.name === 'fgb');
  if (!enabled) {
    if (current) await guild.commands.delete(current.id);
    return;
  }
  if (current) await guild.commands.edit(current.id, definition.toJSON());
  else await guild.commands.create(definition.toJSON());
}
function attach(client, guild, settings, bridge) {
  client.on('interactionCreate', async interaction => {
    if (!interaction.isChatInputCommand() || interaction.commandName !== 'fgb' || interaction.guildId !== guild.id) return;
    try {
      await interaction.deferReply({ flags: MessageFlags.Ephemeral });
      const ace = await bridge.request('commandPermission', { discordId: interaction.user.id });
      if (ace?.allowed !== true) {
        const member = await guild.members.fetch({ user: interaction.user.id, force: true });
        const effective = resolve(settings, member.id, [...member.roles.cache.keys()], guild.id);
        if (!canCommand(effective)) return await interaction.editReply('Permission denied: FGCommands or Misc required.');
      }
      const command = commands.find(c => c.name === interaction.options.getSubcommand());
      if (!command) throw new Error('Unknown command');
      const user = interaction.options.getUser('user');
      const target = interaction.options.getInteger('server-id')
        ?? interaction.options.getInteger('ban-id')
        ?? interaction.options.getString('identifier')
        ?? (user ? `discord:${user.id}` : null)
        ?? interaction.options.getString('type');
      let destination = '';
      const color = (value, code) => `^${code}${String(value).replace(/[\r\n]|\^[0-9]/g, ' ')}^0`;
      if (target !== null && target !== undefined) {
        if (command.name === 'clear') destination = ` for ${color(target, 5)}`;
        else if (command.name === 'offlineban') destination = ` for identifier ${color(target, 5)}`;
        else destination = ` for id ${color(target, 5)}`;
      }
      let details = '';
      const reason = interaction.options.getString('reason');
      if (reason) details = ` with reason ${color(reason, 3)}`;
      if (command.name === 'record') {
        const seconds = interaction.options.getInteger('seconds');
        details += seconds === null ? ` using the ${color('configured default duration', 3)}` : ` for ${color(seconds, 3)} seconds`;
      }
      console.log(`${color(interaction.user.username, 5)} issued the command ${color(command.name, 2)}${destination}${details}`);
      const value = await command.execute(interaction.options, bridge);
      const content = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
      const response = { allowedMentions: { parse: [] } };
      if (content.length > 1900) response.files = [{ attachment: Buffer.from(content), name: 'fiveguard-result.txt' }];
      else response.content = content || 'Completed.';
      await interaction.editReply(response);
    } catch (error) {
      console.error('[Discord bot] [Commands]', error.message);
      if (interaction.deferred) await interaction.editReply({ content: `Error: ${error.message}`.slice(0, 1900), allowedMentions: { parse: [] } }).catch(() => {});
    }
  });
}
module.exports = { register, attach, definition };
