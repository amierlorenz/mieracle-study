---
name: study-import
description: Use when turning lecture slides, notes, PDFs, textbook chapters, or other course documents into MieracleStudy import JSON, or when a MieracleStudy import file fails mieracle-validate.
---

# Study Import

## Overview

Produce a schema v1 import file (`Schema/import-v1.schema.json`) that MieracleStudy can upsert. **`mieracle-validate` is the source of truth**: a file isn't done until it prints `OK`.

## Workflow

1. **Get context.** Course id and name, plus existing unit and concept ids. Best source: in the app, Import → *Copy AI Generator Prompt* for that class (it lists existing ids and the full authoring rules). Otherwise read earlier import files. Reusing an existing id updates that item; a new id for an old idea creates a duplicate.
2. **Extract text.** PDF: `pdftotext -layout file.pdf out.txt` (or the pdf skill). Slides: the pptx skill.
3. **Outline before writing prompts.** List units → concepts, one testable idea per concept. Material over ~30 slides or several decks: write one file per unit. Files may be imported in any order.
4. **Write the JSON** following the rules in the generator prompt (Quick Reference below).
5. **Validate and fix until OK:**
   ```sh
   swift run --package-path MieracleKit --scratch-path ~/Library/Caches/MieracleKit-build mieracle-validate path/to/file.json
   ```
   Run from the repo root. Fix every `error:` line; read every `warning:`.
6. **Report** file paths and counts, then tell the user: Import → *Choose JSON File…* (or paste).

## Quick Reference

| Thing | Rule |
|---|---|
| Ids | lowercase kebab-case, parent-prefixed: `cs201.heaps.top-k.flashcard-1` |
| Prompts per concept | 2–4, mixed; at least one `flashcard` or `shortAnswer`. Quick notes may omit `prompts` (lean): the Mac app writes two from the explanation |
| `shortAnswer` | `question`, `modelAnswer`, 2–4 `keyPoints` |
| `multipleChoice` | 3–5 `options`, 0-based `correctIndex`, plausible distractors |
| `codeImplement` | `functionName`, `tests: [{args: [...], expected}]` — `args` is the positional argument list |
| `codeComplexity` | `code`, `time`, `space` as `O(...)`, `explanation` |
| `patternPick` | `answer` + `explanation`; `options` and `correctIndex` together or not at all |
| Math / code | `$inline$`, `$$display$$`, fenced code blocks in any text field |
| `exams` | only when the material gives a date; `unitIds` it covers |

## Common Mistakes

| Mistake | Fix |
|---|---|
| LaTeX backslash not escaped in JSON (`"\frac"`) | `"\\frac"` |
| One list argument written as `"args": [1, 2]` | `"args": [[1, 2]]` |
| New id for an idea that already exists | Reuse the existing concept id |
| Same prompt id in two unit files | Keep the concept-id prefix on every prompt id |
| Concept covers several ideas | Split into one concept per idea |
| Only "what is" questions | Add why/how/compare questions |
| Invented resource URLs | Omit `resources` unless certain the page exists |
