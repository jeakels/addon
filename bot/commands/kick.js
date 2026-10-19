'use strict';
module.exports = {
  name: 'kick',
  description: 'Kick a player',
  build: sub => sub.addIntegerOption(o => o.setName('server-id').setDescription('server-id').setMinValue(1).setRequired(true)).addStringOption(o => o.setName('reason').setDescription('Reason').setMaxLength(512).setRequired(true)),
  execute: (options, bridge) => bridge.request('kick', { serverId: options.getInteger('server-id'), reason: options.getString('reason') })
};
