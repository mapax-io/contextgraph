#!/bin/sh
# contextgraph one-command install — RunPod, a VPS, or any docker host:
#
#   git clone https://github.com/mapax-io/contextgraph && cd contextgraph && ./install.sh
#
# Makes .env with a strong random token (never printed, never overwritten),
# builds and starts the stack, and says where the MCP endpoint is. Needs
# docker with the compose plugin; python3 is used when present, otherwise a
# python container generates the .env.
set -e
cd "$(dirname "$0")"

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose is required (Docker Engine with the compose plugin)." >&2
  exit 1
fi

if [ ! -f .env ]; then
  if command -v python3 >/dev/null 2>&1; then
    python3 make_env.py
  else
    docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/w python:3.12-slim \
      python /w/make_env.py /w
  fi
  FRESH_ENV=1
else
  echo ".env already exists — keeping its secrets."
  FRESH_ENV=0
fi

if [ "$FRESH_ENV" = "1" ]; then
  cat <<'EDIT'

.env created. Before the graph means anything, tell it what to index:

  1. edit .env and set REPOS (comma-separated https git URLs)
  2. for private github repos, set GIT_TOKEN (fine-grained PAT, Contents: read)
  3. run ./install.sh again

EDIT
  exit 0
fi

docker compose up -d --build

HTTP_PORT=$(grep -E '^HTTP_PORT=' .env | cut -d= -f2)
HTTP_PORT=${HTTP_PORT:-8080}

cat <<DONE

contextgraph is up. First indexing runs now — watch it with:
  docker compose logs -f cgc

  MCP endpoint : http://<this box's address>:${HTTP_PORT}/mcp
  Bearer token : read it yourself with  grep CODEGRAPH_TOKEN .env
                 (never paste it into a chat)

Attach it to your MCP client (NeuralOps, Claude, …):
  transport  streamable HTTP
  URL        the endpoint above
  auth       bearer / static secret = the token

For HTTPS, set DOMAIN in .env and start with
  docker compose -f docker-compose.yaml -f docker-compose.tls.yaml up -d
DONE
