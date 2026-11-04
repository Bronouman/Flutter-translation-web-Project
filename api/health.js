'use strict';

const { send, route } = require('./_lib');

module.exports = route('GET', async (_data, res) => send(res, 200, { status: 'ok' }));
