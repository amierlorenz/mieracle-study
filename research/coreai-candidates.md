# Core AI candidate models for Shape (study-prompt writing)

Research date: 2026-10-03. Repo checked: `apple/coreai-models` @ `52c84ba` (2026-10-02), shallow clone at
`/Users/amierld/.claude/jobs/d6c4e61e/tmp/coreai-models`. Paths below are relative to that clone unless they are URLs.

Target machine (checked locally): Apple M2 Pro, 16 GB unified memory (`hw.memsize` = 17179869184), macOS 27.0.1 (26A434), Xcode 27.0 (27A266a), `uv` 0.11.7 installed, **43 GiB free** on the data volume (96% full).

Key: **[src]** = read in repo source/docs; **[doc]** = Apple developer docs; **[HF]** = Hugging Face API/model card; **[est]** = my arithmetic, not published; **[unverified]** = not confirmed.

---

## TL;DR

| Rank | Model (registry short name) | Why | Gated? | Est. `.aimodel` | Fits 16 GB? |
|---|---|---|---|---|---|
| 1 | **Qwen3-8B** (`qwen3-8b`) | Strongest model that fits with headroom; Apache-2.0; byte-level BPE matches the grammar engine's default vocab mode | No | ~4.6 GB [est] | Yes |
| 2 | **Gemma 3 12B-it** (`gemma3-12b-it`) | Bigger, best-known quality in the fit range; but tight memory and a tokenizer-type risk for constrained decoding (see below) | **Yes** (HF license click-through + `hf auth login`) | ~6.6 GB [est] | Tight |
| 3 | **Qwen3-4B** (`qwen3-4b`) | Same pipeline as #1, half the size: speed/quality baseline | No | ~2.3 GB [est] | Easily |
| reserve | Phi-4-mini-instruct (`phi-4-mini-instruct`) | MIT, strong math (MATH 64.0) but Microsoft warns of weak factual recall | No | ~3.3 GB [est] | Yes |

**Not feasible:** Qwen3-Coder-30B-A3B (the only `qwen3_moe` preset) is ~17 GB at 4-bit. gpt-oss-20b is ~13–14 GB, which leaves no headroom. Muse-Glimmer-30B and Mixtral-8x7B are both larger. **Gemma 4 is iOS-only** in this catalog and needs iOS 27.2+, so it is out.

**Integration headline:** `CoreAILanguageModel` (from the `CoreAILM` product of the repo's Swift package) **conforms to Foundation Models' `LanguageModel` protocol**. So `LanguageModelSession(model:)` with `@Generable`/`GenerationSchema` works unchanged, and xgrammar enforces the schema. For a throwaway test you can use `llm-runner --json-schema` or the OpenAI-compatible `llm-server` with `response_format: {type: "json_schema"}`.

**LaTeX risk:** Core AI uses the standard xgrammar JSON grammar. A single-backslash `\t`, `\b`, `\f`, `\n`, `\r` is a *legal* JSON escape, and any other single backslash (`\g`, `\s`) is *masked*, so the model is pushed to some other token. That is exactly the failure seen with the on-device FM model. Core AI does nothing special about it, but a JSON-schema `pattern` on each LaTeX-bearing string can forbid those escapes at the grammar level (details in Q2).

---

## 1. Catalog filtered to the user's Mac

Authoritative list from `uv run coreai.model.registry --list-models --type llm --platform macOS` (same output with `--experimental`):

```
SHORT_NAME                       PLATFORM   COMPRESSION                                 CTX  HF_ID
qwen2.5-1.5b-instruct            macOS      4bit                                      32768  Qwen/Qwen2.5-1.5B-Instruct
qwen2.5-1.5b-instruct-8bit-kv    macOS      4bit_weights_8bit_kv_cache                32768  Qwen/Qwen2.5-1.5B-Instruct
qwen3-0.6b                       macOS      4bit                                       8192  Qwen/Qwen3-0.6B
qwen3-1.7b                       macOS      4bit                                      32768  Qwen/Qwen3-1.7B
qwen3-4b                         macOS      4bit                                      40960  Qwen/Qwen3-4B
qwen3-4b-8bit-kv                 macOS      4bit_weights_8bit_kv_cache                40960  Qwen/Qwen3-4B
qwen3-8b                         macOS      4bit                                      40960  Qwen/Qwen3-8B
qwen3-coder-30b-a3b-instruct     macOS      4bit                                     262144  Qwen/Qwen3-Coder-30B-A3B-Instruct
gemma3-4b-it                     macOS      4bit                                     131072  google/gemma-3-4b-it
gemma3-12b-it                    macOS      4bit                                     131072  google/gemma-3-12b-it
mistral-7b-instruct-v0.3         macOS      4bit                                       8192  mistralai/Mistral-7B-Instruct-v0.3
mixtral-8x7b-instruct-v0.1       macOS      4bit                                      32768  mistralai/Mixtral-8x7B-Instruct-v0.1
gpt-oss-20b                      macOS      none                                      32768  openai/gpt-oss-20b
phi-4-mini-instruct              macOS      phi_4bit_down_int8.yaml                  131072  microsoft/Phi-4-mini-instruct
phi-3-mini-instruct              macOS      phi_4bit_embedding_excluded.yaml           4096  microsoft/Phi-3-mini-4k-instruct
phi-3.5-mini-instruct            macOS      phi_4bit_embedding_excluded.yaml         131072  microsoft/Phi-3.5-mini-instruct
muse-glimmer-30b                 macOS      4bit                                     131072  meta-models/Muse-Glimmer-30B
muse-glimmer-30b-drafter         macOS      none                                     131072  meta-models/Muse-Glimmer-30B-assistant
smollm2-1.7b-instruct            macOS      smollm2_4bit_embedding_excluded.yaml       8192  HuggingFaceTB/SmolLM2-1.7B-Instruct
smollm2-360m-instruct            macOS      none                                       8192  HuggingFaceTB/SmolLM2-360M-Instruct
smollm2-135m-instruct            macOS      none                                       8192  HuggingFaceTB/SmolLM2-135M-Instruct
gemma-3n-e2b-it                  macOS      gemma3n_e2b_4bit_embedding_excluded.yaml    32768  google/gemma-3n-E2B-it
gemma-3n-e4b-it                  macOS      gemma3n_e2b_4bit_embedding_excluded.yaml    32768  google/gemma-3n-E4B-it
gemma-3n-e2b / gemma-3n-e4b      (base, not instruct)
olmo2-1b-instruct                macOS      4bit                                       4096  allenai/OLMo-2-0425-1B-Instruct
```

The macOS `4bit` preset is "INT4 weight-only, block size 32 (all layers)", which is 4.50 bits per weight (`models/README.md` → Quantization Options; the BPW columns in each card). Size estimate = params × 4.5 / 8 [est].

| Model | Params [HF] | Est. 4-bit size | Verdict on 16 GB |
|---|---|---|---|
| Qwen3-0.6B / 1.7B, SmolLM2, OLMo2-1B, Qwen2.5-1.5B | ≤1.7B | <1 GB | Fit, but too weak for exact definitions/MCQ distractors |
| Qwen3-4B | 4.02B | ~2.3 GB | Fit |
| Phi-4-mini | 3.84B | ~3.3 GB (FP16 embedding + INT8 down_proj, "~5.5 BPW") | Fit |
| Gemma 3 4B-it | 4.30B (text part smaller) | ~2.4 GB | Fit |
| Mistral-7B-v0.3 | 7.25B | ~4.1 GB | Fit, but old (2024), 8K context preset, SentencePiece |
| Qwen3-8B | 8.19B | ~4.6 GB | **Fit** |
| Gemma 3n E4B-it | 7.85B (embedding excluded from quant) | ~5–6 GB [unverified] | Fit, but 4-bit perplexity jumps 9.83→12.46 (`models/gemma3n/README.md`) |
| Gemma 3 12B-it | 12.19B (text-only export: `python/src/coreai_models/models/macos/gemma3_text.py`) | ~6.6 GB | **Tight but OK** |
| gpt-oss-20b | 20.9B, MXFP4 experts kept as Float4 with a runtime dequantize (`models/macos/gpt_oss.py` ~L340–375) | ~13–14 GB (HF safetensors 13.76 GB) | **No headroom** |
| Qwen3-Coder-30B-A3B (only `qwen3_moe`) | 30.5B | ~17.2 GB | **No** (also a coding model) |
| Muse-Glimmer-30B, Mixtral-8x7B | 29.6B / 46.7B | ≥16 GB | No |

### Gemma 4 "27.2+"
`models/gemma4/README.md` lists Gemma 4 E2B/E4B **only in an iOS column** ("Yes (27.2+)"). `models/gemma4/export.py` has only an `_export_ios` path (static-shape, ANE-style buckets), and Gemma 4 is **absent from the macOS registry listing**. "27.2+" refers to iOS 27.2. There is no macOS preset, and the user's Mac is on 27.0.1 anyway. Excluded. (Its MMLU after 4-bit: E4B 0.6546, E2B 0.5240, per the same card.)

### Schema-constrained output support
Every LLM engine supports guided generation. `InferenceEngine.supportsGuidedGeneration` = `supportsLogits || self is ConstrainedGenerationCapable` (`swift/Sources/CoreAILanguageModels/InferenceEngines/InferenceEngine.swift` ~L200). The sequential, static-shape and VLM engines return logits. The default macOS GPU engine, `CoreAIPipelinedEngine`, conforms to `ConstrainedGenerationCapable` and masks on the GPU. So all macOS candidates qualify, with one tokenizer caveat:

**Tokenizer-type risk [src + inference, unverified at runtime].** Grammar vocab is always built with `VocabularyType.byteLevel` (the default in `ConstrainedGenerationSession.init`, `GuidedGeneration/ConstrainedGenerationSession.swift` L62/L132). No production code path passes `.byteFallback`, and nothing in `CoreAILanguageModels` handles SentencePiece `▁`/`<0xNN>` tokens for the grammar. Byte-level BPE vocabularies (Qwen2.5/Qwen3, Phi-4-mini's o200k-style, gpt-oss) match. SentencePiece-derived vocabularies (Gemma 3/3n, Mistral, Phi-3) may get wrong masks: spaces or backslash byte tokens could be treated incorrectly inside strings. If Gemma 3 12B produces odd spacing or refuses `\\` under a schema, this is the likely cause. That is one more reason Qwen3-8B is #1.

---

## 2. Candidate details

Common export setup (repo root): `uv sync` is implicit in `uv run`. The export downloads HF weights to the HF cache (full-precision safetensors), traces with a memory-efficient mmap path into a temp dir on macOS (`python/src/coreai_models/export/pipeline.py` L212–228), and writes `<repo>/exports/<output-name>/`, a folder with the `.aimodel`, `tokenizer/` and `metadata.json`. Disk needed ≈ HF download + export output + temp. **With 43 GiB free, do one model at a time and clear the HF cache between exports.**

Exact preset args come from `uv run coreai.model.registry --type llm --model-info <name> --platform macOS --as-export-args` / `--as-output-name`.

**No model card in the repo publishes tokens/s or runtime memory.** Cards publish only WikiText-2 perplexity (Gemma 4: MMLU). Measure with `swift run -c release llm-benchmark --model <folder>` (defaults: 512 prompt tokens, 1024 generated, 5 trials; `-p/-g/-n`). The tok/s figures below are bandwidth-bound ceilings [est] for M2 Pro (200 GB/s ÷ weight bytes); expect roughly 50–70% of them in practice [unverified].

### #1 Qwen3-8B
- Export: `uv run coreai.llm.export qwen3-8b` (equivalent to `Qwen/Qwen3-8B --compression 4bit --compute-precision float16 --max-context-length 40960`) → `exports/qwen3_8b_4bit_dynamic/`
- Gating: **none**. Apache-2.0 [HF]. HF download 16.4 GB.
- Size: ~4.6 GB `.aimodel` [est]. Runtime: weights + KV cache at fp16 ≈ 2·36 layers·8 KV heads·128·2 B ≈ 147 KB/token, so ~0.3 GB at 2K tokens [est]. Total ~5–5.5 GB.
- Speed ceiling ≈ 43 tok/s [est]; realistic ~20–30 [unverified].
- Context: 40,960 preset (native 32K; the HF card says YaRN to 131K).
- Quality: perplexity 12.19 (fp16) → **12.90 at 4-bit**, the smallest quantization loss in the catalog (`models/qwen3/README.md`). Hybrid thinking model. **Run it non-thinking**: HF card recommends `enable_thinking=False`, temperature 0.7, top-p 0.8, top-k 20 for non-thinking mode.
- Constrained decoding: byte-level BPE matches xgrammar's `.byteLevel`.

### #2 Gemma 3 12B-it
- Export: `uv run coreai.llm.export gemma3-12b-it` (= `google/gemma-3-12b-it --compression 4bit --compute-precision bfloat16 --max-context-length 131072`; bf16 is required, per `models/gemma3/README.md`) → `exports/gemma_3_12b_it_4bit_dynamic/`
- Gating: **yes**. HF `gated: manual`, Gemma license. Accept the license on HF, then `brew install hf && hf auth login`. HF download 24.4 GB, which is a lot against 43 GiB free.
- Size: ~6.6 GB [est]. KV ≈ 2·48·8·256·2 B ≈ 393 KB/token, so ~0.8 GB at 2K [est]. Total ~7.5–8 GB. Fits, but Metal's default working-set cap on a 16 GB Mac is about 2/3 of RAM [unverified], so close other heavy apps. Consider `--max-context-length 8192` to cut graph/program size.
- Speed ceiling ≈ 30 tok/s [est]; realistic ~12–20 [unverified].
- Quality [HF card]: MMLU 74.5, MMLU-Pro 45.3, MATH 43.3, GSM8K 71.0, GPQA 25.4. Repo perplexity 11.24 → 11.75 at 4-bit.
- Caveat: SentencePiece vocab vs `.byteLevel` grammar vocab (see above). Test this first with a LaTeX-heavy schema.

### #3 Qwen3-4B
- Export: `uv run coreai.llm.export qwen3-4b` → `exports/qwen3_4b_4bit_dynamic/`. Optionally `--compression 4bit_weights_8bit_kv_cache` (the preset `qwen3-4b-8bit-kv`).
- Gating: none, Apache-2.0. HF download 8.0 GB. ~2.3 GB `.aimodel` [est]. Speed ceiling ≈ 85 tok/s [est].
- Quality: perplexity 16.41 → 18.33 at 4-bit (bigger loss than 8B). Useful as the "is the 8B worth it?" control.

### Reserve: Phi-4-mini-instruct
- `uv run coreai.llm.export phi-4-mini-instruct` (uses `models/phi/phi_4bit_down_int8.yaml`). MIT, not gated. HF download 7.7 GB. ~3.3 GB.
- HF card: MMLU 67.3, MMLU-Pro 52.8, MATH 64.0, GSM8K 88.6, GPQA 25.2. Microsoft: "does not have the capacity to store too much factual knowledge". That is fine when Shape feeds it the source text, but weak for recall. The repo notes INT4 `down_proj` is "numerically fragile on some Apple GPU families", hence INT8.

### qwen3_moe and gpt-oss on 16 GB
- **Qwen3-Coder-30B-A3B**: only 3B active, but all 30.5B params must be resident: ~17.2 GB at 4.5 BPW (card BPW 4.50). It does not fit. There is no Qwen3-30B-A3B *Instruct* (non-coder) preset.
- **gpt-oss-20b**: preset compression `none` because the checkpoint is already MXFP4. The exporter keeps experts as `Float4Tensor` with a `WeightDequantize` parametrization, so the asset is roughly the 13.76 GB checkpoint size [est]. Add KV and the OS and you exceed a safe budget on 16 GB. It is also a harmony-format reasoning model. **Not feasible with headroom.**

---

## Q1. Calling a model with a JSON schema

### (a) Foundation Models API (recommended for the app and for a Swift script)
`CoreAILanguageModel: LanguageModel` (`swift/Sources/CoreAILanguageModels/LanguageModel/CoreAILanguageModel.swift`). Its executor receives `request.schema` (a `GenerationSchema`), JSON-encodes it, and runs `PipelinedConstrainedDecodingStrategy` (GPU engine) or `ConstrainedDecodingStrategy` (L301–321, L534–593). Default max tokens is 512, or 2048 for reasoning models (L293). Default sampling is greedy unless `GenerationOptions.temperature` is set (L134, L799–807).

```swift
import FoundationModels
import CoreAILanguageModels   // SwiftPM: https://github.com/apple/coreai-models, product "CoreAILM"

@Generable struct MCQ { var stem: String; var options: [String]; var answerIndex: Int }

let model = try await CoreAILanguageModel(resourcesAt: folderURL, mode: .eager)
let session = LanguageModelSession(model: model, instructions: "…")
let mcq = try await session.respond(to: prompt, generating: MCQ.self).content
```

- **Thinking:** reasoning effort maps through `ContextOptions.ReasoningLevel` (`.custom("none")` → `enable_thinking: false` in the chat template, L710–733). For Qwen3, ask for no reasoning, because the grammar forces `{` as the first token anyway. The exact session-level API for passing `ContextOptions` is [unverified].
- The capabilities list includes `.guidedGeneration` (L76–82).
- Package minimums: `platforms: [.macOS("27.0"), .iOS("27.0")]` (`Package.swift`). MieracleKit is `.macOS(.v27), .iOS(.v26)`, so link CoreAILM only into the macOS target, or wait for the iOS 27 restore. Otherwise SwiftPM will reject the iOS 26 client [unverified exact error].

### (b) Low-level `ConstrainedGenerationSession`
`ConstrainedGenerationSession(jsonSchema:tokenizer:vocabSize:vocabType:stopTokenIds:)` → `applyMask(to:&logits)` / `fillBitmask(into:)` → sample → `acceptToken(_:)`, plus `isTerminated`, `rollback`, `findJumpForwardString` (`GuidedGeneration/ConstrainedGenerationSession.swift`). It compiles via `GrammarCompiler.compileJSONSchema(_, anyWhitespace: true, strictMode: true)` (`XGrammarWrapper.swift`), with xgrammar pinned at `exact: "0.2.2"` (`Package.swift`). Note: `stopTokenIds` is accepted by the vocabulary init but never forwarded to `TokenizerInfo` (L60–71) [src]. `ConstrainedGenerator` gives `generate(prompt:type:)` / `generateJSON(prompt:jsonSchema:)`. You only need these if you bypass Foundation Models.

### (c) CLI: `llm-runner` (best for the bake-off script)
From the repo root:
```bash
swift run -c release llm-runner --model exports/qwen3_8b_4bit_dynamic \
  --prompt-file prompt.txt --json-schema schema.json --max-tokens 800 --temperature 0
```
`--json-schema` accepts a schema string or a file path (`Tools/llm-runner/LLMRunnerMain.swift` L126–131, L776–820). The chat template is applied by default (`--apply-chat-template true`). It picks the GPU-pipelined constrained strategy when available. `--repetition-penalty` is rejected together with `--json-schema` (L283).

### (d) CLI: `llm-server` (OpenAI-compatible)
```bash
swift run -c release llm-server --model exports/qwen3_8b_4bit_dynamic --port 8080 \
  --no-thinking --temperature 0 --max-tokens 1024 [--variant coreai-sequential]
```
- Abstract: "Start an OpenAI-compatible HTTP server for LLM inference" (`Tools/llm-server/LLMServerMain.swift`). Binds `127.0.0.1`.
- Routes (`ChatHandler.swift` L17–80): `POST /v1/chat/completions` (also `POST /v1`), `POST /v1/completions` (loglikelihood; only when the engine supports logits), `GET /v1/models`, `GET /v1/stats`, `GET /health`, `GET /ready`.
- Request fields (`CoreAILMCommon/ServerAPITypes.swift`): `messages, temperature, max_tokens, max_completion_tokens, top_p, top_k, seed, stream, stop, response_format, tools, tool_choice, parallel_tool_calls, reasoning_effort, raw`.
- **`response_format` supported:** `{"type":"json_schema","json_schema":{"name":…,"schema":{…}}}` → that schema; `{"type":"json_object"}` → schema `{}`. (`strict` is ignored, since xgrammar always runs in strict mode.)
- **Gotcha [src, inferred, not run]:** the server always uses the CPU-side `ConstrainedDecodingStrategy` (`ChatHandler.swift` L226–228, L456–457), which requires per-step logits (`ConstrainedDecodingStrategy.swift` L134: "No logits returned from engine"). The default macOS engine is the GPU pipelined one with `supportsLogits == false`, and the server prints "use --variant coreai-sequential" for logprobs. If schema requests fail on the server, add `--variant coreai-sequential` (slower), or use `llm-runner` / the FM API, which pick the GPU path.

---

## Q2. Do LaTeX backslashes survive constrained JSON decoding?

**Nothing in Core AI specifically handles JSON string escaping.** The grammar is xgrammar's stock JSON-schema conversion. In xgrammar v0.2.2 `cpp/json_schema_converter.cc` L1230, the string escape rule is:

```
basic_escape ::= ["\\/bfnrt] | "u" [A-Fa-f0-9]{4}
```

Consequences:
- If the model writes a **single** backslash: `\textstyle` → `\t` + `extstyle` (legal; decodes to TAB), `\bigcup` → BACKSPACE, `\frac` → FORMFEED, `\nu`/`\neq`/`\nabla` → newline, `\rho`/`\rangle` → CR.
- `\ge`, `\sum`, `\alpha`… start an **illegal** escape, so the grammar masks every continuation except `"\/bfnrtu`. The model is forced into some other token, which explains substitutions like `\ge`→∂ and `\sum`→√ (likely `∂`-style escapes or dropped backslashes) [inference].
- Correct output needs the model to emit `\\textstyle`. Whether it does is a model-skill question. Qwen3 and Gemma are heavily JSON-trained, so test it in the bake-off.
- **Extra trap:** xgrammar builds `minLength`/`maxLength` strings as `[^"\\\r\n]{m,n}` (L1484–1494). Any length-constrained string **cannot contain a backslash at all**, so keep length limits off LaTeX fields.

**Grammar-level fix that Core AI allows:** xgrammar applies a string `pattern` regex to the *raw JSON text between the quotes* (L1478–1482: `"\"" + RegexToEBNF(pattern) + "\""`). A pattern can therefore allow only the escapes you want, for example (JSON-schema string, regex shown unescaped):

```
^([^"\\\x00-\x1f]|\\\\|\\")*$
```

That admits ordinary characters, `\\` and `\"` only. It makes `\t`/`\b`/`\n` impossible, so the model must write `\\textstyle`. Add `|\\n` if newlines are wanted. This works through `llm-server` `response_format` or `llm-runner --json-schema`, both of which pass raw JSON schema. Whether FM's `@Guide(pattern)`/`Regex` guide is serialized into the `GenerationSchema` JSON as `pattern` is **[unverified]**. If you keep FM, a deterministic post-repair works as a fallback: restore `\t \b \f \r` and `\n`+letter to backslash+letter. Both should be validated in the bake-off.

---

## Q3. Core AI vs Foundation Models

- **Core AI** (`import CoreAI`, macOS/iOS/visionOS… 27.0+) is the general on-device model runtime: `.aimodel` format, `AIModel`, specialization, caching, AOT compile. "For language models specifically, you can also run the model through Foundation Models." ([doc] https://developer.apple.com/documentation/coreai)
- **Foundation Models 27** adds a public `LanguageModel` protocol ("Implement this protocol to create a bridge between a model and the framework"), plus `LanguageModelExecutor` and `LanguageModelSession(model:)`, all macOS 27.0+ ([doc] https://developer.apple.com/documentation/foundationmodels/languagemodel, …/languagemodelexecutor).
- Apple article "Running a Core AI model in a Foundation Models session": "With Core AI, you can deploy AI models within your app and load them into the same language model session API you already use. Only the model you pass into `init(model:tools:instructions:)` changes." It also states the requirement: macOS 27, iOS 27, Xcode 27 ([doc] https://developer.apple.com/documentation/foundationmodels/running-a-core-ai-model-in-a-foundation-models-session).
- So the two are separate frameworks, and **yes, a Core AI model is a custom `LanguageModel`** (`CoreAILanguageModel`), with tools, guided generation (`@Generable`), streaming and reasoning routing (`Transcript.Reasoning`). Shape's existing `AIProvider` / FM code would only swap the model passed to the session.

## Q4. Shipping cost (personal Developer ID app, sandbox off)

- **Model files:** an export folder (`.aimodel` + `tokenizer/` + `metadata.json`) of about 2.3–6.6 GB for the candidates. Apple's article says to "bundle with your app" (`Bundle.main.url(forResource:)`). Any readable URL works for `CoreAILanguageModel(resourcesAt:)`, and with the sandbox off that includes `~/Library/Application Support/com.mieracle.MieracleStudy/Models/…`.
  - **Recommendation:** keep the model out of the `.app`, which is in iCloud-synced Documents during dev builds (and multi-GB bundles slow codesign/notarization). Export once and point the app at an Application Support path, with a Settings field or first-run copy/download. A self-hosted download (Background Assets, as Apple suggests for `.aimodelc`) only matters if other Macs need it.
- **Specialization:** the first load specializes the model for the device and caches it. The cache is **invalidated on every OS update** and on source-file change, and is purgeable under storage pressure unless `.persistent`. Pre-warm with `AIModel.specialize(contentsOf:)` or `model.load()`. AOT: `xcrun coreai-build compile X.aimodel --platform macOS …` → `X.<arch>.aimodelc` (needs the Metal Toolchain). Sources: [doc] …/coreai/managing-model-specialization-and-caching, …/coreai/compiling-core-ai-models-ahead-of-time.
- **Licenses:** the repo is BSD-3. Qwen3 and gpt-oss are Apache-2.0, Phi-4-mini MIT, Mistral Apache-2.0. **Gemma** uses Google's Gemma Terms with a use policy, which requires passing the terms on if redistributed. None of these block personal use. Keep the license and metadata in the exported asset (`models/README.md` warns that `save_asset` drops author/license unless re-attached).
- **Repo hygiene:** never commit exports to MieracleStudy (multi-GB). Add the models dir to `.gitignore` if it lives near the repo.

## Q5. Local readiness

- `uv` 0.11.7 at `~/.local/bin/uv`. Xcode 27.0. macOS 27.0.1. Meets "macOS and iOS 27.0+ / Xcode 27.0+" (README).
- Free disk: **43 GiB** (926 GiB volume, 96% used). Peak for Gemma 3 12B is ~24 GB download + ~7 GB output + temp, which is risky. For Qwen3-8B it is ~16 + 5 GB. Delete `~/.cache/huggingface/hub/models--*` after each export.
- Registry ran fine from the clone (`uv run coreai.model.registry …`). No weights were downloaded.
- Not checked: Metal Toolchain installed (only needed for `coreai-build` AOT), and actual export peak RAM on 16 GB [unverified]. The macOS path uses mmap'd layers, which suggests 8B/12B exports are designed to fit.

## Suggested bake-off order
1. `qwen3-8b` export → `llm-runner --json-schema` with the three Shape schemas (flashcard / short answer / 4-option MCQ), run once with and once without the LaTeX `pattern`. Measure `llm-benchmark`.
2. `qwen3-4b` (same commands) as the speed/quality control.
3. `gemma3-12b-it` only if 1–2 miss on quality, after the HF license and cache cleanup. Check spacing and backslashes for the SentencePiece/`.byteLevel` issue.
