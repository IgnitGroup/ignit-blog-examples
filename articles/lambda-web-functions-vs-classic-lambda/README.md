# Hono, Express and Fastify on Lambda Web Functions and classic Lambda

The apps from our blog post [Lambda Web Functions vs classic Lambda: we ran the benchmarks](https://ignit.group/blog/lambda-web-functions-vs-classic-lambda-we-ran-the-benchmarks), comparing AWS Lambda Web Functions with classic Lambda. These are the same apps we measured, built the same way.

| Target | Entry | Build output | Runs as |
|---|---|---|---|
| `hono` | `hono/src/index.ts` | `hono/dist.zip` (`index.js`) | Lambda Web Function, Node.js 24, Arm64 |
| `express` | `express/src/index.ts` | `express/dist.zip` (`index.js`) | Lambda Web Function, Node.js 24, Arm64 |
| `fastify` | `fastify/src/index.ts` | `fastify/dist.zip` (`index.js`) | Lambda Web Function, Node.js 24, Arm64 |
| `hono-lambda` | `hono/src/lambda.ts` | `hono/dist-lambda.zip` (`index.mjs`, handler `index.handler`) | Classic Lambda, `nodejs24.x`, Arm64, Function URL |

The Web Function and classic Lambda comparison uses Hono only. Both Hono targets serve the same routes from `hono/src/app.ts`. Express and Fastify were used for the cold start comparison between frameworks.

Each target is bundled into a single minified file with no `node_modules`.

## Layout

```
shared/common.ts            payload, CPU work and instrumentation, copied into each app at build time
hono/ express/ fastify/     one app each, with its own package.json and lockfile
build.sh                    type-check, bundle and zip
smoke.sh                    local test of the built apps
rolldown.config.mjs         Web Function bundle config (all three apps)
rolldown.lambda.config.mjs  classic Lambda bundle config (Hono)
```

## Routes

All three apps serve the same routes.

| Route | What it does |
|---|---|
| `GET /json` | Returns about 1 KB of JSON |
| `GET /io?ms=N` | Waits N ms on a timer (0-5000, default 50). Stands in for a database or API call |
| `GET /cpu?n=K` | Runs K chained SHA-256 rounds (default 1000). On Graviton, K = 35272 is about 100 ms of CPU |
| `GET /meta` | Process info: framework, environment ID, uptime, request count, CPU used |

Every response carries `x-framework`, `x-env-id`, `x-req-n`, `x-import-ms`, `x-boot-ms` and `x-uptime-ms` headers. A cold request has `x-req-n: 1`.

## Build

Needs Node.js 24, pnpm, `zip`, and `curl` and `jq` for the smoke test.

```bash
./build.sh all          # all four targets
./build.sh express      # one target: hono, express, fastify or hono-lambda
./smoke.sh              # starts each built app locally and checks the routes
```

## Run locally

A Web Function passes its listen address in `AWS_LAMBDA_HTTP_ENDPOINT` (`host:port`). Without it the server listens on `127.0.0.1:3000`.

```bash
./build.sh fastify
node fastify/dist/index.js
curl "localhost:3000/io?ms=50"
```

## Deploy

Web Function (the AWS CLI creates a default S3 bucket and execution role unless you pass `--bucket-name` and `--execution-role-arn`). Swap `hono` for `express` or `fastify` to deploy the others:

```bash
./build.sh hono
aws lambda-web deploy --name hono-web --code hono/dist --create --region eu-west-1
```

Classic Lambda with a public Function URL (`ROLE_ARN` is an execution role with basic Lambda permissions):

```bash
./build.sh hono-lambda
aws lambda create-function --function-name hono-classic \
  --runtime nodejs24.x --architectures arm64 --handler index.handler \
  --memory-size 1024 --timeout 30 --role "$ROLE_ARN" \
  --zip-file fileb://hono/dist-lambda.zip --region eu-west-1
aws lambda create-function-url-config --function-name hono-classic --auth-type NONE --region eu-west-1
aws lambda add-permission --function-name hono-classic --statement-id public-url \
  --action lambda:InvokeFunctionUrl --principal '*' --function-url-auth-type NONE --region eu-west-1
aws lambda add-permission --function-name hono-classic --statement-id public-url-invoke \
  --action lambda:InvokeFunction --principal '*' --invoked-via-function-url --region eu-west-1
```

A public endpoint can be called by anyone. Delete the functions when you're done.
