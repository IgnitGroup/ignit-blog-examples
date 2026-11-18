import express from 'express';
import { PAYLOAD, cpuWork, instrumentHeaders, listenAddress, markImported, markListening, meta, parseMs, parseN, sleep } from './common.js';

markImported();
const FW = 'express';
const app = express();
// Keep Express on par with Hono and Fastify: no extra header, no body hashing.
app.disable('x-powered-by');
app.disable('etag');

app.get('/json', (_req, res) => {
  res.set(instrumentHeaders(FW)).json(PAYLOAD);
});

app.get('/io', async (req, res) => {
  const ms = parseMs(req.query.ms);
  await sleep(ms);
  res.set(instrumentHeaders(FW)).json({ waitedMs: ms });
});

app.get('/cpu', (req, res) => {
  const n = parseN(req.query.n);
  const digest = cpuWork(n);
  res.set(instrumentHeaders(FW)).json({ rounds: n, digest });
});

app.get('/meta', (_req, res) => {
  res.set(instrumentHeaders(FW)).json(meta(FW));
});

const { host, port } = listenAddress();
app.listen(port, host, () => markListening(FW));
