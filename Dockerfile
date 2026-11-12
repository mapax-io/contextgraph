# codegraph-mcp — CodeGraphContext (MIT, indexes code into a queryable
# graph) served over streamable HTTP. The image holds three things:
#   git           — the entrypoint clones/pulls the repos itself
#   cgc           — CodeGraphContext, stdio MCP + the indexer CLI
#   mcp-proxy     — bridges the stdio server to HTTP on :8900
FROM python:3.13-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/*

# falkordblite is the preferred embedded graph store; where the wheel is
# missing for this platform, CodeGraphContext falls back to KuzuDB on its own.
RUN pip install --no-cache-dir codegraphcontext mcp-proxy \
 && (pip install --no-cache-dir falkordblite \
     || echo "falkordblite unavailable — KuzuDB fallback will be used")

COPY entrypoint.sh /usr/local/bin/codegraph-entrypoint.sh

# Everything mutable lives under /data (a volume): the clones, the graph
# database (~/.codegraphcontext with HOME=/data), the git credential file.
VOLUME /data
EXPOSE 8900

ENTRYPOINT ["/bin/sh", "/usr/local/bin/codegraph-entrypoint.sh"]
