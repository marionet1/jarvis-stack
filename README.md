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

Detailed operator guide:
- `docs/RAG_OPERATIONS_GUIDE.md`

1. Set these values in root `.env`:

```dotenv
OPENROUTER_API_KEY=...
# optional dedicated embedding key:
RAG_EMBED_API_KEY=
# optional if Qdrant auth is enabled:
QDRANT_API_KEY=
```

2. Configure non-secret RAG settings in:

`mcp-jarvis1net/src/rag/rag_config.json`

3. Start or rebuild services:

```bash
docker compose up -d --build
```

4. Ingest documentation:

```bash
cd mcp-jarvis1net
python3 src/rag/ingest_docs.py --source src/rag/sources/microsoft.yaml --source src/rag/sources/internal.yaml
```

5. Validate retrieval quality:

```bash
python3 src/rag/tests/evaluate_rag.py
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

3. In `agent-jarvis1net/config/runtime_config.json`, configure stdio MCP command:

```json
{
  "mcp_stdio_command": "python3",
  "mcp_stdio_args": ["/absolute/path/to/mcp-jarvis1net/src/server.py"]
}
```

## Telegram bot onboarding

1. Create bot in [@BotFather](https://t.me/BotFather) with `/newbot`.
2. Put token into root `.env`:

```dotenv
TELEGRAM_BOT_TOKEN=...
```

3. Send one message to the bot and read your chat ID:
   - `https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/getUpdates`
   - Use `message.chat.id`.
4. Put allowed IDs into:
   - `agent-jarvis1net/config/telegram_config.json`

```json
{
  "allowed_chat_ids": ["123456789"]
}
```

## Repository layout

- `agent-jarvis1net/` - agent code
- `mcp-jarvis1net/` - MCP server code
- `docker-compose.yml` - deployment definition
- `Dockerfile` - unified image build
- `deploy/` - deployment helper scripts

## Security

- Never commit `.env`, private keys, or credentials.
- Set `agent-jarvis1net/config/telegram_config.json` (`allowed_chat_ids`) for production deployments.

## License

See license files in each repository/submodule.
