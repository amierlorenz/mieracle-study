"""PROTOTYPE — throwaway. Usage: python3 repair.py  (out/fm.json → out/fm-repaired.json)

Deterministic post-repair for eaten LaTeX escapes: a tab, backspace, form feed or CR becomes
backslash + t/b/f/r again, and a newline right before a lowercase letter becomes `\\n`.
Foundation Models rejects regex guides (UnsupportedGuide), so this is the only on-device fix.
"""
import json, re
from pathlib import Path

here = Path(__file__).parent
eaten = {"\t": "\\t", "\x08": "\\b", "\x0c": "\\f", "\r": "\\r"}


def fix(v):
    if isinstance(v, str):
        for a, b in eaten.items():
            v = v.replace(a, b)
        return re.sub(r"\n(?=[a-z])", r"\\n", v)
    if isinstance(v, list):
        return [fix(x) for x in v]
    if isinstance(v, dict):
        return {k: fix(x) for k, x in v.items()}
    return v


fm = json.loads((here / "out/fm.json").read_text())
for entry in fm["results"]:
    if "prompts" in entry:
        entry["prompts"] = fix(entry["prompts"])
fm["meta"]["provider"] = "Foundation Models on-device + escape repair"
(here / "out/fm-repaired.json").write_text(json.dumps(fm, indent=2, ensure_ascii=False))
print("repair: wrote out/fm-repaired.json")
