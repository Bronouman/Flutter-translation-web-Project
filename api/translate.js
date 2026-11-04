'use strict';

const { LANG_RE, MAX_TRANSLATE, send, route, translateText } = require('./_lib');

module.exports = route('POST', async (data, res) => {
  const text = data.text;
  const destination = data.dest_lang_code;
  if (typeof text !== 'string' || !text.trim()) {
    return send(res, 400, { error: 'Please enter text to translate.' });
  }
  if (text.trim().length > MAX_TRANSLATE) {
    return send(res, 400, {
      error: `Text is too long. Please keep it under ${MAX_TRANSLATE} characters.`,
    });
  }
  if (typeof destination !== 'string' || !LANG_RE.test(destination)) {
    return send(res, 400, { error: 'Please select a valid target language.' });
  }
  try {
    const result = await translateText(text.trim(), destination);
    if (!result.trim()) throw new Error('Empty translation');
    return send(res, 200, { result });
  } catch (error) {
    console.error('Translation failed:', error);
    return send(res, 502, {
      error: 'Translation service is temporarily unavailable. Please try again shortly.',
    });
  }
});
