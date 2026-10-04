"""PROTOTYPE — throwaway. Usage: python3 pptx-text.py <deck.pptx> <out.txt>

Slide text straight from the PPTX XML, one "Slide N:" block per slide (no Keynote needed).
"""
import re, sys, zipfile

z = zipfile.ZipFile(sys.argv[1])
slides = sorted((n for n in z.namelist() if re.fullmatch(r"ppt/slides/slide\d+\.xml", n)), key=lambda n: int(re.findall(r"\d+", n)[0]))
blocks = []
for i, n in enumerate(slides, 1):
    xml = z.read(n).decode()
    paras = [" ".join(re.findall(r"<a:t>([^<]*)</a:t>", p)) for p in re.findall(r"<a:p>.*?</a:p>", xml, re.S)]
    blocks.append(f"Slide {i}:\n" + "\n".join(p for p in paras if p.strip()))
open(sys.argv[2], "w").write("\n\n".join(blocks))
print(f"{len(slides)} slides")
