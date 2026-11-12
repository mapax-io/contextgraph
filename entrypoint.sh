#!/bin/sh
# codegraph-mcp entrypoint: sync the repos, index them, serve MCP over HTTP.
#
#   REPOS          comma-separated https git URLs. Private github.com ones
#                  authenticate with GIT_TOKEN.
#   GIT_TOKEN      read-only token used for every github.com clone/pull.
#                  Never logged, never served; stored 0600 inside /data.
#   REINDEX_HOURS  re-pull + re-index cycle (default 24). 0 = index once.
#
# The graph database is self-contained: once a repo is indexed, queries
# never touch the clone again — the cycle only keeps the graph fresh.
set -u
export HOME=/data
mkdir -p /data/repos

if [ -n "${GIT_TOKEN:-}" ]; then
  umask 077
  printf 'https://x-access-token:%s@github.com\n' "$GIT_TOKEN" \
    > /data/.git-credentials
  umask 022
  git config --global credential.helper 'store --file /data/.git-credentials'
fi
git config --global --add safe.directory '*'
export GIT_TERMINAL_PROMPT=0

sync_all() {
  printf '%s\n' "${REPOS:-}" | tr ',' '\n' | while read -r url; do
    url=$(printf '%s' "$url" | tr -d '[:space:]')
    [ -z "$url" ] && continue
    name=$(basename "$url" .git)
    if [ -d "/data/repos/$name/.git" ]; then
      echo "[sync] pull $name"
      git -C "/data/repos/$name" pull --ff-only \
        || echo "[sync] WARN pull failed: $name (serving the last good index)"
    else
      echo "[sync] clone $name"
      git clone --depth 1 "$url" "/data/repos/$name" \
        || { echo "[sync] WARN clone failed: $name"; continue; }
    fi
    echo "[index] $name"
    cgc index "/data/repos/$name" \
      || echo "[index] WARN failed: $name"
  done
}

sync_all

hours=${REINDEX_HOURS:-24}
case "$hours" in
  ''|*[!0-9]*) hours=24 ;;
esac
if [ "$hours" -gt 0 ]; then
  (
    while :; do
      sleep $(( hours * 3600 ))
      echo "[cycle] re-sync after ${hours}h"
      sync_all
    done
  ) &
fi

echo "[serve] mcp-proxy on :8900 (streamable HTTP /mcp, SSE /sse)"
exec mcp-proxy --host 0.0.0.0 --port 8900 -- cgc mcp start
