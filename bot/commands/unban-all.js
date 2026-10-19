'use strict';
module.exports = {
  name: 'unban-all',
  description: 'Console-only operation',
  build: sub => sub,
  execute: (options, bridge) => Promise.resolve('For safety, use the console with the command: fga unban all.')
};
