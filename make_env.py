"""Create codegraph-mcp/.env with a strong random token — never printed.

    python3 make_env.py           # or, without python on the host:
    docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/w python:3.12-slim python /w/make_env.py /w

Refuses to touch an existing .env (secrets are created once, never
regenerated). Read the token back for your MCP client's dialog with:

    grep CODEGRAPH_TOKEN .env     # read it yourself — never paste it in a chat
"""
import os
import secrets
import sys

folder = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))
path = os.path.join(folder, ".env")
if os.path.exists(path):
    sys.exit(f"{path} already exists — refusing to overwrite secrets.")

lines = [
    "# Created by make_env.py — keep it private; never commit it.",
    f"CODEGRAPH_TOKEN={secrets.token_urlsafe(48)}",
    "# Comma-separated https git URLs to index, e.g.",
    "#   REPOS=https://github.com/owner/repo-a.git,https://github.com/owner/repo-b.git",
    "REPOS=",
    "# Read-only token for private github.com repos (fine-grained PAT,",
    "# Contents: read). Leave empty for public repos.",
    "GIT_TOKEN=",
    "# Re-pull + re-index cycle in hours; 0 = index once at start.",
    "REINDEX_HOURS=24",
    "# Embedded graph-store buffer in MB (the library default is multi-GB).",
    "CGC_BUFFER_MB=512",
    "# Caddy's host port (plain HTTP). For real HTTPS set DOMAIN and use",
    "# docker-compose.tls.yaml instead.",
    "HTTP_PORT=8080",
    "DOMAIN=",
]
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
with os.fdopen(fd, "w") as fh:
    fh.write("\n".join(lines) + "\n")
print(f"wrote {path} (values not shown)")
