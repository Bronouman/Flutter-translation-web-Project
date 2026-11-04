'use strict';

const { send, route } = require('./_lib');

module.exports = route('POST', async (data, res) => {
  const text = data.text;
  if (typeof text !== 'string' || !text.trim()) {
    return send(res, 400, { error: 'Please enter text to detect.' });
  }
  let language = 'en';
  if (/[\u0600-\u06FF]/.test(text)) language = 'ar';
  else if (/[\u0400-\u04FF]/.test(text)) language = 'ru';
  else if (/[\u0900-\u097F]/.test(text)) language = 'hi';
  return send(res, 200, { language });
});
