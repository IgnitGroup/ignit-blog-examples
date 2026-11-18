#!/usr/bin/env bash
# Type-check, bundle and zip one target, or all of them.
#   ./build.sh hono          -> hono/dist.zip            (Lambda Web Function)
#   ./build.sh express       -> express/dist.zip         (Lambda Web Function)
#   ./build.sh fastify       -> fastify/dist.zip         (Lambda Web Function)
#   ./build.sh hono-lambda   -> hono/dist-lambda.zip     (classic Lambda + Function URL)
#   ./build.sh all           -> all four
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
USAGE="usage: build.sh <hono|express|fastify|hono-lambda|all>"

build() {
  local target=$1 fw dist config
  case "$target" in
    hono|express|fastify) fw=$target; dist=dist; config=rolldown.config.mjs ;;
    hono-lambda) fw=hono; dist=dist-lambda; config=rolldown.lambda.config.mjs ;;
    *) echo "$USAGE" >&2; exit 1 ;;
  esac
  cd "$ROOT/$fw"
  cp ../shared/common.ts src/common.ts
  rm -rf "$dist" "$dist.zip"
  [[ -d node_modules ]] || pnpm install --frozen-lockfile
  # tsc only type-checks; rolldown strips types without checking them.
  pnpm exec tsc -p tsconfig.json --noEmit
  pnpm exec rolldown -c "../$config"
  # The Web Function bundle is ESM index.js; without "type": "module" Node would load it as CommonJS.
  # The classic Lambda bundle is index.mjs, which Node always loads as ESM.
  [[ "$dist" != dist ]] || echo '{"type":"module"}' > dist/package.json
  # Match `aws lambda-web deploy`, which leaves hidden files and dirs out of the package.
  (cd "$dist" && zip -qr -X "../$dist.zip" . -x '.*' -x '*/.*')
  echo "built $fw/$dist.zip ($(wc -c < "$dist.zip" | tr -d ' ') bytes)"
}

if [[ "${1:?$USAGE}" == all ]]; then
  for t in hono express fastify hono-lambda; do build "$t"; done
else
  build "$1"
fi
