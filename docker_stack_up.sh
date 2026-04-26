#!/usr/bin/env bash
# Uruchom z głównego katalogu repozytorium stack-jarvis1net (Dockerfile, submoduły jarvis1net, mcp-jarvis1net).
set -euo pipefail
cd "$(dirname "$0")"

systemctl --user stop jarvis1net-telegram.service 2>/dev/null || true
systemctl --user stop jarvis1net-mcp.service 2>/dev/null || true
echo "Stopped jarvis1net-telegram / jarvis1net-mcp (if running)."

if [[ ! -f .env ]]; then
  if [[ -f agent-jarvis1net/.env ]]; then
    cp agent-jarvis1net/.env .env
  elif [[ -f /home/jump/agent-jarvis1net/.env ]]; then
    cp /home/jump/agent-jarvis1net/.env .env
  else
    cp agent-jarvis1net/.env.example .env
  fi
  echo "Created .env — edit secrets if needed."
fi

add_if_missing() {
  local k="$1" v="$2"
  if ! grep -qE "^${k}=" .env 2>/dev/null; then
    echo "" >> .env
    echo "# docker_stack_up.sh" >> .env
    echo "${k}=${v}" >> .env
  fi
}
add_if_missing MCP_STDIO_COMMAND python3
add_if_missing 'MCP_STDIO_ARGS' '["/opt/mcp-jarvis1net/src/server.py"]'
add_if_missing MCP_ALLOWED_ROOTS /app/data
add_if_missing AUDIT_LOG_PATH /app/data/audit.jsonl
add_if_missing MICROSOFT_TENANT_ID consumers

sudo docker compose build
sudo docker compose up -d
sudo docker compose ps
echo "Logs: sudo docker compose logs -f"
