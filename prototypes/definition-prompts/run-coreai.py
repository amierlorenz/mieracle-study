"""PROTOTYPE — throwaway. Usage: python3 run-coreai.py [plain|pattern]  (out/records.json → out/coreai[-pattern].json)

Talks to a running Core AI `llm-server` (OpenAI-compatible) on $COREAI_URL, default http://127.0.0.1:8080.
`pattern` adds a JSON-schema regex to every string that admits only `\\\\` and `\\"` escapes, so the
model can't emit `\\t`/`\\b` (eaten LaTeX) and must double its backslashes.
"""
import copy, json, os, sys, time, urllib.error, urllib.request
from pathlib import Path

here = Path(__file__).parent
variant = sys.argv[1] if len(sys.argv) > 1 else "plain"
url = os.environ.get("COREAI_URL", "http://127.0.0.1:8080") + "/v1/chat/completions"
safe = r'(?:[^\\"\n]|\\\\|\\")*'


def add_pattern(node):
    if node.get("type") == "string":
        node["pattern"] = safe
    for child in node.get("properties", {}).values():
        add_pattern(child)
    if "items" in node:
        add_pattern(node["items"])


schema = json.loads((here / "schema.json").read_text())
if variant == "pattern":
    schema = copy.deepcopy(schema)
    add_pattern(schema)
system = (here / "prompt.md").read_text()
records = json.loads((here / "out/records.json").read_text())

results, usage = [], {"promptTokens": 0, "outputTokens": 0}
start = time.time()
for r in records:
    body = {"model": "qwen3-8b", "temperature": 0.7, "top_p": 0.8, "max_tokens": 2048,
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": r["record"]}],
            "response_format": {"type": "json_schema", "json_schema": {"name": "prompts", "strict": True, "schema": schema}}}
    entry = {"id": r["id"], "title": r["title"]}
    t0 = time.time()
    try:
        req = urllib.request.Request(url, data=json.dumps(body).encode(), headers={"Content-Type": "application/json"})
        raw = json.load(urllib.request.urlopen(req, timeout=600))
        u = raw.get("usage", {})
        usage["promptTokens"] += u.get("prompt_tokens", 0)
        usage["outputTokens"] += u.get("completion_tokens", 0)
        text = raw["choices"][0]["message"]["content"]
        entry["raw"] = text
        entry["prompts"] = json.loads(text)
    except urllib.error.HTTPError as e:
        entry["error"] = f"HTTP {e.code} {e.read().decode(errors='replace')[:300]}"
    except Exception as e:
        entry["error"] = str(e)
    entry["seconds"] = round(time.time() - t0, 1)
    results.append(entry)
    print(f"coreai/{variant}: {r['title']}: {entry['seconds']}s {entry.get('error', '')}", flush=True)

label = "Core AI qwen3-8b on-device" + (" + pattern" if variant == "pattern" else "")
meta = {"provider": label, "seconds": round(time.time() - start), "requests": 0, **usage}
name = "coreai.json" if variant == "plain" else "coreai-pattern.json"
(here / "out" / name).write_text(json.dumps({"meta": meta, "results": results}, indent=2, ensure_ascii=False))
print(f"coreai/{variant}: {len(results)} concepts in {meta['seconds']}s")
