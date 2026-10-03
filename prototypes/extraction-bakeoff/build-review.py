"""PROTOTYPE — throwaway. Usage: python3 build-review.py <deck.pdf>  → out/review.html"""
import html, json, re, subprocess, sys
from pathlib import Path

here = Path(__file__).parent
out = here / "out"
deck = Path(sys.argv[1])
pages = int(re.search(r"Pages:\s+(\d+)", subprocess.run(["pdfinfo", deck], capture_output=True, text=True).stdout)[1])
(out / "pages").mkdir(parents=True, exist_ok=True)
subprocess.run(["pdftoppm", "-png", "-r", "80", deck, out / "pages/p"], check=True)
images = sorted((out / "pages").glob("p-*.png"))


def norm(s):
    return re.sub(r"\s+", " ", re.sub(r"[‘’“”]", "'", s)).strip().lower()


texts = [norm(subprocess.run(["pdftotext", "-f", str(i), "-l", str(i), deck, "-"], capture_output=True, text=True).stdout)
         for i in range(1, pages + 1)]

providers = {}
for name in ["claude", "gemini", "fm"]:
    f = out / f"{name}.json"
    if f.exists():
        providers[name] = json.loads(f.read_text())


def flags(c):
    f = []
    s = c.get("slide", 0)
    if not 1 <= s <= pages:
        f.append("slide out of range")
    elif not c["evidence"].strip():
        f.append("no quote")
    elif norm(c["evidence"]) not in texts[s - 1]:
        hit = [i + 1 for i, t in enumerate(texts) if norm(c["evidence"]) in t]
        f.append(f"quote on p{hit[0]} not p{s}" if hit else "quote not found")
    if c.get("gapFill"):
        f.append("gap-fill")
    if c.get("confidence") == "low":
        f.append("low confidence")
    return f


summary_rows = []
for name, p in providers.items():
    cs = p["concepts"]
    verified = sum(1 for c in cs if not any(x.startswith(("quote", "no quote", "slide")) for x in flags(c)))
    m = p["meta"]
    summary_rows.append(f"<tr><td>{html.escape(m['provider'])}</td><td>{len(cs)}</td><td>{verified}</td>"
                        f"<td>{sum(c.get('gapFill', False) for c in cs)}</td><td>{m.get('seconds')}s</td>"
                        f"<td><pre>{html.escape(json.dumps({k: v for k, v in m.items() if k not in ('provider', 'seconds')}, indent=1))}</pre></td></tr>")


def card(name, i, c):
    fl = "".join(f"<span class=flag>{html.escape(x)}</span>" for x in flags(c))
    lst = lambda xs: html.escape("; ".join(xs)) or "—"
    cid = f"{name}-{i}"
    return f"""<div class=card><b>{html.escape(c['title'])}</b> <i>{c['kind']}</i> {fl}
<div>{html.escape(c['definition'])}</div>
<div class=dim>quote: “{html.escape(c['evidence'])}”</div>
<div class=dim>use when: {lst(c['useWhen'])}</div>
<div class=dim>confused with: {lst(c['confusedWith'])}</div>
<select data-id="{cid}" data-title="{html.escape(c['title'])}"><option value="">verdict…</option><option>good</option><option>wrong definition</option><option>wrong slide</option><option>hallucinated</option><option>not worth a card</option></select></div>"""


rows = []
for s in range(1, pages + 1):
    cols = []
    for name, p in providers.items():
        cards = [card(name, i, c) for i, c in enumerate(p["concepts"]) if c.get("slide") == s]
        cols.append(f"<td><h4>{name} ({len(cards)})</h4>{''.join(cards)}</td>")
    img = images[s - 1].relative_to(out) if s <= len(images) else ""
    rows.append(f"<tr><td class=page><h3>Page {s}</h3><img src='{img}'></td>{''.join(cols)}</tr>")
stray = []
for name, p in providers.items():
    stray += [card(name, i, c) for i, c in enumerate(p["concepts"]) if not 1 <= c.get("slide", 0) <= pages]

(out / "review.html").write_text(f"""<!doctype html><meta charset=utf-8><title>Extraction bake-off (PROTOTYPE)</title>
<style>body{{font:13px system-ui;margin:12px}}table{{border-collapse:collapse}}td{{vertical-align:top;border:1px solid #ccc;padding:6px;width:22%}}
td.page{{width:34%}}img{{width:100%}}.card{{border:1px solid #ddd;border-radius:4px;padding:5px;margin:4px 0}}.dim{{color:#666}}
.flag{{background:#fde2b8;border-radius:3px;padding:0 4px;margin-left:3px;font-size:11px}}pre{{margin:0;font-size:10px;white-space:pre-wrap}}</style>
<h1>Extraction bake-off — PROTOTYPE, throwaway</h1>
<p>Deck: {html.escape(deck.name)}, {pages} pages. Flags come from checking each quote against that page's PDF text.</p>
<table><tr><th>Provider</th><th>Concepts</th><th>Quote verified</th><th>Gap-fill</th><th>Time</th><th>Usage</th></tr>{''.join(summary_rows)}</table>
<p><button onclick="exp()">Export verdicts</button></p><textarea id=v rows=4 cols=120></textarea>
<table>{''.join(rows)}</table>{'<h3>Uncited / bad slide</h3>' + ''.join(stray) if stray else ''}
<script>
const K='bakeoff-verdicts';let saved={{}};try{{saved=JSON.parse(localStorage.getItem(K)||'{{}}')}}catch(e){{}}
document.querySelectorAll('select').forEach(s=>{{s.value=saved[s.dataset.id]||'';s.onchange=()=>{{saved[s.dataset.id]=s.value;try{{localStorage.setItem(K,JSON.stringify(saved))}}catch(e){{}}}}}});
function exp(){{const r={{}};document.querySelectorAll('select').forEach(s=>{{if(s.value)r[s.dataset.id+' '+s.dataset.title]=s.value}});document.getElementById('v').value=JSON.stringify(r,null,1)}}
</script>""")
print(f"wrote {out / 'review.html'} with {', '.join(providers)}")
