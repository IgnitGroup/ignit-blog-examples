#!/usr/bin/env bash
# Local smoke test: start each built app and check status codes, x-* headers,
# x-req-n incrementing, /io timing and /cpu. If hono/dist-lambda exists (./build.sh
# hono-lambda), also invoke the classic Lambda handler with a Function URL event.
# Needs curl and jq. Usage: ./smoke.sh [fw ...]
set -euo pipefail

cd "$(dirname "$0")"
PORT=3000
FWS=("$@"); [[ $# -gt 0 ]] || FWS=(hono express fastify)
fail=0

check() { if [[ "$2" == "ok" ]]; then echo "  ok   $1"; else echo "  FAIL $1 ($2)"; fail=1; fi; }

for fw in "${FWS[@]}"; do
  echo "== $fw"
  AWS_LAMBDA_HTTP_ENDPOINT="127.0.0.1:$PORT" node "$fw/dist/index.js" &
  pid=$!
  trap 'kill $pid 2>/dev/null || true' EXIT
  for _ in $(seq 50); do curl -s -o /dev/null "http://127.0.0.1:$PORT/json" && break; sleep 0.1; done

  base="http://127.0.0.1:$PORT"
  h1=$(curl -s -D - -o /dev/null "$base/json")
  h2=$(curl -s -D - -o /dev/null "$base/json")
  code=$(echo "$h1" | head -1 | awk '{print $2}')
  check "/json status 200" "$([[ $code == 200 ]] && echo ok || echo "$code")"
  for h in x-env-id x-req-n x-import-ms x-boot-ms x-uptime-ms x-framework; do
    check "header $h" "$(echo "$h1" | grep -qi "^$h:" && echo ok || echo missing)"
  done
  n1=$(echo "$h1" | grep -i '^x-req-n:' | tr -d '\r' | awk '{print $2}')
  n2=$(echo "$h2" | grep -i '^x-req-n:' | tr -d '\r' | awk '{print $2}')
  check "x-req-n increments ($n1 -> $n2)" "$([[ $n2 -eq $((n1 + 1)) ]] && echo ok || echo no)"
  etag=$(echo "$h1" | grep -ci '^etag:' || true)
  echo "  info etag headers: $etag"

  t=$(curl -s -o /dev/null -w '%{time_total}' "$base/io?ms=200")
  check "/io?ms=200 took ${t}s" "$(awk -v t="$t" 'BEGIN{print (t >= 0.2 && t < 0.4) ? "ok" : "bad"}')"
  cpu=$(curl -s "$base/cpu?n=2000")
  check "/cpu?n=2000 rounds" "$([[ $(jq -r .rounds <<< "$cpu") == 2000 ]] && echo ok || echo "$cpu")"
  mcode=$(curl -s -o /dev/null -w '%{http_code}' "$base/meta")
  check "/meta status 200" "$([[ $mcode == 200 ]] && echo ok || echo "$mcode")"
  curl -s "$base/meta" | jq -c '{framework, importMs, bootMs, requests, node}'

  kill $pid; wait $pid 2>/dev/null || true
  trap - EXIT
done

if [[ -f hono/dist-lambda/index.mjs ]]; then
  echo "== hono-lambda (handler invoked with a Function URL payload v2 event)"
  # Two calls in one process: the second must see x-req-n 2, like a warm Lambda sandbox.
  out=$(node --input-type=module -e '
    const { handler } = await import(process.argv[1]);
    const ev = (path, qs) => ({
      version: "2.0", routeKey: "$default", rawPath: path, rawQueryString: qs, headers: { host: "local" },
      requestContext: { domainName: "local", http: { method: "GET", path, protocol: "HTTP/1.1", sourceIp: "127.0.0.1", userAgent: "smoke" } },
      isBase64Encoded: false,
    });
    const a = await handler(ev("/cpu", "n=2000"), {});
    const b = await handler(ev("/io", "ms=50"), {});
    console.log(JSON.stringify({ a: a.statusCode, b: b.statusCode, rounds: JSON.parse(a.body).rounds, n: b.headers["x-req-n"] }));
  ' "$PWD/hono/dist-lambda/index.mjs" | tail -1)
  check "lambda /cpu 200, /io 200, rounds 2000, x-req-n 2 ($out)" \
    "$(jq -e '.a == 200 and .b == 200 and .rounds == 2000 and .n == "2"' <<< "$out" > /dev/null && echo ok || echo bad)"
fi

exit $fail
