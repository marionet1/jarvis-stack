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
- Docker deployment uses one image and one service:
  - Service: `jarvis1net`
  - Container: `stack-jarvis1net`
  - Image: `stack-jarvis1net`

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
docker compose down
```

Notes:
- Place `.env` in the repository root (next to `docker-compose.yml`).
- Persistent data is stored in volume `jarvis_data` mounted to `/app/data`.

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
