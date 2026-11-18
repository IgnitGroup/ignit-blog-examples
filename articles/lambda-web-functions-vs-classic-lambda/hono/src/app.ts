// Routes shared by the Web Function entry (index.ts) and the classic Lambda entry (lambda.ts),
// so both deployments run the same app code.
import { Hono } from 'hono';
import { PAYLOAD, cpuWork, instrumentHeaders, meta, parseMs, parseN, sleep } from './common.js';

export const FW = 'hono';
export const app = new Hono();

app.get('/json', (c) => {
  for (const [k, v] of Object.entries(instrumentHeaders(FW))) c.header(k, v);
  return c.json(PAYLOAD);
});

app.get('/io', async (c) => {
  const ms = parseMs(c.req.query('ms'));
  await sleep(ms);
  for (const [k, v] of Object.entries(instrumentHeaders(FW))) c.header(k, v);
  return c.json({ waitedMs: ms });
});

app.get('/cpu', (c) => {
  const n = parseN(c.req.query('n'));
  const digest = cpuWork(n);
  for (const [k, v] of Object.entries(instrumentHeaders(FW))) c.header(k, v);
  return c.json({ rounds: n, digest });
});

app.get('/meta', (c) => {
  for (const [k, v] of Object.entries(instrumentHeaders(FW))) c.header(k, v);
  return c.json(meta(FW));
});
