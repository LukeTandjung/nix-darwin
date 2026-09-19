#!/usr/bin/env bash
# Run from a delta-nix-linux checkout. Read the token only at runtime.
set +x
set -euo pipefail

token_file="$HOME/secrets/github-token"
if [[ ! -s "$token_file" ]]; then
  echo "Missing token: $token_file" >&2
  exit 1
fi
if [[ ! -f releases.json ]]; then
  echo "Run this command from your delta-nix-linux checkout." >&2
  exit 1
fi
export GH_TOKEN
GH_TOKEN="$(< "$token_file")"
# The upstream helper gives GITHUB_TOKEN precedence over GH_TOKEN.
export GITHUB_TOKEN="$GH_TOKEN"
if [[ $# -eq 0 ]]; then
  set -- trunk
fi
exec nix run .#update -- "$@"
