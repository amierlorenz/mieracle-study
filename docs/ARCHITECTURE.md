# Architecture Overview

MieracleStudy is a SwiftUI multiplatform app (macOS primary, iPhone secondary). The app target contains only screens and wiring; everything else lives in the local `MieracleKit` package so it can be tested with `swift test`.

## High-Level Data Flow

```
 Slides / docs / notes
          │  external AI agent (study-import skill, generator prompt)
          ▼
   import JSON (schema v1) ──► mieracle-validate (CLI, same validator as the app)
          │
          ▼
 ┌──────────────┐  upsert by externalID  ┌────────────────────────────┐
 │   Importer   │ ─────────────────────► │ SwiftData store            │ ◄──► CloudKit private DB
 └──────────────┘                        │ Course→Unit→Concept→Prompt │      (Mac ⇄ iPhone)
                                         │ ReviewLog, Exam, ...       │
 Canvas API ──► CanvasSync ──► Exam ───► └─────────────┬──────────────┘
                                                       │ candidates
 VariantGenerator (Foundation Models) ──► variants ────┤
                                                       ▼
                                        SessionBuilder (scope, mode, order)
                                                       │ queue
                                                       ▼
                                        SessionEngine ──► grading (self / AI / tests / Big-O)
                                                       │
                                                       ▼
                                        Scheduler (SM-2) + exam cap ──► ReviewLog, next due
```

## Subsystem Details

### Models (`MieracleKit/Models`)
SwiftData `@Model` types mirrored to the CloudKit private database. Knowledge is organized as Class → Unit → Concept → Prompt, and the **concept** is the unit of scheduling. Prompt payloads are Codable structs stored as JSON data and exposed through a `PromptContent` enum. All models follow CloudKit's constraints: no unique attributes, defaults on every property, optional relationships, additive-only changes.

### Scheduling (`MieracleKit/Scheduling`)
A `Scheduler` protocol maps a value-type schedule state and a grade to a new state. `SM2Scheduler` implements Anki-flavored SM-2. Two rules wrap it: practice-mode successes on concepts that aren't due leave the schedule unchanged, and concepts covered by an upcoming exam have their interval capped at half the days remaining. Every answer is logged so a future FSRS scheduler can be fitted to real history.

### Sessions (`MieracleKit/Sessions`)
`SessionBuilder` is a pure function from candidate concepts and a `SessionConfig` (scope, mode, length, order, prompt kinds) to an ordered queue. Interleaved order avoids consecutive items from the same unit; prompts rotate by least recently shown. `SessionEngine` runs the queue, records reviews, requeues failed items once, and produces a summary of missed concepts.

### Import (`MieracleKit/Import`)
Decode → validate → plan → apply. The plan reports new and updated items before anything is written; apply upserts by stable `externalID`, preserving review history and never deleting. The exporter writes the same schema for backups. `GeneratorPrompt` builds the copyable instructions for an external AI, and the `mieracle-validate` CLI lets that agent check its output with the app's own validator.

### AI (`MieracleKit/AI`)
An `AIProvider` protocol isolates model access. The MVP provider uses on-device Foundation Models with `@Generable` outputs to suggest short-answer grades and to reword questions. `VariantGenerator` runs on the Mac only, keeps at most three variants per concept, and copies answers verbatim so a reworded question can't change what's correct. Every AI path has a non-AI fallback.

### Coding (`MieracleKit/Coding`)
A `CodeRunner` protocol with a macOS `PythonRunner` that writes the user's solution and a bundled harness to a temporary directory, runs `python3` with a timeout, and returns per-test results. `BigONormalizer` grades complexity answers by normalized equivalence. Coding practice is split into separate prompt kinds — implement, complexity, pattern pick — so each skill can be interleaved on its own.

### Canvas (`MieracleKit/Canvas`)
`CanvasClient` reads courses, assignments, and calendar events with a bearer token from the Keychain. `CanvasSync` runs at most daily, upserts items, and refreshes the dates of exams linked to them while keeping the user's exam-to-unit mappings.

### Rendering (`MieracleKit/Rendering`)
`RichTextView` uses SwiftUI's `WebView` with a `WebPage` that loads a bundled template over a private `mieracle:` URL scheme. The template's script pulls math out before Markdown parsing (so code spans and underscores survive), renders with marked.js, KaTeX, and highlight.js, and returns the content height, which the view uses as its frame height. A content security policy limits scripts to the bundled files, and clicked links open in the default browser.

### App (`MieracleStudy/`)
Minimal stock SwiftUI: a sidebar with Dashboard, Study, Library, Exams, Import, and Settings.

## Key Design Decisions

- **Concept-centric scheduling** so varied prompts test the idea instead of one phrasing (*Make It Stick*: variation).
- **SM-2 behind a protocol, full review logs** so FSRS can replace it without migration.
- **Heavy content generation happens outside the app** (Claude with the study-import skill); the on-device model only rewords and grades.
- **CloudKit from the first milestone** so model constraints are respected from day one.
- **macOS App Sandbox off** to run `python3`; the Mac app is distributed with Developer ID only.
- **One web-based renderer** instead of separate native Markdown, LaTeX, and highlighting libraries.
- **Secrets only in the Keychain**, with a gitleaks pre-commit hook, so the repository stays public-safe.
