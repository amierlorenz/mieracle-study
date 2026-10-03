"""PROTOTYPE — throwaway. Usage: python3 build-review.py  → out/review.html (+ out/checks.json)"""
import html, json, re
from pathlib import Path

here = Path(__file__).parent
out = here / "out"
records = {r["id"]: r for r in json.loads((out / "records.json").read_text())}
providers = {}
for name, files in {"fm": ["fm-judged.json", "fm.json"], "fmRepaired": ["fm-repaired.json"], "coreai": ["coreai.json"], "coreaiPattern": ["coreai-pattern.json"], "lite": ["lite.json"], "litePattern": ["lite-pattern.json"]}.items():
    for f in files:
        if (out / f).exists():
            providers[name] = json.loads((out / f).read_text())
            break

MATH_SYMBOLS = set("∂√∈∑∫≤≥∞≠∪∩≈±×÷∀∃∉⊂⊆")
KINDS = ["flashcard", "shortAnswer", "multipleChoice"]


def words(s):
    return set(re.findall(r"[a-z0-9]+", s.lower())) - {"the", "a", "an", "of", "is", "to", "and", "for", "in", "on", "that", "it", "be", "if", "x"}


def texts(p):
    return {"flashcard": [p["front"], p["back"]],
            "shortAnswer": [p["question"], p["modelAnswer"], *p["keyPoints"]],
            "multipleChoice": [p["question"], *p["options"], p["explanation"]]}


def checks(cid, prompts):
    record = records[cid]["record"]
    rec_cmds = set(re.findall(r"\\[A-Za-z]+", record))
    flags = {k: [] for k in KINDS}
    for kind in KINDS:
        p = prompts[kind]
        f = flags[kind]
        all_text = " ".join(texts_one(kind, p))
        for field, value in p.items():
            if isinstance(value, str) and not value.strip():
                f.append(f"{field} empty")
        drift = {c for c in re.findall(r"\\[A-Za-z]+", all_text)} - rec_cmds
        drift |= {ch for ch in all_text if ch in MATH_SYMBOLS and ch not in record}
        if drift:
            f.append("math drift: " + " ".join(sorted(drift)))
        if re.search(r"[\x00-\x08\x0b-\x1f]|\t", all_text):
            f.append("control chars (mangled LaTeX escape)")
        if all_text.count("$") % 2:
            f.append("unbalanced $")
        question = p.get("front") or p.get("question")
        answer = {"flashcard": p.get("back"), "shortAnswer": p.get("modelAnswer"),
                  "multipleChoice": (p["options"][p["correctIndex"]] if kind == "multipleChoice" and 0 <= p["correctIndex"] < len(p["options"]) else "")}[kind]
        aw = words(answer or "")
        if aw and len(aw & words(question)) / len(aw) >= 0.7:
            f.append("answer leak")
        if kind == "shortAnswer" and not 2 <= len(p["keyPoints"]) <= 4:
            f.append(f"{len(p['keyPoints'])} key points")
        if kind == "multipleChoice":
            opts = p["options"]
            if len(opts) != 4:
                f.append(f"{len(opts)} options")
            if len({re.sub(r'\s+', ' ', o.strip().lower()) for o in opts}) < len(opts):
                f.append("duplicate options")
            if not 0 <= p["correctIndex"] < len(opts):
                f.append("correctIndex out of range")
            else:
                lens = sorted(len(o) for o in opts)
                if len(opts) > 1 and len(opts[p["correctIndex"]]) == lens[-1] and lens[-1] > 1.3 * lens[-2]:
                    f.append("correct option longest by far")
    return flags


def texts_one(kind, p):
    return texts({"front": "", "back": "", "question": "", "modelAnswer": "", "keyPoints": [], "options": [], "explanation": "", **p})[kind]


def opener(s):
    return " ".join(re.findall(r"[A-Za-z]+", s)[:2]).lower()


summary, all_checks = [], {}
for name, data in providers.items():
    res = data["results"]
    ok = [r for r in res if "prompts" in r]
    cks = {r["id"]: checks(r["id"], r["prompts"]) for r in ok}
    all_checks[name] = cks
    det_fail = sum(1 for c in cks.values() for k in KINDS if c[k])
    ver = [r["verify"][k] for r in ok if "verify" in r for k in KINDS]
    ver_fail = sum(1 for v in ver if not (v["correct"] and v["withinClaims"] and v["noLeak"] and v["singleBest"]))
    wrong = sum(1 for v in ver if not v["correct"])
    outside = sum(1 for v in ver if not v["withinClaims"])
    questions = [r["prompts"]["flashcard"]["front"] for r in ok] + [r["prompts"]["shortAnswer"]["question"] for r in ok] + [r["prompts"]["multipleChoice"]["question"] for r in ok]
    variety = f"{len({opener(q) for q in questions})} distinct openers / {len(questions)}"
    secs = [r.get("seconds", 0) + r.get("verifySeconds", 0) for r in ok]
    m = data["meta"]
    reqs = m.get("requests", 0)
    judge = f" (+{m['judgeRequests']} judge-only)" if m.get("judgeRequests") else ""
    tokens = f"{m.get('promptTokens', 0)} in / {m.get('outputTokens', 0)} out / {m.get('thinkingTokens', 0)} thinking" if reqs else "—"
    summary.append([m["provider"], f"{len(ok)}/{len(res)}", f"{det_fail} of {3 * len(ok)}",
                    f"{ver_fail} of {len(ver)} (wrong {wrong}, outside claims {outside})" if ver else "not judged",
                    variety, f"{m['seconds']}s total, {sum(secs) / max(len(secs), 1):.1f}s/concept",
                    f"{reqs}{judge}" + (f", failed: {', '.join(m['failed'])}" if m.get("failed") else ""), tokens])
(out / "checks.json").write_text(json.dumps(all_checks, indent=1, ensure_ascii=False))

e = html.escape


def prompt_html(name, cid, kind, p, flags, verify):
    if kind == "flashcard":
        body = f"<div><b>Q</b> {e(p['front'])}</div><div><b>A</b> {e(p['back'])}</div>"
    elif kind == "shortAnswer":
        body = (f"<div><b>Q</b> {e(p['question'])}</div><div><b>A</b> {e(p['modelAnswer'])}</div>"
                f"<ul>{''.join(f'<li>{e(k)}</li>' for k in p['keyPoints'])}</ul>")
    else:
        opts = "".join(f"<li{' class=ok' if i == p['correctIndex'] else ''}>{e(o)}</li>" for i, o in enumerate(p["options"]))
        body = f"<div><b>Q</b> {e(p['question'])}</div><ol type=A>{opts}</ol><div class=dim>{e(p['explanation'])}</div>"
    fl = "".join(f"<span class=flag>{e(x)}</span>" for x in flags)
    if verify:
        bad = [k for k in ["correct", "withinClaims", "noLeak", "singleBest"] if not verify[k]]
        label = "judge" if name == "fm" else "verify"
        fl += (f"<span class=vbad>{label}: {', '.join(bad)} — {e(verify['issue'])}</span>" if bad
               else f"<span class=vok>{label} ok</span>")
    sid = f"{name}-{cid}-{kind}"
    sel = (f"<select data-id='{sid}'><option value=''>verdict…</option><option>good</option><option>wrong</option>"
           f"<option>outside claims</option><option>leaks answer</option><option>weak / trivial</option></select>")
    return f"<div class=p><div class=kind>{kind} {fl}</div>{body}{sel}</div>"


rows = []
for cid, rec in records.items():
    cells = []
    for name, data in providers.items():
        r = next((x for x in data["results"] if x["id"] == cid), None)
        if not r or "prompts" not in r:
            cells.append(f"<td><span class=flag>{e(r.get('error', 'missing') if r else 'missing')}</span></td>")
            continue
        t = f"{r.get('seconds')}s" + (f" + verify {r['verifySeconds']}s" if "verifySeconds" in r else "")
        cells.append(f"<td><div class=dim>{t}</div>" + "".join(
            prompt_html(name, cid, k, r["prompts"][k], all_checks[name][cid][k], r.get("verify", {}).get(k)) for k in KINDS) + "</td>")
    win = (f"<select data-id='winner-{cid}'><option value=''>better…</option>" +
           "".join(f"<option>{o}</option>" for o in ["on-device", "Flash Lite", "tie", "both bad"]) + "</select>")
    rows.append(f"<tr><td class=rec><h3>{e(rec['title'])}</h3><pre>{e(rec['record'])}</pre>{win}</td>{''.join(cells)}</tr>")

heads = "".join(f"<th>{e(providers[n]['meta']['provider'])}</th>" for n in providers)
sum_rows = "".join("<tr>" + "".join(f"<td>{e(str(c))}</td>" for c in row) + "</tr>" for row in summary)
(out / "review.html").write_text(f"""<!doctype html><meta charset=utf-8><title>Definition prompts bake-off (PROTOTYPE)</title>
<link rel=stylesheet href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/contrib/auto-render.min.js"
 onload="renderMathInElement(document.body,{{delimiters:[{{left:'$',right:'$',display:false}}],throwOnError:false}})"></script>
<style>body{{font:13px system-ui;margin:12px}}table{{border-collapse:collapse;width:100%}}td,th{{vertical-align:top;border:1px solid #ccc;padding:6px}}
td.rec{{width:28%}}pre{{white-space:pre-wrap;font-size:11px;margin:0}}.p{{border:1px solid #ddd;border-radius:4px;padding:5px;margin:5px 0}}
.kind{{font-weight:600;color:#555;margin-bottom:3px}}.dim{{color:#666}}.ok{{background:#d9f2d9}}ol,ul{{margin:3px 0;padding-left:22px}}
.flag{{background:#fde2b8;border-radius:3px;padding:0 4px;margin-left:4px;font-size:11px;font-weight:400}}
.vbad{{background:#f8c9c9;border-radius:3px;padding:0 4px;margin-left:4px;font-size:11px;font-weight:400}}
.vok{{background:#d9f2d9;border-radius:3px;padding:0 4px;margin-left:4px;font-size:11px;font-weight:400}}</style>
<h1>Definition prompts: on-device vs Flash Lite — PROTOTYPE, throwaway</h1>
<p>Input: the 11 approved concepts from the extraction bake-off (MAT 305 Ch. 3), as records only. Same instructions and output shape for both.
Orange = deterministic checks. Green/red = the Flash Lite verify call (on the on-device column it is a judge only, not part of that path).</p>
<table><tr><th>Provider</th><th>Concepts</th><th>Prompts failing checks</th><th>Verify / judge failures</th><th>Variety</th><th>Latency</th><th>Requests</th><th>Tokens</th></tr>{sum_rows}</table>
<p><button onclick="exp()">Export verdicts</button></p><textarea id=v rows=4 cols=120></textarea>
<table><tr><th>Concept record</th>{heads}</tr>{''.join(rows)}</table>
<script>
const K='defprompts-verdicts';let saved={{}};try{{saved=JSON.parse(localStorage.getItem(K)||'{{}}')}}catch(e){{}}
document.querySelectorAll('select').forEach(s=>{{s.value=saved[s.dataset.id]||'';s.onchange=()=>{{saved[s.dataset.id]=s.value;try{{localStorage.setItem(K,JSON.stringify(saved))}}catch(e){{}}}}}});
function exp(){{const r={{}};document.querySelectorAll('select').forEach(s=>{{if(s.value)r[s.dataset.id]=s.value}});document.getElementById('v').value=JSON.stringify(r,null,1)}}
</script>""")
print(f"wrote {out / 'review.html'} with {', '.join(providers)}")
for row in summary:
    print(" | ".join(row))
