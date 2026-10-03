#!/bin/zsh
# PROTOTYPE — throwaway. Usage: ./run-claude.sh <deck.pdf> [model]
set -euo pipefail
here=${0:A:h}
deck=${1:A}
model=${2:-sonnet}
mkdir -p "$here/out"
work=$(mktemp -d)
cp "$deck" "$work/deck.pdf"
cd "$work"

/Users/amierld/.local/bin/claude -p "/usage" --output-format json > "$here/out/claude-usage-before.json"

start=$(date +%s)
env -u ANTHROPIC_API_KEY -u ANTHROPIC_AUTH_TOKEN /Users/amierld/.local/bin/claude -p \
  "Read ./deck.pdf (all pages) and extract its concepts." \
  --model "$model" \
  --system-prompt "$(cat "$here/prompt.md")" \
  --tools Read --allowedTools Read \
  --setting-sources "" --strict-mcp-config \
  --output-format json \
  --json-schema "$(cat "$here/schema.json")" \
  --max-budget-usd 2 \
  > "$here/out/claude-raw.json"
end=$(date +%s)

/Users/amierld/.local/bin/claude -p "/usage" --output-format json > "$here/out/claude-usage-after.json"

python3 - "$here/out" $((end - start)) <<'PY'
import json, sys
out, secs = sys.argv[1], int(sys.argv[2])
raw = json.load(open(f"{out}/claude-raw.json"))
result = raw.get("structured_output") or json.loads(raw["result"])
meta = {"provider": "Claude Sonnet via claude -p", "seconds": secs,
        "usage": raw.get("usage"), "total_cost_usd": raw.get("total_cost_usd"),
        "usage_before": json.load(open(f"{out}/claude-usage-before.json")).get("result"),
        "usage_after": json.load(open(f"{out}/claude-usage-after.json")).get("result")}
json.dump({"meta": meta, **result}, open(f"{out}/claude.json", "w"), indent=2)
print(f"claude: {len(result['concepts'])} concepts in {secs}s")
PY
rm -rf "$work"
