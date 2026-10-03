"""PROTOTYPE — throwaway. Usage: GEMINI_API_KEY=… python3 run-gemini.py <deck.pdf> [model]"""
import base64, json, os, sys, time, urllib.error, urllib.request
from pathlib import Path

here = Path(__file__).parent
deck = Path(sys.argv[1])
model = sys.argv[2] if len(sys.argv) > 2 else "gemini-3.8-flash"
key = os.environ["GEMINI_API_KEY"]
(here / "out").mkdir(exist_ok=True)

body = {
    "systemInstruction": {"parts": [{"text": (here / "prompt.md").read_text()}]},
    "contents": [{"role": "user", "parts": [
        {"inlineData": {"mimeType": "application/pdf", "data": base64.b64encode(deck.read_bytes()).decode()}},
        {"text": "Extract this document's concepts."},
    ]}],
    "generationConfig": {
        "responseMimeType": "application/json",
        "responseJsonSchema": json.loads((here / "schema.json").read_text()),
    },
}
models = [model] + [m for m in ["gemini-3.8-flash", "gemini-3.7-flash", "gemini-3.6-flash"] if m != model]
attempts = []
raw = None
start = time.time()
for m in models:
    for wait in [0, 15, 45]:
        time.sleep(wait)
        req = urllib.request.Request(
            f"https://generativelanguage.googleapis.com/v1beta/models/{m}:generateContent",
            data=json.dumps(body).encode(),
            headers={"Content-Type": "application/json", "x-goog-api-key": key},
        )
        try:
            raw = json.load(urllib.request.urlopen(req, timeout=600))
            model = m
            break
        except urllib.error.HTTPError as e:
            detail = e.read().decode(errors="replace")[:300]
            attempts.append(f"{m}: HTTP {e.code}")
            print(f"{m}: HTTP {e.code} {detail}", file=sys.stderr)
            if e.code not in (429, 500, 503):
                sys.exit(1)
    if raw:
        break
if not raw:
    sys.exit("gemini: every model failed: " + ", ".join(attempts))
secs = round(time.time() - start)
(here / "out/gemini-raw.json").write_text(json.dumps(raw, indent=2))
result = json.loads(raw["candidates"][0]["content"]["parts"][0]["text"])
meta = {"provider": f"Gemini {model} (free tier)", "seconds": secs, "usage": raw.get("usageMetadata"), "failed_attempts": attempts}
(here / "out/gemini.json").write_text(json.dumps({"meta": meta, **result}, indent=2))
print(f"gemini: {len(result['concepts'])} concepts in {secs}s")
