"""PROTOTYPE — throwaway. Usage: python3 run-judge.py <deck> full|shortlist  → out/<deck>-judge-<mode>.json

Option C (full): one Flash Lite call sees every candidate and every library concept.
Option D (shortlist): the same call, but each candidate only sees its gemini-embedding-2
neighbours scoring ≥ 0.70 (top 5).
For "same" matches it also proposes the enrichment: what the candidate adds to the old concept.
"""
import json, sys
from pathlib import Path
from gemini import generate

here = Path(__file__).parent
deck, mode = sys.argv[1], sys.argv[2]
library = json.loads((here / "out/library.json").read_text())
by_id = {c["id"]: c for c in library}
extract = json.loads((here / f"out/{deck}-extract.json").read_text())
concepts = extract["concepts"]
scores = json.loads((here / "out/embeddings.json").read_text())["gemini"]["scores"][deck]


def lib_line(c):
    return f"[{c['id']}] ({c['course']}) {c['title']}: {c['explanation'][:400]}"


def cand_block(i, c):
    lines = [f"Candidate {i}: {c['title']} (kind: {c['kind']})", f"Definition: {c['definition']}"]
    if c["useWhen"]:
        lines.append("Use when: " + "; ".join(c["useWhen"]))
    if mode == "shortlist":
        near = [k for k, v in sorted(scores[i].items(), key=lambda x: -x[1]) if v >= 0.70][:5]
        lines.append("Library concepts to compare against:" + ("" if near else " none"))
        lines += [f"  {lib_line(by_id[k])}" for k in near]
    return "\n".join(lines)


system = """You compare newly extracted study concepts with the learner's existing library so the app proposes enrichment instead of duplicates.

For each candidate return every library concept it relates to, with a relation:
- "same": teaches the same idea; studying both would be redundant. Different wording, titles or courses still count.
- "confusable": a different idea a student could plausibly mix up with the candidate (similar name, similar use, look-alike method).
Leave out library concepts that are merely on the same topic. Most candidates have no matches.

For each "same" match, list in `adds` only what the candidate would add to the library concept: its kind, use-when cues and any statement the library explanation lacks. Empty if nothing new.
Use the library ids exactly as given."""

body = []
if mode == "full":
    body.append("Library:\n" + "\n".join(lib_line(c) for c in library))
body.append(f"Candidates from a document in the course \"{extract['meta']['course']}\":\n\n" + "\n\n".join(cand_block(i, c) for i, c in enumerate(concepts)))

schema = {
    "type": "object", "additionalProperties": False, "required": ["candidates"],
    "properties": {"candidates": {"type": "array", "items": {
        "type": "object", "additionalProperties": False, "required": ["candidate", "matches"],
        "properties": {
            "candidate": {"type": "integer"},
            "matches": {"type": "array", "items": {
                "type": "object", "additionalProperties": False, "required": ["id", "relation", "reason", "adds"],
                "properties": {
                    "id": {"type": "string"},
                    "relation": {"type": "string", "enum": ["same", "confusable"]},
                    "reason": {"type": "string"},
                    "adds": {"type": "array", "items": {"type": "string"}},
                }}},
        }}}},
}
result, meta = generate(["gemini-3.5-flash-lite", "gemini-3.1-flash-lite"], system, [{"text": "\n\n".join(body)}], schema)
(here / f"out/{deck}-judge-{mode}.json").write_text(json.dumps({"meta": meta, **result}, indent=2))
n = sum(len(c["matches"]) for c in result["candidates"])
print(f"{deck} {mode}: {n} matches, {meta['seconds']}s, {meta['usage'].get('promptTokenCount')} prompt tokens via {meta['model']}")
