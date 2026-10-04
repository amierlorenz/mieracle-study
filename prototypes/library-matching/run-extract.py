"""PROTOTYPE — throwaway. Usage: python3 run-extract.py <deck.pdf> <name> <course>  → out/<name>-extract.json

Option B, "inside Extract": the bake-off Extract prompt plus every library title, and a
`libraryMatch` per candidate. Its candidates also feed the other matchers.
"""
import base64, json, sys
from pathlib import Path
from gemini import generate

here = Path(__file__).parent
deck, name, course = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
library = json.loads((here / "out/library.json").read_text())

listing = "\n".join(f"- {c['id']} | {c['course']} | {c['title']}" for c in library)
system = (here / "extract-prompt.md").read_text() + f"""
Library matching:
The learner's library already holds the concepts below (id | course | title). This document belongs to the course "{course}".
For each extracted concept set `libraryMatch`:
- relation "same": a library concept teaches the same idea (a duplicate, even if worded or titled differently, even in another course). Put its id.
- relation "confusable": a different library concept a student could plausibly mix up with this one. Put its id.
- relation "none" with an empty id otherwise.

Library:
{listing}
"""
schema = json.loads((here / "extract-schema.json").read_text())
item = schema["properties"]["concepts"]["items"]
item["required"].append("libraryMatch")
item["properties"]["libraryMatch"] = {
    "type": "object", "additionalProperties": False, "required": ["relation", "id"],
    "properties": {"relation": {"type": "string", "enum": ["same", "confusable", "none"]}, "id": {"type": "string"}},
}
if deck.suffix == ".txt":
    parts = [{"text": deck.read_text() + "\n\nExtract this document's concepts."}]
else:
    parts = [
        {"inlineData": {"mimeType": "application/pdf", "data": base64.b64encode(deck.read_bytes()).decode()}},
        {"text": "Extract this document's concepts."},
    ]
result, meta = generate(["gemini-3.8-flash", "gemini-3.7-flash", "gemini-3.6-flash"], system, parts, schema)
(here / f"out/{name}-extract.json").write_text(json.dumps({"meta": {**meta, "course": course}, **result}, indent=2))
hits = [c for c in result["concepts"] if c["libraryMatch"]["relation"] != "none"]
print(f"{name}: {len(result['concepts'])} concepts, {len(hits)} library matches, {meta['seconds']}s via {meta['model']}")
