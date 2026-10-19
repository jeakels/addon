'use strict';
module.exports = {
  name: 'unban',
  description: 'Remove a ban',
  build: sub => sub.addIntegerOption(o => o.setName('ban-id').setDescription('ban-id').setMinValue(1).setRequired(true)),
  async execute(options, bridge) {
    const banId = options.getInteger('ban-id');
    const result = await bridge.request('unban', { banId });
    if (typeof result === 'string') return result;
    return `Player with ban ID ${banId} unbanned successfully.`;
  }
};
