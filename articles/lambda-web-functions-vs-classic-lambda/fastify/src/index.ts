import Fastify from 'fastify';
import { PAYLOAD, cpuWork, instrumentHeaders, listenAddress, markImported, markListening, meta, parseMs, parseN, sleep } from './common.js';

markImported();
const FW = 'fastify';
const app = Fastify({ logger: false });

app.get('/json', async (_req, reply) => {
  reply.headers(instrumentHeaders(FW));
  return PAYLOAD;
});

app.get<{ Querystring: { ms?: string } }>('/io', async (req, reply) => {
  const ms = parseMs(req.query.ms);
  await sleep(ms);
  reply.headers(instrumentHeaders(FW));
  return { waitedMs: ms };
});

app.get<{ Querystring: { n?: string } }>('/cpu', async (req, reply) => {
  const n = parseN(req.query.n);
  const digest = cpuWork(n);
  reply.headers(instrumentHeaders(FW));
  return { rounds: n, digest };
});

app.get('/meta', async (_req, reply) => {
  reply.headers(instrumentHeaders(FW));
  return meta(FW);
});

const { host, port } = listenAddress();
await app.listen({ host, port });
markListening(FW);
