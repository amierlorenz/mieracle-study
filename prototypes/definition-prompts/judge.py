"""PROTOTYPE — throwaway. Usage: python3 judge.py out/coreai.json [...]  (adds Flash Lite verify results in place)

Reuses run-lite.py's key lookup, rate limit and verify call without its generation loop.
"""
import json, sys
from pathlib import Path

here = Path(__file__).parent
exec((here / "run-lite.py").read_text().split("\nrecords = ")[0])
by_id = {r["id"]: r for r in json.loads((here / "out/records.json").read_text())}
for name in sys.argv[1:]:
    path = Path(name)
    data = json.loads(path.read_text())
    before = stats["requests"]
    for entry in data["results"]:
        if "prompts" in entry:
            try:
                entry["verify"], _ = verify(by_id[entry["id"]]["record"], entry["prompts"])
            except Exception as e:
                entry["verifyError"] = str(e)
    data["meta"]["judgeRequests"] = stats["requests"] - before
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False))
    print(f"judge: {path.name}: {data['meta']['judgeRequests']} requests")
