# Reading slides with Claude and Gemini

Research for issue #72 (map #70, in-app Canvas intake). Sources were read on 2026-10-02. Every claim links to the page it comes from. Lines marked **Inference** are my reasoning, not something a source says.

## Answer

1. **Neither required path can use a vendor citation feature.** Claude's Citations works only on the raw Messages API (`document` blocks with `citations.enabled`). The `claude -p` interface doesn't expose it. It also can't be combined with structured outputs, and it can't cite image-only pages. Gemini has no citation feature for a PDF you send in the prompt. Its only page-level citations come from File Search, which is retrieval (RAG) and so doesn't fit "pull out every concept in this deck". **Recommendation:** use one citation scheme for both vendors. The schema asks for `slide` (a page number) and `evidence` (a verbatim quote) on each concept. The app checks the quote against that page's PDFKit text. A concept that fails the check, or that cites a slide with no text, gets the "no citation" or "low confidence" flag the map already plans for.
2. **Convert PPTX to PDF before sending it to either vendor.** Neither vendor gives PPTX the visual PDF treatment. On this Mac, Keynote's AppleScript `export … as PDF` does the conversion. With `all stages` off, each slide becomes one page, so page number = slide number. Keynote also exposes each slide's `presenter notes`. Quick Look and PDFKit can't do this conversion.
3. **Structured output works on all three surfaces, but not in the same way.** The Claude API enforces the schema while generating the output (constrained decoding). `claude -p --json-schema` checks the result afterwards and asks again on a mismatch; after too many retries it fails with `error_max_structured_output_retries`. Gemini enforces a subset of JSON Schema. Keep one schema that every surface accepts: flat, few optional fields, no numeric constraints.
4. **Caching:** the Claude API gives explicit control (`cache_control`, 5-minute or 1-hour TTL). Claude Code caches automatically and gives no control. Gemini caches implicitly by default (minimum 4,096 tokens on the 3.x models). Explicit Gemini caches exist only on `generateContent`, not the Interactions API.
5. **A 50-slide deck is small for both vendors.** On Gemini it's about 28k–56k input tokens: 560–1,120 per page, and the native text is free. On Claude it's very roughly 80k–250k (an estimate; measure it). Per pass, that's cents on Gemini Flash and about $0.15–$1.00 of input on Sonnet 5.5 or Opus 5.5 at API prices.
6. **Starting models:** Gemini 3.8 Flash (stable, cheap) for the default pass. Claude Sonnet 5.5 or Opus 5.5 through `claude -p` for harder decks (math-heavy, "which method applies"). Gemini 3.1 Pro is still Preview.

## 1. Input formats

### Claude (Messages API)

- A PDF goes in as a `document` block: base64, URL, or Files API `file_id`. Limits are 32 MB per request and 600 pages (100 when the context window is under 1M). [PDF support](https://platform.claude.com/docs/en/build-with-claude/pdf-support)
- Each page is turned into an image, and the page's extracted text is sent with it, so Claude sees both. That means charts, diagrams and math rendered as images can be read. [PDF support → How PDF support works](https://platform.claude.com/docs/en/build-with-claude/pdf-support)
- Every active model supports PDFs. Text costs about 1,500–3,000 tokens per page for dense documents, and each page also pays image-token costs. [PDF support → Estimate your costs](https://platform.claude.com/docs/en/build-with-claude/pdf-support)
- Image cost is `⌈w/28⌉ × ⌈h/28⌉` visual tokens. Claude 4.7 and later models (including Opus 5.5 and Sonnet 5.5) are on the high-resolution tier: long edge up to 2,576 px, at most 4,784 tokens per image. Older models such as Haiku 4.5 are on the standard tier: 1,568 px, at most 1,568 tokens. A 1920×1080 image costs 2,691 tokens on the high-resolution tier and 1,560 on the standard tier. [Vision → Resolution and token cost](https://platform.claude.com/docs/en/build-with-claude/vision)
- The docs don't say what resolution PDF pages are rendered at. Measure it with `count_tokens` or `usage` on a real deck.
- The best-practice list says to put the PDF before the text prompt, use logical page numbers in prompts, and turn on prompt caching for repeated analysis. [PDF support → Optimize](https://platform.claude.com/docs/en/build-with-claude/pdf-support)
- PPTX isn't an accepted document type. The document types are PDF, plain text and custom content. [Citations → Document types](https://platform.claude.com/docs/en/build-with-claude/citations)

### Claude through Claude Code (`claude -p`)

- Claude reads files with the **Read** tool. Short PDFs are read whole. PDFs over 10 pages are read in page ranges of at most **20 pages per call**, and page-range reads render pages with **`pdftoppm` (poppler)**, which has to be installed (`brew install poppler`). [Tools reference → Read tool behavior](https://code.claude.com/docs/en/tools-reference)
  - Consequence: a 60-slide deck takes at least 3 Read calls. The docs don't say whether a page-range read also carries the page text or only the rendered images.
- Read resizes and recompresses large images, so Claude may see a smaller copy. [Tools reference → Read](https://code.claude.com/docs/en/tools-reference)
- With streaming input (`--input-format stream-json`, or the SDK), you can attach base64 **image** blocks to user messages. **`document` blocks aren't documented** for this surface. [Agent SDK → Streaming input](https://code.claude.com/docs/en/agent-sdk/streaming-vs-single-mode)
- **Inference:** the most controllable route on Claude Code is for the app to prepare the input. PDFKit pulls the text of each page, the app renders page PNGs, and the prompt carries a per-slide text manifest with image paths for Read. That avoids depending on poppler and the 20-page read limit.

### Gemini API

- PDFs are read with native vision: text, images, diagrams, charts and tables. Limits are **50 MB or 1,000 pages**, inline or through the Files API. Uploaded files are kept for 48 hours, at no cost. [Document understanding](https://ai.google.dev/gemini-api/docs/document-processing)
- Gemini 3 models get the PDF's native text too, and **you aren't charged for native-text tokens**. Page tokens are reported under the `IMAGE` modality. [Document understanding → Gemini 3 models](https://ai.google.dev/gemini-api/docs/document-processing)
- You can set `media_resolution` per part. For a PDF on Gemini 3: `low` = 280, `medium` = 560, `high` = 1,120 tokens per page, plus native text. The default (`unspecified`) is 560. Google says `high` gives the best quality for most uses and recommends medium/high for dense documents. [Media resolution](https://ai.google.dev/gemini-api/docs/media-resolution)
- On older models, pages are scaled to between 768² and 3072² and each page costs 258 tokens. [Document understanding → Technical details](https://ai.google.dev/gemini-api/docs/document-processing)
- **Only PDFs get vision.** Other MIME types are read as plain text, and charts and formatting are lost. [Document understanding → Document types](https://ai.google.dev/gemini-api/docs/document-processing)
- PPTX is accepted only by File Search (RAG), which lists `application/vnd.openxmlformats-officedocument.presentationml.presentation`. [File Search](https://ai.google.dev/gemini-api/docs/file-search)

### PPTX → PDF on macOS

| Option | Works? | Notes |
|---|---|---|
| **Keynote via AppleScript** (`export document to file as PDF`) | Yes | Keynote's scripting dictionary (`/Applications/Keynote.app/Contents/Resources/Keynote.sdef`) has the export format `PDF` and export options `all stages` (one page per build stage when true), `skipped slides`, `slide numbers`, `export style` (include notes) and `PDF image quality`. Each slide has a `presenter notes` property. Keynote opens .pptx. Calling it needs Apple Events: `NSAppleEventsUsageDescription` and the user's Automation consent. The app isn't sandboxed (see CLAUDE.md), so no temporary-exception entitlement is needed. **Inference:** set `all stages` to false and `skipped slides` to true so page N = slide N. |
| Microsoft PowerPoint via AppleScript | Probably | Installed on this Mac. Its dictionary wasn't checked. Use it as a fallback. |
| LibreOffice `soffice --headless --convert-to pdf` | Yes, but not installed | Third-party dependency, so not first choice. |
| PDFKit | No | `PDFDocument` opens PDFs only. It's what you use *after* conversion: `PDFPage.string` returns the page text, which the citation check needs. [PDFPage.string](https://developer.apple.com/documentation/pdfkit/pdfpage/string) |
| Quick Look (`QLThumbnailGenerator`) | No | Makes a thumbnail image for a file ([QLThumbnailGenerator](https://developer.apple.com/documentation/quicklookthumbnailing/qlthumbnailgenerator)), not a multi-page PDF. |

Canvas often hosts the instructor's own PDF export as well. Prefer that file when there is one; ticket #71 covers what Canvas provides.

## 2. Citations: can each concept carry a slide reference?

### Claude Citations (Messages API only)

- GA on every active model. Turn it on with `citations: {enabled: true}` on each `document` block. [Citations](https://platform.claude.com/docs/en/build-with-claude/citations)
- PDF citations are **`page_location`**, with `start_page_number` (1-indexed) and `end_page_number` (exclusive). A **custom content** document gives `content_block_location` block indices, and it isn't split any further. Sending one text block per slide would therefore give slide-level citations. [Citations → Citation indices, Document types](https://platform.claude.com/docs/en/build-with-claude/citations)
- **Only text can be cited.** "Citing images from PDFs is not currently supported," and scanned PDFs with no extractable text "are not citable". Image-only slides can't carry a Claude citation. [Citations](https://platform.claude.com/docs/en/build-with-claude/citations)
- **Can't be combined with structured outputs.** Turning on citations with `output_config.format` returns a 400. [Citations](https://platform.claude.com/docs/en/build-with-claude/citations); [Structured outputs → Feature compatibility](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- Works with prompt caching and batches. `cited_text` doesn't count toward output tokens. [Citations → Token costs / Feature compatibility](https://platform.claude.com/docs/en/build-with-claude/citations)
- **Not available through `claude -p`.** None of the CLI or headless flags turn it on, and document blocks aren't documented for streaming input. [CLI reference](https://code.claude.com/docs/en/cli-reference); [Headless](https://code.claude.com/docs/en/headless)

### Gemini

- There's no citation feature for a PDF passed inline or by `file_uri`. (No such feature appears in [Document understanding](https://ai.google.dev/gemini-api/docs/document-processing) or [Structured output](https://ai.google.dev/gemini-api/docs/structured-output).)
- **File Search** returns `file_citation` annotations with `page_number` for paged documents, and on Gemini 3 it can be combined with structured output. It is retrieval over chunks, though, so the model sees only the chunks retrieved, not the whole deck. Indexing is billed at embedding rates. [File Search → Citations / Page numbers / Structured output](https://ai.google.dev/gemini-api/docs/file-search)
- **Inference:** File Search fits a later "ask questions about my course" feature better than exhaustive extraction.

### Recommendation

Use a vendor-neutral citation the app can check:

```json
{"concepts":[{"title":"…","definition":"…","kind":"…","slide":12,"evidence":"verbatim phrase from slide 12","gapFill":false, "...":"…"}]}
```

- The app checks that `evidence` is a normalized substring of `PDFPage.string` for page `slide`. If it passes, the citation is verified. If it fails, the concept gets a "citation unverified" flag (a likely hallucination or an off-by-one page).
- Slides with no text layer, or where the evidence is visual (a diagram or a math image): the model sets something like `evidenceKind: "visual"`. The citation stays unverified and the concept gets a low-confidence flag. That matches the map's "accept by default, flag exceptions" rule.
- The same scheme works on Claude Code, the Claude API and Gemini, which keeps vendors swappable.

## 3. Structured output

| Surface | Mechanism | Limits / notes |
|---|---|---|
| Claude API | `output_config.format` (JSON schema) or `strict: true` tools. **Constrained decoding**, so the output always matches the schema. | Not supported: recursive schemas, numeric/length constraints (`minimum`, `maxLength` and so on). At most 24 optional parameters and 16 union-typed parameters across all strict schemas. Grammar compilation times out after 180 s. The first request with a new schema is slower; compiled grammars are cached for 24 h. Changing the schema invalidates the prompt cache. **Can't be combined with Citations.** [Structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) |
| Claude Code `claude -p` | `--output-format json --json-schema '<schema>'`. The result is in `structured_output`. | **Checked after generation and re-prompted on a mismatch, not constrained.** Fails with `error_max_structured_output_retries`. Schemas must be JSON Schema draft-07. `format` is accepted only as an annotation. [Headless → Get structured output](https://code.claude.com/docs/en/headless); [Agent SDK structured outputs](https://code.claude.com/docs/en/agent-sdk/structured-outputs); [CLI reference](https://code.claude.com/docs/en/cli-reference) |
| Gemini API | `response_format` with `mime_type: application/json` and `schema`. Supports a subset of JSON Schema: types, `enum`, `items`, `prefixItems`, `anyOf`, `additionalProperties`, recursive schemas, nullable through type arrays. | "Very large or deeply nested schemas may be rejected." Google says to still validate values in the app. Combining it with built-in tools is Preview, Gemini 3 only. [Structured output](https://ai.google.dev/gemini-api/docs/structured-output) |

**Inference:** design the concept schema to fit the strictest of these: all fields required (use `null` or `""` instead of optional), a flat concept array, enums for `kind`, and no numeric constraints. Validate on the app side either way.

## 4. Prompt caching for multi-step runs

Intake reads the same deck several times (Extract, then Shape practice, and any re-runs). Put the deck first and the step-specific instructions after it.

- **Claude API:** set `cache_control` breakpoints (at most 4) or use automatic top-level caching. TTL is 5 min by default or `"ttl": "1h"`. Writes cost 1.25× base input (5 min) or 2× (1 h). Reads cost 0.1× base, and **0.05× on Opus 5.5 ($0.20/MTok)**. The minimum cacheable prefix is 512 tokens on Opus 5.5 and Sonnet 5.5, and 4,096 on Haiku 4.5. The TTL counts from the start of the request. [Prompt caching](https://platform.claude.com/docs/en/build-with-claude/prompt-caching); [Pricing](https://platform.claude.com/docs/en/about-claude/pricing)
- **Claude Code:** the SDK caches prompts automatically, and you don't set it up yourself. `usage` reports `cache_creation_input_tokens` and `cache_read_input_tokens`. [Agent SDK cost tracking → Track cache tokens](https://code.claude.com/docs/en/agent-sdk/cost-tracking). There's no control over breakpoints or TTL. `--exclude-dynamic-system-prompt-sections` improves cache reuse across machines. [CLI reference](https://code.claude.com/docs/en/cli-reference). **Inference:** to share the cache across steps, run them as `--resume`d turns of one session within the TTL instead of as separate cold `-p` calls.
- **Gemini:** implicit caching is on by default for 2.5+. The minimum is 4,096 tokens on 3.x (2,048 on 2.5). It works with stateful (`previous_interaction_id`) and stateless calls, and hits are reported in `usage.total_cached_tokens`. Explicit caches (default TTL 1 h, with storage billed per hour) exist **only on `generateContent`, not the Interactions API**. [Caching](https://ai.google.dev/gemini-api/docs/caching); [Explicit caching](https://ai.google.dev/gemini-api/docs/generate-content/caching). Cached-token prices: 3.8 Flash $0.075/MTok plus $0.50/MTok-hour storage; 3.1 Pro Preview $0.20/MTok. [Pricing](https://ai.google.dev/gemini-api/docs/pricing)

## 5. Models and price (API list prices; subscription usage is covered by #74)

| Model | Input / output per MTok | Cache read | Notes |
|---|---|---|---|
| Claude Opus 5.5 `claude-opus-5-5` | $4 / $20 | $0.20 | 1M context, high-res vision. Thinking can't be turned off; effort defaults to `medium`. [Pricing](https://platform.claude.com/docs/en/about-claude/pricing) |
| Claude Sonnet 5.5 `claude-sonnet-5-5` | $2 / $10 | $0.20 | 1M context, high-res vision. |
| Claude Haiku 4.5 `claude-haiku-4-5` | $1 / $5 | $0.10 | 200K context, so **100-page PDF limit**. Standard-res vision. Minimum cacheable prefix is 4,096 tokens. |
| Gemini 3.8 Flash `gemini-3.8-flash` | $0.75 / $3.75 until 2026-12-31, then $1.50 / $7.50 | $0.075 (+ storage) | Stable. Free tier available. [Pricing](https://ai.google.dev/gemini-api/docs/pricing); [Models](https://ai.google.dev/gemini-api/docs/models) |
| Gemini 3.5 Flash-Lite `gemini-3.5-flash-lite` | $0.30 / $2.50 | $0.03 | Stable, cheapest. |
| Gemini 3.1 Pro `gemini-3.1-pro-preview` | $2 / $12 (≤200k) | $0.20 | **Preview only**, no free tier. |

- **Gemini free-tier privacy:** on the free tier, Google uses prompts "to improve our products". The paid tier doesn't. [Pricing](https://ai.google.dev/gemini-api/docs/pricing) Course slides are low-sensitivity, but the API-key setup in Settings should mention this.
- Gemini 2.5 models are limited to existing users. [Models](https://ai.google.dev/gemini-api/docs/models)
- With `claude -p`, `--model` takes an alias (`sonnet`, `opus`, `haiku`) or a full ID, and `--effort` sets effort. `--fallback-model` sets a fallback chain. [CLI reference](https://code.claude.com/docs/en/cli-reference)
- **Inference on quality:** none of these sources has a published benchmark for slide-concept extraction. Choose in #76 (extraction bake-off) by running the same 2–3 real decks (one math-heavy, one diagram-heavy, one coding) through Gemini 3.8 Flash at `high` resolution and Claude Sonnet 5.5, and comparing them with the citation check above.

## 6. Size of a typical 40–60-slide deck (50 slides)

| Vendor | Per slide | 50 slides | Input cost per pass |
|---|---|---|---|
| Gemini 3.x, default/medium | 560 + free native text | ~28k | 3.8 Flash ≈ $0.02; 3.1 Pro ≈ $0.06 |
| Gemini 3.x, `high` | 1,120 + free native text | ~56k | 3.8 Flash ≈ $0.04; 3.1 Pro ≈ $0.11 |
| Claude Opus 5.5 / Sonnet 5.5 (estimate) | image ≤ 4,784 (≈2.7k at 1080p) + text (slides are sparse, so likely well under the 1.5–3k/page document figure) | **~80k–250k** | Sonnet ≈ $0.16–0.50; Opus ≈ $0.32–1.00; cached re-reads ≈ $0.02–0.05 |
| Claude Haiku 4.5 (estimate) | image ≤ 1,568 + text | ~80k–150k | ≈ $0.08–0.15 |

Output adds to this. A concept list for 50 slides is probably 5–15k output tokens plus thinking: about $0.05–0.30 on Sonnet or Opus, and cents on Flash. **Inference:** the Claude figures are bounds worked out from the vision formula, because the docs don't give the PDF page render size. Measure a real deck once with `count_tokens` (free) or the `usage` in `claude -p --output-format json`. The JSON output also includes a client-side `total_cost_usd` estimate. [Headless](https://code.claude.com/docs/en/headless)

## 7. Math-heavy and image-only slides

- **Math:** both vendors send page images, so equations rendered as glyphs or images can be read even when the PDF text layer is garbled. [Claude PDF support](https://platform.claude.com/docs/en/build-with-claude/pdf-support); [Gemini document understanding](https://ai.google.dev/gemini-api/docs/document-processing). **Inference:** ask for definitions in Markdown with LaTeX (`$…$`), since the app already renders KaTeX. On Gemini, use `high` resolution for those decks. On Claude, Opus 5.5 and Sonnet 5.5 are already on the high-res tier.
- **Image-only slides:** both vendors can *read* them through vision. Claude Citations can't *cite* them, and PDFKit has no text to check evidence against. Flag those concepts as unverified. The flag-review screen (not yet specified in #70) should show the slide image next to the concept.

## 8. Claude Code (`claude -p`) vs the Messages API: gaps

| Feature | Messages API | `claude -p` (subscription) |
|---|---|---|
| PDF as a document block (text + image per page) | Yes | No. Only the Read tool: at most 20 pages per call, with poppler needed for page ranges |
| Citations | Yes | **No** |
| Constrained JSON schema | Yes | **Checked afterwards and retried** (`--json-schema`) |
| Prompt cache control (breakpoints, 1 h TTL) | Yes | Automatic only |
| Batches (50% off) | Yes | No |
| Model / effort choice | Yes | `--model`, `--effort` |
| Spend cap | n/a | `--max-budget-usd`, `--max-turns` |
| Cost / usage readout | `usage` | `usage`, `total_cost_usd` (client-side estimate) |

**Running `claude -p` cleanly with the subscription:**
- `--bare` would skip the user's CLAUDE.md, hooks, MCP servers and skills, but it **doesn't use the subscription login**: it needs `ANTHROPIC_API_KEY`. [Headless → bare mode](https://code.claude.com/docs/en/headless)
- `--safe-mode` turns off CLAUDE.md, skills, plugins, hooks, MCP servers and auto memory, while "authentication, model selection, built-in tools, and permissions work normally". [CLI reference](https://code.claude.com/docs/en/cli-reference)
- Without either flag, a `-p` session runs the project's hooks and `.mcp.json` servers with no trust prompt. [Headless](https://code.claude.com/docs/en/headless)
- **Inference:** run intake as `claude -p --safe-mode --tools Read --system-prompt-file … --output-format json --json-schema … --max-budget-usd …` from an empty temporary working directory that holds only the prepared slide files. Verify that `--safe-mode` keeps the subscription OAuth login before relying on it.

## What this changes in the map (#70)

- **The map's "every concept cites file + slide/page" can't depend on a vendor citation feature** on either required path. Citations should be the model's self-reported `slide` + `evidence`, checked by the app with PDFKit. The "no citation" flag becomes "citation unverified", which covers hallucinated, off-by-one and visual-only cases.
- **Add a conversion step before Extract:** PPTX → PDF through Keynote AppleScript (Automation permission prompt), plus per-page text extraction with PDFKit. The concept model (#77) should store page = slide number. Presenter notes are another possible text source.
- **The Claude Code path needs a hardened invocation** (`--safe-mode`, a restricted tool set, an isolated working directory, a budget cap). It may also need poppler, unless the app pre-renders page images. This is a build-time dependency worth recording.
- The raw Claude Messages API (API key) would get Citations, constrained JSON and batches. It isn't on the map's required path list; adding it would be an optional third adapter.
