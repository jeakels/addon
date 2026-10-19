'use strict';
module.exports = {
  name: 'check',
  description: 'Show ban details',
  build: sub => sub.addIntegerOption(o => o.setName('ban-id').setDescription('ban-id').setMinValue(1).setRequired(true)),
  execute: (options, bridge) => bridge.request('check', { banId: options.getInteger('ban-id') })
};
