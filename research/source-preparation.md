# Preparing sources before Extract

Research for [#90](https://github.com/AmierD/MieracleStudy/issues/90). Machine: M2 Pro, 16 GB, macOS 27.0.1, Xcode 27.0, Keynote 14.5 and PowerPoint 16.113 installed, LibreOffice not installed, poppler `pdftoppm` installed via Homebrew.

Each fact is tagged:
- **[M]**: measured locally for this ticket.
- **[R]**: read in a primary source (linked).
- **[I]**: inferred from the two above, and not verified directly.

## Answer

Extract prepares every source as **one PDF where page N is slide N**, plus **two cached texts per page**: the PDFKit text layer and Vision OCR.
- **PPTX:** Keynote exports it to PDF through AppleScript. That needs one-time Automation consent and Keynote installed. Without Keynote, PPTX files are greyed out in Pick.
- **Speaker notes:** read straight from the PPTX XML. No Keynote is needed for this.
- **OCR:** runs on every page, in the background while the model call is in flight. It takes about 10–13 s per 60 pages on this Mac.
- **Gemini** gets the whole PDF.
- **`claude -p`** gets PDFKit-written chunks of at most 10 pages. Each chunk is read whole, so poppler isn't needed. The prompt and file names give each chunk's absolute slide range.

## Pipeline the spec can adopt

1. **Classify.** PDF goes to step 3. PPTX goes to step 2. Any other type is greyed out in Pick (decided in #78).
2. **PPTX → PDF (Keynote).** Runs only on macOS.
   1. Look up Keynote by bundle id `com.apple.iWork.Keynote` (for example `NSWorkspace.urlForApplication(withBundleIdentifier:)`). If it's missing, block the file: "Install Keynote (free) to read PowerPoint files."
   2. Launch Keynote hidden, without activating it. Then, off the main thread, call `AEDeterminePermissionToAutomateTarget(target, typeWildCard, typeWildCard, askUserIfNeeded: true)`. Explain the prompt in the UI before asking. The results:
      - `noErr`: continue.
      - `errAEEventNotPermitted` (−1743): show "Allow MieracleStudy under System Settings › Privacy & Security › Automation › Keynote" and stop.
      - `procNotFound`: Keynote isn't running yet.

      The target must already be running, and the call "may take arbitrarily long … if the user needs to be prompted" **[R: `AE.framework/Headers/AppleEvents.h`, macOS 27 SDK]**.
   3. Create an **empty destination file** first, inside an app-owned temp folder. Keynote is sandboxed, and the sender has to issue it a sandbox extension for that path. When the path didn't exist, `osascript` logged `sandbox_extension_issue_file failed … (No such file or directory)` and the export didn't finish **[M]**. Keynote's entitlements: `app-sandbox`, `files.user-selected.read-write`, no write exception covering arbitrary paths **[M: `codesign -d --entitlements`]**.
   4. Run the script by launching `/usr/bin/osascript` with `Process`. Keep it asynchronous, wrap it in `with timeout of 600 seconds`, and kill it from the app if it overruns. The script, with properties from the Keynote dictionary **[R: `sdef /Applications/Keynote.app`]**:
      ```applescript
      tell application "Keynote"
        set d to open srcFile
        export d to dstFile as PDF with properties {export style:IndividualSlides, all stages:false, skipped slides:true, slide numbers:false, date:false, PDF image quality:Better}
        close d saving no
      end tell
      ```
      Why these properties:
      - `all stages:false`: one page per slide rather than per build.
      - `skipped slides:true`: page N then always equals slide N in the original deck.
      - `IndividualSlides`: not `SlideWithNotes`. That style shrinks the slide and adds a notes area under it.
   5. Quit Keynote only if the app launched it.
3. **Open the PDF** with `PDFDocument`. Reject it if `isLocked`. Record the page count.
4. **Speaker notes (PPTX only).** Unzip `ppt/notesSlides/notesSlideN.xml` and drop the `sldNum` placeholder shape. Keep the remaining `<a:t>` text. If it isn't empty, pass it to the model as a separate block: "Speaker notes, slide N: …". Citations stay on slide text and image text, not notes.
5. **Per-page text (all PDFs), in the background:**
   1. Read `PDFPage.string`.
   2. Render the page at **2× (144 dpi)**. A 16:9 slide (960 × 540 pt) becomes 1920 × 1080 px.
   3. Run `RecognizeTextRequest` with `.accurate` and `usesLanguageCorrection = true`.
   4. Cache per file hash: the text layer, the OCR text, and the observation boxes. The boxes drive the quote highlight on the flag-review screen (#80).
6. **Send to the model.**
   - **Gemini:** the whole PDF, inline or through the Files API.
   - **`claude -p`:** decks of 10 pages or fewer are read whole. Longer decks are written by PDFKit as `slides-011-020.pdf` and so on, at most 10 pages each. The prompt states each file's first slide number and asks for **absolute** slide numbers.
7. **Check citations** (from #76). Normalise the quote, then match it against the text layer of the reported slide, then that slide's OCR text. If both miss, also try the other pages in the same chunk. A hit there means the model gave a chunk-relative number by mistake: fix the number and don't raise a flag. Otherwise flag it "citation unverified".

## Findings and recommendations

### PPTX → PDF via Keynote

| Fact | Tag |
|---|---|
| Keynote's dictionary has `export … as PDF with properties {export style (IndividualSlides / SlideWithNotes / Handouts), all stages, skipped slides, borders, slide numbers, date, include comments, PDF image quality (Good/Better/Best), password}`. Each slide has `presenter notes` (rich text, rw), `skipped`, and `slide number`. | R (sdef) |
| `NSAppleEventsUsageDescription` "is required if your app uses APIs that send Apple events". | R ([Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription)) |
| `com.apple.security.automation.apple-events` = "whether the app may prompt the user for permission to send Apple events to other apps". You add it under Hardened Runtime › Resource Access. | R ([Apple](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events), [Hardened Runtime](https://developer.apple.com/documentation/security/hardened-runtime)) |
| Notarization requires Hardened Runtime. Today's project has no `ENABLE_HARDENED_RUNTIME` and no apple-events entitlement. | R (Hardened Runtime page); M (`project.pbxproj`, `MieracleStudy.entitlements`) |
| Consequence: a notarized Developer ID build needs **both** the Info.plist key and the entitlement. Without the entitlement, a hardened app can't show the prompt and gets −1743. | I, from the two docs above plus [forum reports](https://developer.apple.com/forums/thread/108815) |
| Refused consent: every later event fails with `errAEEventNotPermitted` (−1743) until the user changes it in System Settings. `kAEDoNotPromptForUserConsent` / `errAEEventWouldRequireUserConsent` (−1744) let the app check without prompting. | R (AppleEvents.h) |
| **Unanswered consent** blocks the event until it times out. Two runs ended with −1712 after 120 s (the AppleScript default) and after 600 s. During the wait, Keynote's main thread sat idle in its event loop and an AE-framework thread waited on a semaphore under `designatedCodeRequirementsCacheQueue`. The screen was locked, so the prompt couldn't be answered. | M |
| PowerPoint (also sandboxed) can `save as PDF` through AppleScript, with the same TCC rules. | M (sdef, codesign) |
| `NSAppleScript` has no documented thread-safety guarantee, and it runs synchronously. `osascript` through `Process` keeps the UI free and can be killed. TCC charges the consent to the responsible app, not to `osascript`. | R (NSAppleScript docs say nothing on threads); I (responsibility) |

**Export time: not measured.** The Automation prompt couldn't be answered during this run. To measure it after consent:

```
touch out.pdf
osascript research/source-preparation/keynote-export.applescript in.pptx "$PWD/out.pdf"
```

Budget a cold Keynote launch plus import. Show progress and allow cancel.

**Presenter notes.** Keynote can read them (`presenter notes of every slide`). The `SlideWithNotes` export puts them into the PDF, but changes the page layout. Reading the PPTX XML gets them with no Keynote and no consent, at under 0.1 s per deck **[M]**.

What the user's 12 real course decks contain **[M]**:
- Most notes are empty.
- History decks hold only textbook page references, such as "P. 91" (16 of 24 slides in one deck).
- The two math decks have none.

**Recommendation:** read notes from XML and pass them along when they aren't empty. Don't verify citations against them. They could become "textbook p. N" metadata later.

**Equations.** The 116-slide math deck stores 51 equations as OMML inside `mc:AlternateContent` with a PNG `mc:Fallback` **[M]**. Keynote (and any non-Office renderer) will most likely draw the fallback PNG **[I]**. So equations reach the PDF as images: the model reads them from pixels, the text layer has nothing, and OCR garbles them. This matches what the MAT 305 handout showed.

**Without Keynote:**
- PowerPoint is a second scripted route, with the same consent and better OMML fidelity.
- LibreOffice `soffice --headless --convert-to pdf` needs no TCC, but it is a large third-party install and wasn't tested here.
- Quick Look and PDFKit can't convert PPTX (#72).
- XML text alone would lose image-only slides (#76).

**Recommendation:** Keynote only for now, and grey out PPTX with an install hint when Keynote is missing.

### Per-page text for citation checks

Measured on 60-page PDFs **[M]**. Timings are for the OCR call only; render and text-layer times are listed separately.

- `mat60`: the 8-page MAT 305 Ch. 3 handout, repeated 7.5 times. Letter size, with image-only definitions and formulas.
- `book60`: pages 21–80 of *Make It Stick* (A4, dense prose).

| Run | mat60 OCR / maxRSS | book60 OCR / maxRSS | Word recall vs text layer (book / mat) | Agreement with 4× (mat) |
|---|---|---|---|---|
| new API, accurate, 1× (72 dpi) | 9.3 s / 97 MB | 11.0 s / 132 MB | 0.964 / 0.904 | 0.934 |
| 1.5× | 10.1 s / 105 MB | 12.7 s / 133 MB | 0.964 / 0.942 | 0.986 |
| **2× (144 dpi)** | **10.9 s / 114 MB** | **12.8 s / 137 MB** | **0.963 / 0.947** | **0.989** |
| 3× | 9.5 s / 134 MB | 13.0 s / 161 MB | 0.964 / 0.943 | 0.984 |
| 4× | 9.8 s / 163 MB | 13.0 s / 189 MB | 0.964 / 0.944 | 1.000 |
| legacy `VNRecognizeTextRequest`, accurate, 2× | 7.8 s / **594 MB** | 9.9 s / **618 MB** | 0.964 / 0.942 | 0.976 |
| new API, `.fast`, 2× | 1.7 s | 2.2 s | **0, no text returned** | – |

Other measurements **[M]**:
- `PDFPage.string` for 60 pages: 0.07–0.10 s.
- Rendering 60 pages at 2×: 0.09–0.15 s.
- The **first-ever** OCR call took **41.9 s for 8 pages**. Every later run was about 0.18 s per page. Treat that as a one-time model warm-up.
- The legacy loop's 600 MB is probably autoreleased images piling up in a loop without an `autoreleasepool`. The new Swift API stayed under 200 MB. `RecognizeTextRequest` needs macOS 15 or later **[R]**.

**Render scale: 2×.** At 1× the handout loses about 4–5 points of recall. Above 1.5× the results level off, while memory keeps rising.

**OCR runs always, not only on pages with little text.**
- On the handout, page 1 has the longest text layer (968 chars), yet **28 %** of its OCR words are missing from that layer.
- Page 6 (349 chars) is missing **53 %**.

A character-count threshold would skip exactly the image-sourced definitions that broke text-only checks in #76. A full deck costs about 10–13 s of background work, which overlaps the 14–82 s model call.

**2-D math.** Page 6 shows both failures **[M]**:
- The text layer garbles the formula fonts: `0(1) = {`, `7897:ℎ7<7`.
- OCR recovers the definition prose, but writes integrals as `Ix`, `Sa`, `[o` and splits piecewise functions.

Formula quotes will still be flagged. That is the accept-by-default behaviour from #76. #101 owns any smarter routing.

### Page images and chunks for `claude -p`

| Fact | Tag |
|---|---|
| Claude Code Read: "reads short `.pdf` files whole. For PDFs longer than 10 pages, it reads in ranges with a `pages` parameter … up to 20 pages at a time. Page-range reads render pages with `pdftoppm` from poppler-utils … Without it, a page-range read fails." | R ([Claude Code tools reference](https://code.claude.com/docs/en/tools-reference), CLI 2.1.288) |
| Read downsizes large images, and re-encodes any over 500 KB as JPEG. | R (same page) |
| Claude API: at most 32 MB per request, 600 pages (100 when the context window is under 1M). Each page goes in as text plus an image, at about 1,500–3,000 text tokens per page plus image tokens. This only matters if a raw-API adapter is ever added. | R ([PDF support](https://platform.claude.com/docs/en/build-with-claude/pdf-support)) |
| PDFKit wrote a 20-page subset in 24 ms. Page labels restart at "1" in the subset, so embedded labels can't carry absolute numbers. | M |
| Gemini: "PDF files up to 50MB or 1000 pages". Several PDFs per request are allowed. Native text is free. Gemini 3 bills 560 tokens per page at the default resolution, and quality "typically saturates at `medium`". Use the Files API when the request is over 100 MB. Non-PDF types are read as plain text only. | R ([document processing](https://ai.google.dev/gemini-api/docs/document-processing), [media resolution](https://ai.google.dev/gemini-api/docs/media-resolution), [Files API](https://ai.google.dev/gemini-api/docs/files)) |

Ways to split a long deck for `claude -p`:
- **10-page PDF chunks (recommended).** Each chunk is read whole, so there is no poppler dependency and the model keeps the text layer and the page image. Numbering risk: the model may report the page number within its chunk. Mitigate with absolute ranges in the file name and prompt, plus the off-by-chunk-offset fallback in step 7.
- **`pages` ranges on the full PDF.** Numbering stays the original's, but it needs poppler, which a stock Mac lacks. Don't use it.
- **One PNG per slide (`slide-023.png`).** The number is unambiguous, but the text layer is lost, it takes one Read per image, and Claude Code may downscale the images. Keep it only for scanned PDFs that have no text layer.

**Gemini** needs no splitting: sixty slides is about 34k tokens. The one size risk is an image-heavy Keynote export over 50 MB. That's why the pipeline uses `PDF image quality: Better` and checks the size before sending **[I]**.

## Open risks

1. **Keynote export is untested end to end.** Export time, the `skipped slides`/`Better` output, fidelity (font substitution, OMML fallback images, embedded video) and Keynote's first-launch dialogs all still need one run after consent. Use `research/source-preparation/keynote-export.applescript`.
2. **The consent prompt can block indefinitely.** A locked screen, or a user who ignores it, leaves the export hanging until the AE timeout. Pre-flight with `AEDeterminePermissionToAutomateTarget` from the Intake window while the user is present, never in a background job.
3. **Hardened runtime / notarization.** If the build is ever notarized, the apple-events entitlement and the usage string must ship together. Otherwise PPTX import fails silently with −1743.
4. **Sandbox handoff.** Keynote writes only where the sender's event grants an extension. Pre-creating the file avoided the logged error, but whether every path works (for example the app's Caches folder) needs confirming.
5. **New Vision API quirks on macOS 27:** `.fast` returned nothing, and the first call took about 40 s. Warm OCR up when the Intake window opens.
6. **Model reports chunk-relative slide numbers.** This is handled by the fallback search, but it should be confirmed on a deck longer than 10 pages in the Claude fallback path.
7. **Benchmark deck shape.** No 60-slide 16:9 deck was OCR'd, because the PPTX couldn't be converted. Slides have less text per page than the letter and A4 pages measured, so timings should be at or below these.

## Evidence

- `research/source-preparation/ocrbench.swift`: render-and-OCR benchmark. Build with `swiftc -O -o ~/Library/Caches/source-prep-bench/ocrbench`, then run `ocrbench <pdf> <pages> <scale> <new|legacy> [accurate|fast]`.
- `research/source-preparation/compare-ocr.py`: computes word recall against the text layer, and agreement between scales.
- `research/source-preparation/keynote-export.applescript`: the export script described above.
- The sample decks (the user's course files in `~/Downloads`) and their OCR outputs aren't committed.
