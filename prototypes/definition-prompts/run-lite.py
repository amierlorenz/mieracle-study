"""PROTOTYPE — throwaway. Usage: python3 run-lite.py  (reads out/records.json [+ out/fm.json] → out/lite.json [+ out/fm-judged.json])

Key: $GEMINI_API_KEY, else the login-keychain item `mieracle-gemini-prototype`.
Flash Lite path = generate + verify per concept. The same verify call is run over the
on-device output as a judge only; those requests are not part of the on-device path.
"""
import json, os, subprocess, sys, time, urllib.error, urllib.request
from pathlib import Path

here = Path(__file__).parent
model = "gemini-3.5-flash-lite"
key = os.environ.get("GEMINI_API_KEY") or subprocess.run(
    ["security", "find-generic-password", "-s", "mieracle-gemini-prototype", "-w"], capture_output=True, text=True).stdout.strip()
if not key:
    sys.exit("no key: set GEMINI_API_KEY or add keychain item mieracle-gemini-prototype")

gen_schema = json.loads((here / "schema.json").read_text())
pattern = os.environ.get("PATTERN") == "1"


def add_pattern(node):
    if node.get("type") == "string":
        node["pattern"] = "^[^\\t\\x08\\x0c]*$"
    for child in node.get("properties", {}).values():
        add_pattern(child)
    if "items" in node:
        add_pattern(node["items"])


if pattern:
    add_pattern(gen_schema)
check = {"type": "object", "additionalProperties": False,
         "required": ["correct", "withinClaims", "noLeak", "singleBest", "issue"],
         "properties": {"correct": {"type": "boolean"}, "withinClaims": {"type": "boolean"}, "noLeak": {"type": "boolean"},
                        "singleBest": {"type": "boolean"}, "issue": {"type": "string"}}}
verify_schema = {"type": "object", "additionalProperties": False, "required": ["flashcard", "shortAnswer", "multipleChoice"],
                 "properties": {k: check for k in ["flashcard", "shortAnswer", "multipleChoice"]}}
stats = {"requests": 0, "failed": [], "promptTokens": 0, "outputTokens": 0, "thinkingTokens": 0}
last_call = [0.0]


def call(system, user, schema):
    for wait in [0, 15, 45]:
        time.sleep(max(wait, 4.2 - (time.time() - last_call[0])))
        last_call[0] = time.time()
        body = {"systemInstruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": [{"text": user}]}],
                "generationConfig": {"responseMimeType": "application/json", "responseJsonSchema": schema}}
        req = urllib.request.Request(f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
                                     data=json.dumps(body).encode(),
                                     headers={"Content-Type": "application/json", "x-goog-api-key": key})
        stats["requests"] += 1
        t0 = time.time()
        try:
            raw = json.load(urllib.request.urlopen(req, timeout=120))
        except urllib.error.HTTPError as e:
            stats["failed"].append(f"HTTP {e.code}")
            print(f"lite: HTTP {e.code} {e.read().decode(errors='replace')[:200]}", file=sys.stderr)
            if e.code not in (429, 500, 503):
                raise
            continue
        u = raw.get("usageMetadata", {})
        stats["promptTokens"] += u.get("promptTokenCount", 0)
        stats["outputTokens"] += u.get("candidatesTokenCount", 0)
        stats["thinkingTokens"] += u.get("thoughtsTokenCount", 0)
        return json.loads(raw["candidates"][0]["content"]["parts"][0]["text"]), round(time.time() - t0, 1)
    raise RuntimeError("lite: gave up after retries")


def verify(record, prompts):
    user = f"Concept record:\n{record}\n\nGenerated prompts:\n{json.dumps(prompts, indent=1, ensure_ascii=False)}"
    return call((here / "verify.md").read_text(), user, verify_schema)


records = json.loads((here / "out/records.json").read_text())
system = (here / "prompt.md").read_text()
results = []
start = time.time()
for r in records:
    entry = {"id": r["id"], "title": r["title"]}
    try:
        entry["prompts"], gen_s = call(system, r["record"], gen_schema)
        entry["verify"], ver_s = verify(r["record"], entry["prompts"])
        entry["seconds"], entry["verifySeconds"] = gen_s, ver_s
    except Exception as e:
        entry["error"] = str(e)
    results.append(entry)
    print(f"lite: {r['title']}: {entry.get('seconds')}s + verify {entry.get('verifySeconds')}s {entry.get('error', '')}")
path_requests = stats["requests"]
meta = {"provider": f"Gemini {model} (free tier) + verify" + (" + pattern" if pattern else ""), "seconds": round(time.time() - start), **stats}
(here / ("out/lite-pattern.json" if pattern else "out/lite.json")).write_text(json.dumps({"meta": meta, "results": results}, indent=2, ensure_ascii=False))
print(f"lite: {len(results)} concepts, {path_requests} requests, {meta['seconds']}s")

fm_path = here / "out/fm.json"
if fm_path.exists() and not pattern:
    fm = json.loads(fm_path.read_text())
    by_id = {r["id"]: r for r in records}
    before = stats["requests"]
    for entry in fm["results"]:
        if "prompts" in entry:
            try:
                entry["verify"], _ = verify(by_id[entry["id"]]["record"], entry["prompts"])
            except Exception as e:
                entry["verifyError"] = str(e)
    fm["meta"]["judgeRequests"] = stats["requests"] - before
    (here / "out/fm-judged.json").write_text(json.dumps(fm, indent=2, ensure_ascii=False))
    print(f"lite: judged on-device output with {fm['meta']['judgeRequests']} requests")
