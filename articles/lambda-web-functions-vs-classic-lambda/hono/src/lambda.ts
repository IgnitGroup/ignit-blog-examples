// Classic Lambda entry: the same Hono app behind a Lambda Function URL.
// Built by `./build.sh hono-lambda` into hono/dist-lambda/index.mjs (handler: index.handler).
import { handle } from '@hono/aws-lambda';
import { FW, app } from './app.js';
import { markImported, markListening } from './common.js';

markImported();
// There is no server to listen; log app.boot here so both entries report import time the same way.
markListening(FW);
export const handler = handle(app);
