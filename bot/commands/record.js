'use strict';
module.exports = {
  name: 'record',
  description: 'Record a player screen',
  build: sub => sub.addIntegerOption(o => o.setName('server-id').setDescription('server-id').setMinValue(1).setRequired(true)).addIntegerOption(o => o.setName('seconds').setDescription('Duration; default from config').setMinValue(1).setMaxValue(60)),
  execute: (options, bridge) => bridge.request('record', { serverId: options.getInteger('server-id'), seconds: options.getInteger('seconds') })
};
