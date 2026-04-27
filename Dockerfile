FROM python:3.12-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONPATH=/app/src

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY agent-jarvis1net/ /app/
RUN python3 -c "import json,subprocess,sys; d=json.load(open('requirements.json')); subprocess.check_call([sys.executable,'-m','pip','install',*d['python_dependencies']])"

COPY mcp-jarvis1net/ /opt/mcp-jarvis1net/
RUN python3 -m pip install /opt/mcp-jarvis1net

RUN mkdir -p /app/data

# Domyślnie: bot Telegram. CLI: docker run ... python3 src/main.py
CMD ["python3", "src/channels/telegram.py"]
