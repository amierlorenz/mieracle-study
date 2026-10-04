"""PROTOTYPE — throwaway. Usage: python3 build-review.py  → out/review.html (one self-contained file)"""
import json
from pathlib import Path

here = Path(__file__).parent
out = here / "out"
decks = {"mis": ("Make It Stick ch. 8 tips (book PDF, 13 pages)", "Make It Stick"),
         "mat305": ("MAT 305 Ch. 3 §3.1–3.3 (handout PDF, 8 pages)", "MAT 305"),
         "os7": ("OS Concepts Ch. 7 Synchronization Examples (public slides, 45)", "CSC 301"),
         "os8": ("OS Concepts Ch. 8 Deadlocks (public slides, 43)", "CSC 301")}
emb = json.loads((out / "embeddings.json").read_text())
data = {"library": json.loads((out / "library.json").read_text()), "decks": {}, "truth": json.loads((here / "truth.json").read_text()), "runs": {}}
for d, (label, course) in decks.items():
    ex = json.loads((out / f"{d}-extract.json").read_text())
    judge = {m: json.loads((out / f"{d}-judge-{m}.json").read_text()) for m in ["full", "shortlist"]}
    data["decks"][d] = {
        "label": label, "course": course,
        "candidates": [{k: c[k] for k in ["title", "kind", "definition", "useWhen", "slide"]} for c in ex["concepts"]],
        "extract": [[c["libraryMatch"]] if c["libraryMatch"]["relation"] != "none" else [] for c in ex["concepts"]],
        "judgeFull": [next((x["matches"] for x in judge["full"]["candidates"] if x["candidate"] == i), []) for i in range(len(ex["concepts"]))],
        "judgeShortlist": [next((x["matches"] for x in judge["shortlist"]["candidates"] if x["candidate"] == i), []) for i in range(len(ex["concepts"]))],
        "scores": {m: emb[m]["scores"][d] for m in ["sentence", "contextual", "gemini"]},
    }
    data["runs"][d] = {"extract": ex["meta"]["model"] + f", {ex['meta']['seconds']} s",
                       **{f"judge-{m}": f"{judge[m]['meta']['model']}, {judge[m]['meta']['usage'].get('promptTokenCount')} prompt tokens" for m in judge}}
html = (here / "review-template.html").read_text().replace("/*DATA*/null", json.dumps(data))
(out / "review.html").write_text(html)
print(f"review.html: {len(html) // 1024} KB")
