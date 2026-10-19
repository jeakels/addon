'use strict';
module.exports = {
  name: 'offlineban', description: 'Ban an identifier or Discord user',
  build: sub => sub.addStringOption(o => o.setName('reason').setDescription('Reason').setMaxLength(512).setRequired(true))
    .addStringOption(o => o.setName('identifier').setDescription('FiveM identifier').setMaxLength(128))
    .addUserOption(o => o.setName('user').setDescription('Discord user')),
  execute(options, bridge) {
    const identifier = options.getString('identifier');
    const user = options.getUser('user');
    if (!!identifier === !!user) throw new Error('Choose exactly one: identifier or user.');
    return bridge.request('offlineban', { identifier: user ? `discord:${user.id}` : identifier, reason: options.getString('reason') });
  }
};
