'use strict';

const { LANG_RE, MAX_SPEAK, send, route, speakText } = require('./_lib');

module.exports = route('POST', async (data, res) => {
  const text = data.text;
  const language = data.language === undefined || data.language === null ? 'en' : data.language;
  if (typeof text !== 'string' || !text.trim()) {
    return send(res, 400, { error: 'Please enter text to speak.' });
  }
  if (text.trim().length > MAX_SPEAK) {
    return send(res, 400, {
      error: `Text is too long to speak. Please keep it under ${MAX_SPEAK} characters.`,
    });
  }
  if (typeof language !== 'string' || !LANG_RE.test(language)) {
    return send(res, 400, { error: 'Please select a valid language.' });
  }
  try {
    const audio = await speakText(text.trim(), language);
    return send(res, 200, { audio: `data:audio/mp3;base64,${audio.toString('base64')}` });
  } catch (error) {
    console.error('Speech generation failed:', error);
    return send(res, 502, { error: 'The speech service could not generate audio. Please try again shortly.' });
  }
});
