'use strict';
module.exports = {
  name: 'help',
  description: 'List commands',
  build: sub => sub,
  execute: (options, bridge) => Promise.resolve('/fgb ban <server-id> <reason>\n/fgb kick <server-id> <reason>\n/fgb unban <ban-id>\n/fgb check <ban-id>\n/fgb offlineban <reason> [identifier | user]\n/fgb clear <ped | vehicles | objects | all>\n/fgb record <server-id> [seconds]\n/fgb screenshot <server-id>\n/fgb unban-all (console only)\n/fgb help')
};
