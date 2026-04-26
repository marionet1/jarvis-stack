# stack-jarvis1net

Monorepo for a self-hosted Jarvis stack:
- `agent-jarvis1net` (AI assistant runtime, Telegram/CLI)
- `mcp-jarvis1net` (Python MCP server, stdio transport)

Related repositories:
- [marionet1/stack-jarvis1net](https://github.com/marionet1/stack-jarvis1net)
- [marionet1/agent-jarvis1net](https://github.com/marionet1/agent-jarvis1net)
- [marionet1/mcp-jarvis1net](https://github.com/marionet1/mcp-jarvis1net)

## Current architecture

- Runtime is Python-based end to end.
- The agent starts the MCP server as a stdio subprocess:
  `python /opt/mcp-jarvis1net/src/server.py`.
- Optional Microsoft Graph integration is handled through MCP tools.
- Docker deployment uses one app container and one vector DB service:
  - Service: `jarvis1net`
  - Container: `stack-jarvis1net`
  - Image: `stack-jarvis1net`
  - RAG service: `qdrant` (`stack-jarvis1net-qdrant`)

## Quick start (Docker, recommended)

```bash
git clone --recurse-submodules https://github.com/marionet1/stack-jarvis1net.git
cd stack-jarvis1net
cp agent-jarvis1net/.env.example .env
# edit .env
docker compose build
docker compose up -d
```

Useful commands:

```bash
docker compose ps
docker compose logs -f
docker compose restart jarvis1net
docker compose restart qdrant
docker compose down
```

Notes:
- Place `.env` in the repository root (next to `docker-compose.yml`).
- Persistent data is stored in volume `jarvis_data` mounted to `/app/data`.
- Vector index data is stored in `qdrant_data`.

## RAG rollout (tools: Microsoft, filesystem, shell)

The stack includes tool-guidance RAG in MCP (`rag_*` tools), backed by Qdrant.

1. Set these values in root `.env`:

```dotenv
RAG_BACKEND=qdrant
QDRANT_URL=http://qdrant:6333
QDRANT_COLLECTION=jarvis1net_tool_docs
OPENAI_API_KEY=...
RAG_EMBED_MODEL=text-embedding-3-small
RAG_GUIDANCE_AUTO=1
```

2. Start or rebuild services:

```bash
docker compose up -d --build
```

3. Ingest documentation:

```bash
cd mcp-jarvis1net
python3 scripts/ingest_docs.py --source scripts/sources_microsoft.yaml --source scripts/sources_internal.yaml
```

4. Validate retrieval quality:

```bash
python3 tests/rag_eval/evaluate_rag.py
```

## Local development (without Docker)

1. Install MCP package:

```bash
cd mcp-jarvis1net
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
```

2. Install and run agent:

```bash
cd ../agent-jarvis1net
python3 -m venv .venv
source .venv/bin/activate
python3 -c "import json,subprocess,sys; d=json.load(open('requirements.json', encoding='utf-8')); subprocess.check_call([sys.executable,'-m','pip','install',*d['python_dependencies']])"
cp .env.example .env
python3 src/main.py
```

3. In agent `.env`, configure stdio MCP command:

```dotenv
MCP_STDIO_COMMAND=python3
MCP_STDIO_ARGS=["/absolute/path/to/mcp-jarvis1net/src/server.py"]
```

## Repository layout

- `agent-jarvis1net/` - agent code
- `mcp-jarvis1net/` - MCP server code
- `docker-compose.yml` - deployment definition
- `Dockerfile` - unified image build
- `deploy/` - deployment helper scripts

## Security

- Never commit `.env`, private keys, or credentials.
- Set `TELEGRAM_ALLOWED_CHAT_IDS` for production deployments.

## License

See license files in each repository/submodule.
