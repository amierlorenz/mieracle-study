"""PROTOTYPE — throwaway. Usage: python3 prepare.py [out/approved-concepts.json]  → out/records.json

Turns approved Extract output into the concept records Shape sees (records only, no slides),
roughly in the #77 shape: kind definition/fact, cited claims, use-when cues, look-alikes.
"""
import json, sys
from pathlib import Path

here = Path(__file__).parent
src = Path(sys.argv[1]) if len(sys.argv) > 1 else here / "out/approved-concepts.json"
concepts = json.loads(src.read_text())["concepts"]
by_title = {c["title"]: c for c in concepts}
kinds = {"term": "definition", "formula": "definition", "fact": "fact", "method": "method"}

records = []
for i, c in enumerate(concepts):
    if kinds[c["kind"]] == "method":
        continue
    lines = [f"Concept: {c['title']}", f"Kind: {kinds[c['kind']]}", "", "Claims:",
             f"- {c['definition']} (cited, slide {c['slide']})"]
    if c["useWhen"]:
        lines += ["", "Use when:"] + [f"- {u}" for u in c["useWhen"]]
    looks = [t for t in c["confusedWith"] if t != c["title"]]
    if looks:
        lines += ["", "Look-alikes (other concepts in this course, not this one):"]
        for t in looks:
            other = by_title.get(t)
            lines.append(f"- {t}: {other['definition']}" if other else f"- {t}")
    records.append({"id": f"c{i + 1}", "title": c["title"], "kind": kinds[c["kind"]], "record": "\n".join(lines)})

(here / "out/records.json").write_text(json.dumps(records, indent=2))
print(f"prepare: {len(records)} records")
