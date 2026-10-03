"""PROTOTYPE — throwaway. Usage: GEMINI_API_KEY=… python3 run-gemini.py <deck.pdf> [model]"""
import base64, json, os, sys, time, urllib.request
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
req = urllib.request.Request(
    f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent",
    data=json.dumps(body).encode(),
    headers={"Content-Type": "application/json", "x-goog-api-key": key},
)
start = time.time()
raw = json.load(urllib.request.urlopen(req, timeout=600))
secs = round(time.time() - start)
(here / "out/gemini-raw.json").write_text(json.dumps(raw, indent=2))
result = json.loads(raw["candidates"][0]["content"]["parts"][0]["text"])
meta = {"provider": f"Gemini {model} (free tier)", "seconds": secs, "usage": raw.get("usageMetadata")}
(here / "out/gemini.json").write_text(json.dumps({"meta": meta, **result}, indent=2))
print(f"gemini: {len(result['concepts'])} concepts in {secs}s")
