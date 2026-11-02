#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 )); then
  printf 'Usage: %s VAULT TARGET_MAIN_TYP [RELATED_MAIN_TYP ...]\n' "$0" >&2
  exit 2
fi

vault=$(realpath "$1")
target=$(realpath "$2")
shift 2

if [[ ! -f "$vault/lsp.typ" || ! -f "$vault/.zettypst/source.toml" ]]; then
  printf 'Not a ZetTypst vault: %s\n' "$vault" >&2
  exit 1
fi

require_vault_document() {
  local path=$1
  case "$path" in
    "$vault"/*) ;;
    *)
      printf 'Document is outside the vault: %s\n' "$path" >&2
      exit 1
      ;;
  esac
  if [[ ! -f "$path" ]]; then
    printf 'Document does not exist: %s\n' "$path" >&2
    exit 1
  fi
}

require_vault_document "$target"

workdir=$(mktemp -d /tmp/note-overlay-validate.XXXXXX)
note_id=$(basename "$(dirname "$target")")
wrapper="$workdir/$note_id-linked.typ"

{
  printf '#set heading(numbering: "1.")\n\n'
  for related in "$@"; do
    related=$(realpath "$related")
    require_vault_document "$related"
    printf '#include "%s"\n' "$related"
  done
  printf '#include "%s"\n' "$target"
} > "$wrapper"

typst compile --root "$vault" "$vault/lsp.typ" "$workdir/graph.pdf"
typst compile --root / "$wrapper" "$workdir/$note_id.pdf"
pdftoppm -png -r 150 "$workdir/$note_id.pdf" "$workdir/$note_id"

printf 'Validation artifacts: %s\n' "$workdir"
printf 'Inspect the rendered target and adjacent pages, then remove this directory after success.\n'
