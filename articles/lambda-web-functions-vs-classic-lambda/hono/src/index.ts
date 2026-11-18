import { serve } from '@hono/node-server';
import { FW, app } from './app.js';
import { listenAddress, markImported, markListening } from './common.js';

markImported();
const { host, port } = listenAddress();
serve({ fetch: app.fetch, hostname: host, port }, () => markListening(FW));
