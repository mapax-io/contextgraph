# contextgraph

Your codebase as a queryable knowledge graph, served as an MCP server you
can run **anywhere Docker runs** — a VPS, RunPod, a homelab — nowhere near
the code's own servers.

Built on [CodeGraphContext](https://github.com/CodeGraphContext/CodeGraphContext)
(MIT): it indexes repositories into a graph database and answers questions
plain text search can't — who calls this function, what's the call chain
from A to B, which code is dead, where are the import cycles.

```
caddy (one public door, bearer token)
  ├─ /mcp, /sse ──► mcp-proxy ──► CodeGraphContext (stdio)
  └─ /healthz      open
cgc container:
  git clone/pull (REPOS, GIT_TOKEN) ──► cgc index ──► graph DB (volume)
```

The key property: **the graph is self-contained.** The container clones the
repos itself, indexes them, and from then on queries run against the graph —
the clones are only touched again on the re-index cycle. That's why the
stack can live anywhere, and why one instance serves any number of MCP
clients and projects.

## Install

```sh
git clone https://github.com/mapax-io/contextgraph
cd contextgraph
./install.sh            # creates .env — edit REPOS (+ GIT_TOKEN), then:
./install.sh            # builds and starts; first indexing begins
```

- `REPOS` — comma-separated https git URLs to index
- `GIT_TOKEN` — read-only fine-grained PAT for private github.com repos
  (Contents: read, only the repos listed). Public repos need none.
- `REINDEX_HOURS` — freshness cycle (default 24; 0 = index once)
- `CGC_BUFFER_MB` — embedded store's memory (default 512)

Watch the first indexing: `docker compose logs -f cgc`

## Attach to an MCP client

- transport: **streamable HTTP**
- URL: `http://<box>:8080/mcp` (or `https://<DOMAIN>/mcp` with the TLS overlay)
- auth: bearer token — `grep CODEGRAPH_TOKEN .env`

In NeuralOps: MCP servers → Add → HTTP, paste URL, auth "Static secret",
the token as `Authorization: Bearer`.

## HTTPS

Set `DOMAIN` in `.env` (ports 80/443 free), then:

```sh
docker compose -f docker-compose.yaml -f docker-compose.tls.yaml up -d
```

## Operations

- **Add a repo:** append it to `REPOS` in `.env`, `docker compose up -d` —
  it's cloned and indexed on the next cycle (or restart `cgc` to do it now).
- **Tenancy:** one instance = one trust zone. The bearer token reaches every
  indexed repo's graph, so give separate customers separate instances
  (it's one `install.sh` on another box).
- **Backup:** the `cgc-data` volume holds clones + graph. Losing it costs a
  re-index, nothing more.

## License

Apache-2.0 (this packaging). CodeGraphContext itself is MIT.
