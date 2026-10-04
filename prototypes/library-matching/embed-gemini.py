"""PROTOTYPE — throwaway. Usage: python3 embed-gemini.py  → adds "gemini" to out/embeddings.json

Option A2, cloud embeddings: gemini-embedding-2 vectors of title + definition, cosine similarity.
"""
import json, math, time, urllib.request
from pathlib import Path
from gemini import key

here = Path(__file__).parent
model = "gemini-embedding-2"


def clean(s):
    return s.replace("**", "").replace("`", "").replace("$", "")[:400]


def embed(text):
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent",
        data=json.dumps({"content": {"parts": [{"text": text}]}, "taskType": "SEMANTIC_SIMILARITY"}).encode(),
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
    )
    v = json.load(urllib.request.urlopen(req, timeout=60))["embedding"]["values"]
    n = math.sqrt(sum(x * x for x in v))
    return [x / n for x in v]


start = time.time()
library = json.loads((here / "out/library.json").read_text())
lib = [embed(clean(f"{c['title']}: {c['explanation']}")) for c in library]
scores = {}
for deck in ["mis", "mat305", "os7", "os8"]:
    concepts = json.loads((here / f"out/{deck}-extract.json").read_text())["concepts"]
    scores[deck] = []
    for c in concepts:
        v = embed(clean(f"{c['title']}: {c['definition']}"))
        scores[deck].append({l["id"]: round(sum(a * b for a, b in zip(v, w)), 3) for l, w in zip(library, lib)})
path = here / "out/embeddings.json"
data = json.loads(path.read_text())
data["gemini"] = {"seconds": f"{round(time.time() - start)} seconds", "scores": scores}
path.write_text(json.dumps(data, indent=2, sort_keys=True))
print(f"gemini embeddings: {round(time.time() - start)}s")
