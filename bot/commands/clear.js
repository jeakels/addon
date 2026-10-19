'use strict';
module.exports = {
  name: 'clear',
  description: 'Clear entities',
  build: sub => sub.addStringOption(o => o.setName('type').setDescription('Entity type').setRequired(true).addChoices(...['ped', 'vehicles', 'objects', 'all'].map(value => ({ name: value, value })))),
  execute: (options, bridge) => bridge.request('clear', { kind: options.getString('type') })
};
