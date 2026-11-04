'use strict';

const LANG_RE = /^[a-zA-Z]{2,3}(-[a-zA-Z0-9]+)?$/;
const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36';

const MAX_TRANSLATE = 5000;
const MAX_SPEAK = 1000;
const TRANSLATE_CHUNK = 700;
const SPEAK_CHUNK = 180;

function send(res, status, body) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  res.end(JSON.stringify(body));
}

async function readBody(req) {
  let body;
  try {
    body = req.body;
  } catch (_) {
    return null;
  }
  if (body === undefined) {
    try {
      const chunks = [];
      for await (const chunk of req) chunks.push(Buffer.from(chunk));
      body = Buffer.concat(chunks).toString('utf8');
    } catch (_) {
      return null;
    }
  }
  if (Buffer.isBuffer(body)) body = body.toString('utf8');
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (_) {
      return null;
    }
  }
  return body && typeof body === 'object' && !Array.isArray(body) ? body : null;
}

// Wraps a handler: CORS preflight, method check, body parsing, and a JSON
// error for anything unexpected so the client never receives HTML/plain text.
function route(method, fn) {
  return async (req, res) => {
    try {
      if (req.method === 'OPTIONS') {
        res.statusCode = 204;
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
        res.end();
        return;
      }
      if (req.method !== method) {
        res.setHeader('Allow', `${method}, OPTIONS`);
        send(res, 405, { error: `Method not allowed. Use ${method}.` });
        return;
      }
      let data = null;
      if (method === 'POST') {
        data = await readBody(req);
        if (data === null) {
          send(res, 400, { error: 'Request body must be a valid JSON object.' });
          return;
        }
      }
      await fn(data, res);
    } catch (error) {
      console.error('Unhandled request error:', error);
      if (!res.headersSent) {
        send(res, 500, { error: 'Internal server error. Please try again.' });
      }
    }
  };
}

function codeCandidates(code) {
  const lower = code.toLowerCase();
  const out = [code];
  if (lower !== code) out.push(lower);
  if (lower === 'iw') out.push('he');
  if (lower === 'he') out.push('iw');
  return [...new Set(out)];
}

function splitText(text, maxLength) {
  const chunks = [];
  let current = '';
  const flush = () => {
    if (current) chunks.push(current);
    current = '';
  };
  const add = (piece) => {
    if (current.length + piece.length > maxLength) flush();
    current += piece;
  };
  const sentences =
    text.match(/[^.!?\n。！？۔]*[.!?\n。！？۔]+|[^.!?\n。！？۔]+/g) || [];
  for (const sentence of sentences) {
    if (sentence.length <= maxLength) {
      add(sentence);
      continue;
    }
    for (const word of sentence.match(/\S+\s*/g) || []) {
      if (word.length <= maxLength) {
        add(word);
        continue;
      }
      flush();
      const chars = Array.from(word);
      for (let i = 0; i < chars.length; i += maxLength) {
        chunks.push(chars.slice(i, i + maxLength).join(''));
      }
    }
  }
  flush();
  return chunks;
}

async function timedFetch(url, ms, headers) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    return await fetch(url, { headers, signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const TRANSLATE_HOSTS = [
  'https://translate.googleapis.com/translate_a/single',
  'https://translate.google.com/translate_a/single',
];

async function translateOnce(text, code) {
  let lastError;
  for (const host of TRANSLATE_HOSTS) {
    for (let attempt = 0; attempt < 2; attempt++) {
      try {
        const url =
          host +
          '?' +
          new URLSearchParams({
            client: 'gtx',
            sl: 'auto',
            tl: code,
            dt: 't',
            ie: 'UTF-8',
            oe: 'UTF-8',
            q: text,
          });
        const response = await timedFetch(url, 15000, {
          'User-Agent': UA,
          Accept: 'application/json, text/plain, */*',
        });
        if (response.status === 429 || response.status >= 500) {
          lastError = new Error(`Provider HTTP ${response.status}`);
          await sleep(400);
          continue;
        }
        if (!response.ok) {
          lastError = new Error(`Provider HTTP ${response.status}`);
          break; // bad request for this code/host; do not retry the same call
        }
        const data = JSON.parse(await response.text());
        if (!Array.isArray(data) || !Array.isArray(data[0])) {
          lastError = new Error('Unexpected provider response');
          break;
        }
        return data[0]
          .map((segment) => (Array.isArray(segment) ? segment[0] || '' : ''))
          .join('');
      } catch (error) {
        lastError = error;
        await sleep(300);
      }
    }
  }
  throw lastError || new Error('Translation failed');
}

async function translateChunk(text, candidates) {
  let lastError;
  for (const code of [...candidates]) {
    try {
      const result = await translateOnce(text, code);
      candidates.splice(candidates.indexOf(code), 1);
      candidates.unshift(code);
      return result;
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError || new Error('No supported language code.');
}

async function translateText(text, code) {
  const candidates = codeCandidates(code);
  let output = '';
  for (const chunk of splitText(text, TRANSLATE_CHUNK)) {
    if (!chunk.trim()) {
      output += chunk;
      continue;
    }
    const lead = chunk.match(/^\s*/)[0];
    const trail = chunk.match(/\s*$/)[0];
    output += lead + (await translateChunk(chunk.trim(), candidates)) + trail;
  }
  return output;
}

async function ttsChunk(text, code) {
  const url =
    'https://translate.google.com/translate_tts?' +
    new URLSearchParams({ ie: 'UTF-8', q: text, tl: code, client: 'tw-ob' });
  let lastStatus = 0;
  for (let attempt = 0; attempt < 2; attempt++) {
    const response = await timedFetch(url, 15000, {
      'User-Agent': UA,
      Referer: 'https://translate.google.com/',
    });
    lastStatus = response.status;
    if (response.ok) {
      const bytes = Buffer.from(await response.arrayBuffer());
      if (bytes.length > 0) return bytes;
    }
    if (response.status !== 429 && response.status < 500) break;
    await sleep(400);
  }
  throw new Error(`TTS provider HTTP ${lastStatus}`);
}

async function speakText(text, language) {
  const chunks = splitText(text, SPEAK_CHUNK)
    .map((c) => c.trim())
    .filter(Boolean);
  const candidates = codeCandidates(language);
  const parts = [];
  for (const chunk of chunks) {
    let bytes;
    let lastError;
    for (const code of [...candidates]) {
      try {
        bytes = await ttsChunk(chunk, code);
        candidates.splice(candidates.indexOf(code), 1);
        candidates.unshift(code);
        break;
      } catch (error) {
        lastError = error;
      }
    }
    if (!bytes) throw lastError || new Error('TTS failed');
    parts.push(bytes);
  }
  return Buffer.concat(parts);
}

module.exports = {
  LANG_RE,
  MAX_TRANSLATE,
  MAX_SPEAK,
  send,
  route,
  translateText,
  speakText,
};
