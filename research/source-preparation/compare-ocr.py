import re, collections
D = '/Users/amierld/.claude/jobs/a25819ea/tmp/bench/'

def words(s):
    return re.findall(r'[a-z0-9]+', s.lower().replace('ﬁ', 'fi').replace('ﬂ', 'fl'))

def recall(ref, hyp):
    r, h = collections.Counter(ref), collections.Counter(hyp)
    total = sum(r.values())
    return sum(min(c, h[w]) for w, c in r.items()) / total if total else 1.0

def read(path):
    try:
        return open(path).read()
    except FileNotFoundError:
        return ''

for deck, pages in [('book60', 60), ('mat60', 8)]:
    print('==', deck)
    ref4 = {p: words(read(f'{D}ocr-new-4x-acc/p{p}.txt')) for p in range(1, pages + 1)} if deck == 'mat60' else None
    for run in ['new-1x-acc', 'new-1.5x-acc', 'new-2x-acc', 'new-3x-acc', 'new-4x-acc', 'new-2x-fast', 'legacy-2x-acc']:
        layer_recall, vs4 = [], []
        for p in range(1, pages + 1):
            o = words(read(f'{D}{deck}-ocr-{run}/p{p}.txt'))
            l = words(read(f'{D}{deck}-ocr-{run}/p{p}.layer.txt'))
            if l:
                layer_recall.append(recall(l, o))
            if ref4 is not None:
                vs4.append(recall(words(read(f'{D}{deck}-ocr-new-4x-acc/p{p}.txt')), o))
        msg = f'{run:14s} OCR recall of text-layer words: {sum(layer_recall)/len(layer_recall):.3f}'
        if vs4:
            msg += f' | agreement with 4x: {sum(vs4)/len(vs4):.3f}'
        print(msg)
