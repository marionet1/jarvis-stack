# RAG Operations Guide

This guide explains how to operate the MCP tool-guidance RAG in `stack-jarvis1net`.

## 1) What is configurable where

### Secrets (`.env` in stack root)

Use `.env` only for secrets:

- `OPENROUTER_API_KEY` (required)
- `RAG_EMBED_API_KEY` (optional, overrides `OPENROUTER_API_KEY` for embeddings)
- `QDRANT_API_KEY` (optional, only if Qdrant auth is enabled)

### Non-secret RAG settings (`mcp-jarvis1net/src/rag/rag_config.json`)

Use this file for runtime behavior:

- `rag_root` - local RAG storage path
- `backend` - `qdrant` or `local`
- `qdrant_url`
- `qdrant_collection`
- `qdrant_api_key_env`
- `openrouter_base_url`
- `embed_model`
- `guidance_auto`

## 2) First-time setup

From stack root:

```bash
docker compose up -d --build
```

Ingest baseline docs:

```bash
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/ingest_docs.py \
  --source /opt/mcp-jarvis1net/src/rag/sources/internal.yaml \
  --source /opt/mcp-jarvis1net/src/rag/sources/microsoft.yaml
```

Run quality checks:

```bash
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/tests/evaluate_rag.py
```

## 3) Daily operations

### Reindex after doc updates

If you changed source YAML files, re-run ingest:

```bash
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/ingest_docs.py \
  --source /opt/mcp-jarvis1net/src/rag/sources/internal.yaml \
  --source /opt/mcp-jarvis1net/src/rag/sources/microsoft.yaml
```

### Restart stack services

```bash
docker compose restart jarvis1net
docker compose restart qdrant
```

### Check logs

```bash
docker compose logs -f jarvis1net
docker compose logs -f qdrant
```

## 4) Changing embedding model

Edit:

- `mcp-jarvis1net/src/rag/rag_config.json`

Change:

- `embed_model`

Then rebuild/restart and reindex:

```bash
docker compose up -d --build
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/ingest_docs.py \
  --source /opt/mcp-jarvis1net/src/rag/sources/internal.yaml \
  --source /opt/mcp-jarvis1net/src/rag/sources/microsoft.yaml
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/tests/evaluate_rag.py
```

## 5) Adding new documentation sources

Add entries to:

- `mcp-jarvis1net/src/rag/sources/microsoft.yaml` (official docs)
- `mcp-jarvis1net/src/rag/sources/internal.yaml` (internal runbooks)

Each entry should include at least:

- `title`
- `tool_family`
- and either:
  - `source_url`, or
  - `content`

Optional but recommended:

- `tool_name`, `doc_type`, `provider`, `version`, `tags`, `doc_id`

## 6) Backup and restore

### Backup Qdrant volume

```bash
docker run --rm -v stack-jarvis1net_qdrant_data:/data -v "$PWD":/backup alpine \
  tar czf /backup/qdrant-backup.tgz -C /data .
```

### Restore Qdrant volume

1. Stop services:

```bash
docker compose down
```

2. Restore data into the volume.
3. Start services and run eval:

```bash
docker compose up -d
docker compose exec -T jarvis1net python3 /opt/mcp-jarvis1net/src/rag/tests/evaluate_rag.py
```

## 7) Troubleshooting quick list

- `evaluate_rag.py` fails:
  - check `OPENROUTER_API_KEY` / `RAG_EMBED_API_KEY`
  - verify `embed_model` in `rag_config.json`
  - inspect `docker compose logs -f jarvis1net`
- no RAG guidance in responses:
  - verify `guidance_auto: true` in `rag_config.json`
  - ensure docs were ingested successfully
- low retrieval quality:
  - enrich source docs
  - improve `tool_name` and `doc_type` tagging
  - reindex and rerun eval
