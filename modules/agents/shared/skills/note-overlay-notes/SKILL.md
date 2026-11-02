---
name: note-overlay-notes
description: Imports note-overlay v2 JSON backups from Google Drive Documents/raw, prepares handwriting and embedded images for verified OCR, and turns them into typed, linked Typst Zettelkasten notes with semantic SVG figures. Use for DC1 note-overlay backups, note-overlay JSON extraction, or updating vault zettels from tablet notebooks.
compatibility: Requires Bun for the stdlib-only TypeScript extractor. Drive import requires rclone-drive; PNG review requires ImageMagick or another SVG renderer. Note transcription requires the PaddleOCR-VL paddle_ocr tool and visual inspection; final notes require Bash, Typst and Poppler for validation.
metadata:
  author: Luke T
---

# Note-overlay notes

Convert the latest note-overlay notebook states into verified, reusable Typst zettels. The backup is evidence, not a note to publish unchanged. Raw stroke SVG is an OCR/review aid only; it is never a semantic diagram redraw.

## Fixed locations and safety

- Drive source: `remote:Documents/raw`, accessed only through `rclone-drive`.
- Vault: `~/Documents/vault`.
- Persistent extractor outputs and transcription ledgers: `~/Documents/vault/.note-overlay/`.
- Disposable review PNGs, OCR crops, and validation renders: a unique per-run `/tmp/note-overlay.XXXXXX` directory.
- Reusable notes: `~/Documents/vault/zettels/`.
- Figures used by those notes: `~/Documents/vault/zettels/<zettel-id>/assets/`.

Treat Drive and explicit input backups as read-only. Never run an rclone move, sync, delete, or write operation against the source. The extractor uses `rclone-drive copy --immutable` into the local raw mirror. It writes only beneath `.note-overlay/`; it never creates or overwrites zettels.

Existing books and articles remain aggregate outputs. Add links or includes to them when useful, but do not replace them with a flat import or reorganize them by notebook provenance. Every zettel owns all content assets it uses beneath its own `assets/` directory; book directories retain only aggregate entry points, shared styling, and source material. Existing Typst diagram helpers belong under `assets/diagrams/`, and existing raster images belong under `assets/images/`. New note-overlay SVGs and retained embeds use the simple `assets/diagram-NN.svg` and `assets/image-NN.webp` names shown below.

## 1. Sync and extract

From this skill directory, run:

```bash
bun extract_note_overlay.ts --drive
```

This copies `note-overlay-backup-*.json` from `remote:Documents/raw` to `.note-overlay/raw/`, then writes:

```text
.note-overlay/
  manifest.json
  raw/                         # Drive mirror only
  review/<notebook-id>/
    <page-id>.svg              # page-sized OCR/PNG-review input
    assets/<page-id>-NN-<hash>.webp
```

To consume local backups without contacting Drive, pass files or directories explicitly:

```bash
bun extract_note_overlay.ts \
  ~/Downloads/note-overlay-backup-20261101-123339-10.json \
  ~/Downloads/note-overlay-backup-20261101-124413-11.json
```

Use `--output <directory>` for an isolated working set and `--width`/`--height` when a different review canvas is needed. The default canvas is 1000 × 1414 px. Coordinates and image bounds in v2 are normalized to that canvas.

Selection is **per stable notebook ID**, not merely the newest whole backup. For every notebook, the extractor selects the state with the greatest book `m`; equal `m` values are resolved by the lexicographically greatest backup filename. Thus an older backup can still supply a notebook absent from newer exports, while duplicate exports resolve deterministically. With the two sample names above and equal notebook `m` values, `note-overlay-backup-20261101-124413-11.json` wins the tie.

The extractor validates `app == "note-overlay"` and `v == 2`. It decodes:

- pages and stable notebook/page IDs;
- stroke `p` arrays as `(x, y, pressure)` triples;
- stroke `t0` start milliseconds, `dur` duration, `w` width, and `k` kind;
- each `i` embed's Base64 WebP bytes, normalized bounds, and `su`/`st`/`sp` source metadata.

`manifest.json` records raw backup SHA-256 hashes, canonical notebook/page content hashes, selected-backup provenance, decoded points and timings, image hashes and citations, stable zettel base IDs, and every generated artifact. It intentionally has no generation timestamp. Writes are content-addressed or compare-before-write, so an unchanged rerun leaves output bytes and modification times untouched. Stale files are removed only when they were declared as generated review artifacts by the previous manifest.

## 2. Render and verify every source page

Create one unique temporary directory for this run and use its printed path in later commands:

```bash
NOTE_OVERLAY_TMP="$(mktemp -d /tmp/note-overlay.XXXXXX)"
mkdir -p "$NOTE_OVERLAY_TMP/review" "$NOTE_OVERLAY_TMP/crops"
```

Convert each non-empty page SVG to a temporary PNG for visual review:

```bash
magick -background white \
  .note-overlay/review/<notebook-id>/<page-id>.svg \
  "$NOTE_OVERLAY_TMP/review/<page-id>.png"
```

ImageMagick can omit linked WebP images from SVG. After the base render, composite every embed explicitly, using its manifest bounds multiplied by the canvas size. For each image, run:

```bash
magick "$NOTE_OVERLAY_TMP/review/<page-id>.png" \
  \( .note-overlay/review/<notebook-id>/assets/<image>.webp \
     -resize '<width>x<height>!' \) \
  -geometry '+<x>+<y>' -composite \
  "$NOTE_OVERLAY_TMP/review/<page-id>.png"
```

Increase the raster size for small handwriting, but retain the original SVG and WebP as evidence. Inspect every non-empty page at readable resolution, including the regions between strokes and every original embedded WebP; confirm the embeds are visible in the review PNG. Record pages with no content instead of silently skipping them. Keep the verified transcription ledger at `.note-overlay/transcriptions/<page-id>.md`. Keep OCR and uncertain-reading crops under `$NOTE_OVERLAY_TMP/crops/`, not in final notes or the persistent extractor output.

### Serial PaddleOCR and literal transcription

Use the PaddleOCR-VL `paddle_ocr` tool. Do not substitute another OCR engine.

1. OCR one full page for discovery and reading-order context.
2. Visually inspect that page and its original WebP embeds.
3. Make one padded crop for context and one tight crop for each handwritten block, formula, table, or label.
4. Run OCR on one crop at a time, serially. Never parallelize page or crop OCR.
5. Check the crop result against the pixels before accepting it. Use `formula`, `table`, `chart`, or `spotting` tasks when they fit the material.
6. Retry a failed or rate-limited OCR request serially; do not switch to bulk OCR to finish faster.

Preserve handwriting literally: spelling, capitalization, punctuation, abbreviations, symbols, emphasis, and list order. Remove visual line wrapping only when it is clearly incidental. Never correct terminology, expand shorthand, polish grammar, or replace a phrase with a plausible summary. Escape Typst metacharacters in the destination without changing the displayed wording.

If a reading remains uncertain after a tighter crop, higher-resolution render, and comparison with repeated letter forms, mark it unresolved and show Luke the smallest useful crop. Do not integrate an unverified reading or claim literal fidelity while any imported wording remains unresolved.

## 3. Build typed atomic zettels without overwriting people

Read `manifest.json` and inspect existing zettels before writing. The manifest's `zettel_id` is the stable page-derived base `note-overlay-<page-id>`. Give each atomic idea an ordinal suffix:

```text
zettels/note-overlay-<page-id>-01/main.typ
zettels/note-overlay-<page-id>-02/main.typ
```

Use visual/reading order for the initial allocation. Never renumber existing ideas after a later import; allocate the next unused ordinal. The stable ID and zettel directory do not change when a title changes.

Each zettel represents one idea and declares its type in metadata. Use `concept`, `claim`, `procedure`, `example`, `question`, or `reference`; do not create a miscellaneous “annotation” type. A self-contained starting shape is:

```typst
#import "../../.zettypst/lib.typ": *

#show: zettel

#metadata((
  id: "note-overlay-<page-id>-01",
  kind: "concept",
  source_page: "<page-id>",
  sources: ((title: "<source-title>", url: "<source-url>"),),
))

= <idea title> <note-overlay-<page-id>-01>

<verified note body>
```

In actual Typst, replace `<idea title>` and `<verified note body>` with content, not angle-bracket placeholders. Attach the source-derived label to the heading as shown. Register every new `main.typ` in `.zettypst/source.toml`; notes absent from that manifest have no ZetTypst graph identity, definition navigation, or backlinks. Link related ideas with `@note-overlay-<page-id>-NN` references and meaningful surrounding prose. A page with several ideas must produce several linked atomic notes, not one page-shaped summary and not repeated paragraphs in multiple notes.

Search for an existing idea by content and links before adding a duplicate. If the idea already exists, add only missing information or a meaningful source link/citation. Do not create provenance headings such as “Imported notes” or “Notebook annotations.”

**Never overwrite an existing human-edited zettel wholesale.** Open it, understand its current type and links, and make surgical additions that preserve human wording and structure. The extractor's hashes make review idempotent; they are not permission to regenerate final notes. If a source page changes, compare the new review artifacts with the existing zettels and merge only verified changes.

Preserve each meaningful embed's source URL `su` and title `st` as a citation, using the vault's normal citation style or a Typst footnote/link. Keep the values exact in metadata even if the visible citation uses a shorter established style. Do not invent citations for bare handwriting, and do not discard source context for an embedded screenshot or diagram.

## 4. Redraw diagrams semantically

Every hand-drawn diagram **and every embedded image that is a diagram** must be recreated as a clean semantic SVG under:

```text
zettels/<zettel-id>/assets/diagram-NN.svg
```

A semantic redraw has explicit nodes, connectors, grouping, arrowheads, and visible SVG `<text>` labels. Preserve literal source labels and their relationships. Give elements useful semantic identities or `data-kind` values such as `actor`, `process`, `store`, or `flow`; use consistent typography, spacing, alignment, and arrow direction. Use explicit SVG fill, stroke, and font attributes supported by Typst's SVG renderer; do not rely on theme CSS variables, external stylesheets, scripts, or linked raster fallbacks. Compare the redraw against the original page/embed and verify every label and edge.

Never rename or restyle the extractor's raw stroke SVG and call it a semantic diagram. Tracing handwriting into paths is still raw stroke vectorization. Likewise, an embedded screenshot passed through an SVG wrapper is not a redraw.

Non-diagram images may remain raster. Copy the original WebP (or a lossless review crop when cropping improves focus) to `zettels/<zettel-id>/assets/image-NN.webp`; do not use the generated page PNG as a substitute for the original embed.

Include every final image through Typst `#figure`, with a caption and a stable label, for example:

```typst
#figure(
  image("assets/diagram-01.svg"),
  caption: [<literal or verified caption>],
) <fig:note-overlay-<page-id>-01-diagram-01>
```

Use the same figure treatment for retained raster images. A diagram may not be replaced by prose merely because redrawing takes effort.

## 5. Validate source fidelity and rendered notes

Before completion:

1. Compare every imported literal passage and diagram label with the verified transcription ledger and source pixels.
2. Check that multi-idea pages became linked atomic notes and that no idea was duplicated across zettels.
3. Confirm all new figures resolve beneath their zettel's `assets/` directory, all source citations are meaningful, and existing human edits remain intact.
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

On failure, retain the relevant temporary directory for diagnosis and report its path. Do not leave validation PDFs, review PNGs, or OCR crops in the vault after a successful run. Report changed zettels/assets, source pages covered, semantic redraws, citations retained, validation performed, and any unresolved readings explicitly.
