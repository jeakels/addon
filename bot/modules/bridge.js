'use strict';
module.exports = function bridge(channel = process) {
  let sequence = 0;
  const pending = new Map();
  const handlers = new Map();
  const send = message => { if (channel.connected) channel.send(message); };
  channel.on('message', async message => {
    if (message.type === 'result') {
      const job = pending.get(message.id);
      if (!job) return;
      clearTimeout(job.timer); pending.delete(message.id);
      message.error ? job.reject(new Error(message.error)) : job.resolve(message.value);
    } else if (handlers.has(message.type)) {
      try { await handlers.get(message.type)(message); }
      catch (error) { console.error('[Discord bot]', error.message); }
    }
  });
  channel.on('disconnect', () => {
    for (const job of pending.values()) { clearTimeout(job.timer); job.reject(new Error('FXServer disconnected')); }
    pending.clear();
  });
  return {
    send,
    on: (type, handler) => handlers.set(type, handler),
    request(action, args = {}) {
      return new Promise((resolve, reject) => {
        if (!channel.connected) return reject(new Error('FXServer disconnected'));
        const id = ++sequence;
        const timer = setTimeout(() => { pending.delete(id); reject(new Error('FXServer request timed out')); }, 150000);
        pending.set(id, { resolve, reject, timer });
        send({ type: 'request', id, action, args });
      });
    }
  };
};
