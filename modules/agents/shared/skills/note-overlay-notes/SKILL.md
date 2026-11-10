---
name: note-overlay-notes
description: Imports Daylight's direct per-notebook PDF exports from Google Drive Note Overlay, prepares every page for verified OCR, and turns them into typed, linked Typst Zettelkasten notes with semantic SVG figures. Use for DC1 Note Overlay PDFs, Daylight notebook exports, or updating vault zettels from tablet notebooks.
compatibility: Requires Bun for the stdlib-only TypeScript extractor and Poppler (pdfinfo, pdfseparate, and pdftoppm). Drive import requires rclone-drive. Note transcription requires the PaddleOCR-VL paddle_ocr tool and visual inspection; final notes require Bash, Typst and Poppler for validation.
metadata:
  author: Luke T
---

# Note-overlay notes

Convert Daylight's per-notebook PDF exports into verified, reusable Typst zettels. The PDF is evidence, not a note to publish unchanged. Its page render is an OCR/review aid only; it is never a semantic diagram redraw.

## Fixed locations and safety

- Drive source: `remote:Note Overlay`, accessed only through `rclone-drive`.
- Vault: `~/Documents/vault`.
- Persistent raw PDF mirror, review PNGs, extractor manifest, and transcription ledgers: `~/Documents/vault/.note-overlay/`.
- Disposable OCR crops and validation renders: a unique per-run `/tmp/note-overlay.XXXXXX` directory.
- Reusable notes: `~/Documents/vault/zettels/`.
- Figures used by those notes: `~/Documents/vault/zettels/<zettel-id>/assets/`.

Treat Drive and explicit input PDFs as read-only. Never run an rclone move, sync, delete, or write operation against the source. The extractor lists Drive recursively and copies current PDFs with `rclone-drive copy --checksum`; it does not use `--immutable`, because a same-name export can change. It writes only beneath `.note-overlay/`; it never modifies input PDFs and never creates or overwrites zettels. It does not auto-delete retained raw PDFs, transcription ledgers, or zettels.

Existing books and articles remain aggregate outputs. Add links or includes to them when useful, but do not replace them with a flat import or reorganize them by notebook provenance. Every zettel owns all content assets it uses beneath its own `assets/` directory; book directories retain only aggregate entry points, shared styling, and source material. Existing Typst diagram helpers belong under `assets/diagrams/`, and existing raster images belong under `assets/images/`. New note-overlay assets use the simple `assets/diagram-NN.svg` and `assets/image-NN.png` names shown below.

## 1. Sync and extract

From this skill directory, run:

```bash
bun extract_note_overlay.ts --drive
```

This lists only the PDFs currently in `remote:Note Overlay`, copies them to the persistent raw mirror, verifies each local SHA-256 against Drive's SHA-256, and writes:

```text
.note-overlay/
  manifest.json
  raw/                              # persistent Drive PDF mirror
  review/<document-id>/page-NNN.png # page-sized OCR/visual-review input
  transcriptions/                   # verified page ledgers, written during transcription
```

To consume local PDFs without contacting Drive, pass files or directories explicitly. Directories are searched recursively:

```bash
bun extract_note_overlay.ts \
  ~/Downloads/Daylight \
  ~/Downloads/'Daily Note — November 2026.pdf'
```

Explicit local inputs always perform a full rebuild, so an intentional subset cannot retain unrelated cached documents. Use `--output <directory>` for an isolated working set, `--remote <remote>` or `--rclone <command>` for a different Drive setup, and `--dpi <number>` for review resolution. The default is 180 DPI. Changing DPI invalidates the incremental checkpoint and renders a new review set.

Drive uses the remote file `ID` as document identity, so page identity survives a Drive rename. Only the current remote listing is processed; renamed-away local raw files are not interpreted as additional documents and are never automatically deleted. Local document IDs are deterministically derived from normalized relative PDF paths. Relative paths and document IDs are validated before use in artifact paths.

For each document, `pdfinfo` supplies the page count and per-page point dimensions. `pdfseparate` supplies individual page PDFs for content hashing. If a Drive document's whole-file SHA-256 is unchanged, its previous page hashes and valid review PNGs are reused without splitting or rendering. Otherwise all pages are split, but `pdftoppm -singlefile -png -r <dpi>` renders only pages whose page-PDF hash changed or whose review PNG is missing or invalid. Temporary split and render files live in a unique `/tmp` directory and are removed afterward.

`manifest.json` uses schema `note-overlay-review/v2`. Each document records its ID, source path/title, SHA-256, size, modification time, raw path, and page count. Each page records:

- a page ID and one-based number;
- `content_sha256` for the individual page PDF and `review_sha256` for the review PNG;
- page dimensions, review path, and transcription-ledger path;
- stable base `zettel_id`: `note-overlay-<first-16-hex-of-sha256(document-ID)>-<NNN>`.

The manifest deterministically lists generated review artifacts and has no generation timestamp or transient changed flags. Writes are compare-before-write: an unchanged second run leaves manifest bytes, manifest mtime, and review artifacts unchanged. Stale files are removed only when the previous manifest declared them as generated review artifacts, and only after successful processing. A missing, invalid, or incompatible prior manifest forces a rebuild while still permitting safe cleanup of its declared review artifacts.

## 2. Review and transcribe every source page

Create one unique temporary directory for crops and later validation renders:

```bash
NOTE_OVERLAY_TMP="$(mktemp -d /tmp/note-overlay.XXXXXX)"
mkdir -p "$NOTE_OVERLAY_TMP/crops" "$NOTE_OVERLAY_TMP/validation"
```

Inspect **every** page review PNG at readable resolution, including blank-looking pages and regions between handwritten blocks. Record pages with no content instead of silently skipping them. Use a higher-DPI extraction or a lossless crop when small handwriting needs closer inspection; retain the raw PDF and persistent page review as evidence. Keep OCR and uncertain-reading crops under `$NOTE_OVERLAY_TMP/crops/`, not in final notes or the persistent extractor output.

### Transcription checkpoint and Git history

Keep the verified transcription ledger at the manifest's page-specific path:

```text
.note-overlay/transcriptions/<zettel-id>.md
```

The ledger must record the page's current `review_sha256` together with its literal transcription and unresolved-reading notes. Before OCR, compare that recorded hash with `manifest.json`:

- Matching hash plus existing integrated zettels means the page is already reviewed: skip OCR.
- Matching hash without integrated zettels means reuse the verified ledger and continue integration; do not repeat OCR merely to fill time.
- Changed or missing hash means re-review the page and ledger. Compare old and new content, then surgically merge only verified changes into existing zettels.

Git versions the manifest and ledger history and is useful for comparing prior text and hashes, but Git is **not** the runtime checkpoint. The current manifest hash and current ledger are authoritative. The extractor never writes transcription ledgers or zettels and never overwrites human note edits.

### Serial PaddleOCR and literal transcription

Use the PaddleOCR-VL `paddle_ocr` tool. Do not substitute another OCR engine.

1. OCR one full page for discovery and reading-order context.
2. Visually inspect that complete page.
3. Make one padded crop for context and one tight crop for each handwritten block, formula, table, chart, or label.
4. Run OCR on one crop at a time, serially. Never parallelize page or crop OCR.
5. Check the crop result against the pixels before accepting it. Use `formula`, `table`, `chart`, or `spotting` tasks when they fit the material.
6. Retry a failed or rate-limited OCR request serially; do not switch to bulk OCR to finish faster.

Preserve handwriting literally: spelling, capitalization, punctuation, abbreviations, symbols, emphasis, and list order. Remove visual line wrapping only when it is clearly incidental. Never correct terminology, expand shorthand, polish grammar, or replace a phrase with a plausible summary. Escape Typst metacharacters in the destination without changing the displayed wording.

If a reading remains uncertain after a tighter crop, higher-resolution render, and comparison with repeated letter forms, mark it unresolved in the ledger and show Luke the smallest useful crop. Do not integrate an unverified reading or claim literal fidelity while any imported wording remains unresolved.

## 3. Build typed atomic zettels without overwriting people

Read `manifest.json`, the hash-matched transcription ledger, and existing zettels before writing. Give each atomic idea an ordinal suffix to the manifest's stable page-derived base:

```text
zettels/note-overlay-<document-hash>-<NNN>-01/main.typ
zettels/note-overlay-<document-hash>-<NNN>-02/main.typ
```

Use visual/reading order for the initial allocation. Never renumber existing ideas after a later import; allocate the next unused ordinal. The stable ID and zettel directory do not change when a title or Drive path changes.

Each zettel represents one idea and declares its type in metadata. Use `concept`, `claim`, `procedure`, `example`, `question`, or `reference`; do not create a miscellaneous “annotation” type. A self-contained starting shape is:

```typst
#import "../../.zettypst/lib.typ": *

#show: zettel

#metadata((
  id: "note-overlay-<document-hash>-<NNN>-01",
  kind: "concept",
  source_page: "<document-id>-page-<NNN>",
  sources: ((title: "<PDF-title>", path: "<Drive-or-local-PDF-path>"),),
))

= <idea title> <note-overlay-<document-hash>-<NNN>-01>

<verified note body>
```

In actual Typst, replace `<idea title>` and `<verified note body>` with content, not angle-bracket placeholders. Attach the source-derived label to the heading as shown. Register every new `main.typ` in `.zettypst/source.toml`; notes absent from that manifest have no ZetTypst graph identity, definition navigation, or backlinks. Link related ideas with `@note-overlay-<document-hash>-<NNN>-NN` references and meaningful surrounding prose. A page with several ideas must produce several linked atomic notes, not one page-shaped summary and not repeated paragraphs in multiple notes.

Search for an existing idea by content and links before adding a duplicate. If the idea already exists, add only missing information or a meaningful source link/citation. Do not create provenance headings such as “Imported notes” or “Notebook annotations.”

**Never overwrite an existing human-edited zettel wholesale.** Open it, understand its current type and links, and make surgical additions that preserve human wording and structure. The extractor's hashes make review idempotent; they are not permission to regenerate final notes. If a source page changes, compare the new review with the hash-matched old ledger and existing zettels, then merge only verified changes.

Keep visible source citations for imported material. At minimum cite the exact PDF title and Drive or local source path in the vault's normal citation style. If a page visibly contains an external source title or URL, preserve that wording and destination exactly as an additional citation; do not invent one for bare handwriting.

## 4. Redraw diagrams semantically

Every hand-drawn or pictured diagram in a PDF page must be recreated as a clean semantic SVG under:

```text
zettels/<zettel-id>/assets/diagram-NN.svg
```

A semantic redraw has explicit nodes, connectors, grouping, arrowheads, and visible SVG `<text>` labels. Preserve literal source labels and their relationships. Give elements useful semantic identities or `data-kind` values such as `actor`, `process`, `store`, or `flow`; use consistent typography, spacing, alignment, and arrow direction. Use explicit SVG fill, stroke, and font attributes supported by Typst's SVG renderer; do not rely on theme CSS variables, external stylesheets, scripts, or linked raster fallbacks. Compare the redraw against the original PDF page and verify every label and edge.

Never wrap or trace the review PNG and call it a semantic diagram. A raster image inside an SVG wrapper is not a redraw.

Non-diagram images may remain raster. Use a lossless crop from the page PDF/review when cropping improves focus, and save it as `zettels/<zettel-id>/assets/image-NN.png`; do not use an entire page PNG as a substitute for the relevant image.

Include every final image through Typst `#figure`, with a caption and a stable label, for example:

```typst
#figure(
  image("assets/diagram-01.svg"),
  caption: [<literal or verified caption>],
) <fig:note-overlay-<document-hash>-<NNN>-01-diagram-01>
```

Use the same figure treatment for retained raster images. A diagram may not be replaced by prose merely because redrawing takes effort.

## 5. Validate source fidelity and rendered notes

Before completion:

1. Compare every imported literal passage and diagram label with the hash-matched transcription ledger and source pixels.
2. Check that multi-idea pages became linked atomic notes and that no idea was duplicated across zettels.
3. Confirm all new figures resolve beneath their zettel's `assets/` directory, all source citations are meaningful and visible, and existing human edits remain intact.
4. Run the validation helper for every affected zettel. Pass every directly referenced zettel needed to resolve its `@` links. Compile every changed aggregate entry point with its established package path and build settings.
5. Render and visually inspect the changed pages and adjacent pages. Check handwriting fidelity, text overflow, links, captions, SVG labels/arrows, raster quality, and figure placement.

From this skill directory, run:

```bash
bash validate_note_overlay.sh \
  "$HOME/Documents/vault" \
  "$HOME/Documents/vault/zettels/<zettel-id>/main.typ" \
  "$HOME/Documents/vault/zettels/<related-zettel-id>/main.typ"
```

Omit the related-zettel argument when the target has no cross-zettel references; repeat it for multiple direct references. The helper compiles the complete ZetTypst graph, builds a temporary linked document with heading numbering enabled, and renders it with Poppler. It prints a unique `/tmp/note-overlay-validate.XXXXXX` directory containing the PDF and PNGs. This resolves cross-zettel labels without changing the notes' own heading style.

For an existing book, compile its real root (usually `main.typ`) into `$NOTE_OVERLAY_TMP/validation/` with its established package path instead. Do not treat a successful compile alone as visual verification.

After every render has passed visual inspection, remove the run and validation temporary directories:

```bash
rm -r -- "$NOTE_OVERLAY_TMP" /tmp/note-overlay-validate.<suffix>
```

On failure, retain the relevant temporary directory for diagnosis and report its path. Do not leave validation PDFs or OCR crops in the vault after a successful run. Report changed zettels/assets, source pages covered, semantic redraws, citations retained, validation performed, and any unresolved readings explicitly.
