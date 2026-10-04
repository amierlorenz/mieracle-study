"""PROTOTYPE — throwaway. Usage: python3 dump-library.py → out/library.json

Reads the real SwiftData store read-only and writes every concept with its course and unit.
"""
import json, sqlite3
from pathlib import Path

here = Path(__file__).parent
store = Path.home() / "Library/Application Support/default.store"
db = sqlite3.connect(f"file:{store}?mode=ro", uri=True)
rows = db.execute("""
    select c.ZEXTERNALID, co.ZNAME, co.ZSHORTNAME, u.ZNAME, c.ZTITLE, c.ZEXPLANATION
    from ZCONCEPT c left join ZCOURSEUNIT u on c.ZUNIT = u.Z_PK left join ZCOURSE co on u.ZCOURSE = co.Z_PK
    order by co.ZNAME, u.ZSORTINDEX, c.ZTITLE""").fetchall()
library = [{"id": r[0], "course": (r[2] or r[1] or "").split(" | ")[0], "unit": r[3], "title": r[4], "explanation": r[5] or ""} for r in rows]
(here / "out").mkdir(exist_ok=True)
(here / "out/library.json").write_text(json.dumps(library, indent=2))
print(f"library: {len(library)} concepts in {len({c['course'] for c in library})} courses")
