// Shared instrumentation for the Hono, Express and Fastify apps: payload, CPU work and headers.
// build.sh copies this file into each app's src/ before compiling, so all three apps report
// exactly the same headers and timings.
import { createHash, randomUUID } from 'node:crypto';
import { performance } from 'node:perf_hooks';

export const ENV_ID = randomUUID();
const cpuStart = process.cpuUsage();
let importMs = 0;
let bootMs = 0;
let requests = 0;

// About 1 KB of JSON, built once per process.
export const PAYLOAD = Object.freeze({
  id: 'b6c1a0f2-0000-4000-8000-000000000000',
  items: Array.from({ length: 10 }, (_, i) => ({
    id: i,
    name: `item-${i}`,
    price: 9.99 + i,
    tags: ['alpha', 'beta', 'gamma'],
  })),
});

// Call as the first statement of index.ts. ESM evaluates all imports first,
// so this marks the time spent loading the framework.
export function markImported(): void {
  importMs = performance.now();
}

// Call when the server reports it is listening.
export function markListening(framework: string): void {
  bootMs = performance.now();
  console.log(JSON.stringify({ event: 'app.boot', framework, envId: ENV_ID, importMs, bootMs }));
}

// Web Functions pass the listen address as "host:port".
export function listenAddress(): { host: string; port: number } {
  const raw = process.env.AWS_LAMBDA_HTTP_ENDPOINT ?? '127.0.0.1:3000';
  const idx = raw.lastIndexOf(':');
  return { host: raw.slice(0, idx), port: Number(raw.slice(idx + 1)) };
}

export function parseMs(raw: unknown): number {
  const n = Number(raw ?? 50);
  return Number.isFinite(n) ? Math.min(Math.max(n, 0), 5000) : 50;
}

export function parseN(raw: unknown): number {
  const n = Number(raw ?? 1000);
  return Number.isFinite(n) ? Math.min(Math.max(Math.floor(n), 0), 1_000_000) : 1000;
}

// Fixed CPU work for /cpu: n chained SHA-256 rounds over the ~1 KB payload. Both deployments do
// the same work for the same n, so CPU time per request compares directly.
// Not a process.cpuUsage() busy loop: that counter is per process, and a Web Function environment
// runs many requests at once. On Graviton (Node 24), n = 35272 is about 100 ms of CPU.
const PAYLOAD_BYTES = Buffer.from(JSON.stringify(PAYLOAD));
export function cpuWork(n: number): string {
  let digest: Buffer = PAYLOAD_BYTES;
  for (let i = 0; i < n; i++) digest = createHash('sha256').update(digest).update(PAYLOAD_BYTES).digest();
  return digest.toString('hex').slice(0, 16);
}

export const sleep = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

export function instrumentHeaders(framework: string): Record<string, string> {
  requests += 1;
  return {
    'x-env-id': ENV_ID,
    'x-req-n': String(requests),
    'x-import-ms': importMs.toFixed(1),
    'x-boot-ms': bootMs.toFixed(1),
    'x-uptime-ms': performance.now().toFixed(1),
    'x-framework': framework,
  };
}

export function meta(framework: string) {
  const cpu = process.cpuUsage(cpuStart);
  return {
    framework,
    envId: ENV_ID,
    importMs,
    bootMs,
    uptimeMs: performance.now(),
    requests,
    cpuUserUs: cpu.user,
    cpuSystemUs: cpu.system,
    node: process.version,
    region: process.env.AWS_REGION ?? 'local',
    nonce: process.env.COLD_NONCE ?? null,
  };
}
