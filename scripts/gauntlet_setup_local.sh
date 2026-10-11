#!/usr/bin/env bash
# Run a CPU-only Ollama backend on a fresh GitHub Linux runner, with NO cloud API key.
# Only used in trusted Actions environments, never installed on the user's phone.
set -euo pipefail
command -v docker >/dev/null || { echo "BLOCKED: docker unavailable"; exit 2; }
command -v curl >/dev/null || { echo "BLOCKED: curl unavailable"; exit 2; }
if [ -n "${GAUNTLET_AI_TOKEN:-}" ]; then
  echo "BLOCKED: local Gauntlet must not receive a cloud token"
  exit 2
fi
export GAUNTLET_BUILDER_MODEL="${GAUNTLET_BUILDER_MODEL:-qwen2.5-coder:1.5b}"
export GAUNTLET_CRITIC_MODEL="${GAUNTLET_CRITIC_MODEL:-qwen2.5-coder:7b}"
if [ "$GAUNTLET_BUILDER_MODEL" = "$GAUNTLET_CRITIC_MODEL" ]; then
  echo "BLOCKED: independent model names must differ"
  exit 2
fi
# Models are explicitly allowlisted to prevent arbitrary large/untrusted downloads.
case "$GAUNTLET_BUILDER_MODEL" in
  qwen2.5-coder:1.5b) ;;
  *) echo "BLOCKED: unexpected builder model"; exit 2 ;;
esac
case "$GAUNTLET_CRITIC_MODEL" in
  qwen2.5-coder:7b) ;;
  *) echo "BLOCKED: unexpected critic model"; exit 2 ;;
esac
docker run -d --name dice-gauntlet-ollama --pull always \
  -p 127.0.0.1:11434:11434 \
  -e OLLAMA_NUM_PARALLEL=1 -e OLLAMA_MAX_LOADED_MODELS=1 \
  ollama/ollama:latest
for n in $(seq 1 45); do
  if curl --fail --silent --max-time 2 http://127.0.0.1:11434/api/version >/dev/null; then
    break
  fi
  sleep 2
done
curl --fail --silent --show-error --max-time 8 http://127.0.0.1:11434/api/version
echo
docker exec dice-gauntlet-ollama ollama pull "$GAUNTLET_BUILDER_MODEL"
docker exec dice-gauntlet-ollama ollama pull "$GAUNTLET_CRITIC_MODEL"
docker exec dice-gauntlet-ollama ollama list
echo "Local models pulled. API binds only to runner loopback. No external model API used."
