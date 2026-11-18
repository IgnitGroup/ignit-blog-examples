// Web Function bundle, shared by the three apps. build.sh runs it from each app's directory,
// so paths resolve against that app: src/index.ts -> dist/index.js, one minified ESM file,
// no node_modules. No import from 'rolldown' here: each app's own rolldown CLI loads this file.
export default {
  input: 'src/index.ts',
  platform: 'node',
  treeshake: true,
  transform: {
    target: 'node24',
  },
  resolve: {
    // Sources import './common.js' (NodeNext style); the file on disk is common.ts.
    extensionAlias: { '.js': ['.ts', '.js'] },
  },
  output: {
    dir: 'dist',
    format: 'esm',
    // The runtime runs index.js at the zip root.
    entryFileNames: 'index.js',
    codeSplitting: false,
    minify: true,
    keepNames: true,
    sourcemap: false,
  },
}
