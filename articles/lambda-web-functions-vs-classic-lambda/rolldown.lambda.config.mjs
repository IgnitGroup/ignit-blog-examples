// Classic Lambda bundle (Hono only): src/lambda.ts -> dist-lambda/index.mjs (handler: index.handler).
// .mjs makes Node load it as ESM without a package.json.
import base from './rolldown.config.mjs';

export default {
  ...base,
  input: 'src/lambda.ts',
  output: { ...base.output, dir: 'dist-lambda', entryFileNames: 'index.mjs' },
};
