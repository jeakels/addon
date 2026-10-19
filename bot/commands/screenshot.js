'use strict';
module.exports = {
  name: 'screenshot',
  description: 'Capture a player screen',
  build: sub => sub.addIntegerOption(o => o.setName('server-id').setDescription('server-id').setMinValue(1).setRequired(true)),
  execute: (options, bridge) => bridge.request('screenshot', { serverId: options.getInteger('server-id') })
};
