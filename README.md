# MieracleStudy

A personal study app for macOS and iPhone built on the research in *Make It Stick* (Brown, Roediger, McDaniel). It combines spaced-repetition flashcards, varied quizzes, and a graded coding environment for interview prep, with content synced through iCloud.

The goal is to spend almost no time making study material and almost all of it retrieving. Notes and slides are turned into structured JSON by an external AI agent, imported, and studied in sessions the app builds.

## Features

- **Concept-centric content:** Class → Unit → Concept → Prompts. Each concept is scheduled once; its prompts (flashcard, short answer, multiple choice, coding) rotate so you learn the idea, not the wording.
- **Spaced repetition:** SM-2 with Again / Hard / Good / Easy, capped so everything on an upcoming exam gets reviewed before it.
- **Interleaved, configurable sessions:** choose classes, units, and tags; review due items, practice anything, or learn new concepts; set length and order.
- **JSON import:** full concepts with prompts, updated in place by stable ids. A built-in generator prompt and a Claude Code skill produce valid files from slides and documents.
- **On-device AI:** Foundation Models suggests short-answer grades and rewords questions into variants.
- **Coding practice (Mac):** write Python solutions graded against test cases, analyze Big-O, and pick the right pattern — practiced separately and interleaved.
- **Canvas sync:** exam dates refresh daily; you map exams to units.
- **Rich content:** Markdown, LaTeX, and highlighted code everywhere.

## Requirements

- Xcode 27, macOS 27 / iOS 27
- Apple Developer Program membership (CloudKit)
- `python3` on the Mac for coding problems
- [`gitleaks`](https://github.com/gitleaks/gitleaks) for the pre-commit hook

## Setup

```sh
git clone https://github.com/AmierD/MieracleStudy.git
cd MieracleStudy
brew install gitleaks
git config core.hooksPath .githooks
open MieracleStudy.xcodeproj
```

Set your team under *Signing & Capabilities*. The app uses the CloudKit container `iCloud.com.mieracle.MieracleStudy`.

Run the package tests with the build directory outside iCloud-synced folders (codesigning rejects the metadata iCloud adds):

```sh
cd MieracleKit
swift test --scratch-path ~/Library/Caches/MieracleKit-build
```

## Project layout

| Path | Contents |
|---|---|
| `MieracleStudy/` | SwiftUI app target: screens and app wiring |
| `MieracleKit/` | Local Swift package: models, scheduling, sessions, import, AI, coding, Canvas, rendering |
| `Schema/` | JSON Schema for import files |
| `.claude/skills/study-import/` | Claude Code skill that turns slides and docs into import JSON |
| `docs/ARCHITECTURE.md` | How the pieces fit together |

## Secrets

No keys live in this repository. The Canvas token (and any future API key) is entered in Settings and stored only in the Keychain. The pre-commit hook scans staged changes with gitleaks.
