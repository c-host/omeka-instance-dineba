#!/usr/bin/env bash
# Build release zips for Ghent Docker OMEKA_S_MODULES / OMEKA_S_THEMES.
# Run from the parent of the module/theme repos (e.g. omeka-s/).
# Upload the resulting files to the matching GitHub Release as assets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="${ROOT}/release-zips"
mkdir -p "$OUT"

zip_module() {
  local dir="$1"
  local name="$2"
  local version="$3"
  local out="${OUT}/${name}-${version}.zip"
  rm -f "$out"
  (cd "$ROOT" && zip -r "$out" "$dir" -x "*.git*" -x "*/vendor/*" -x "*/node_modules/*")
  echo "Wrote $out"
  unzip -l "$out" | head -5
}

zip_theme() {
  local src="$1"
  local version="$2"
  local out="${OUT}/freedom-${version}.zip"
  local stage="${OUT}/.stage-freedom"
  rm -rf "$stage" "$out"
  cp -a "${ROOT}/${src}" "$stage/freedom"
  (cd "$stage" && zip -r "$out" freedom -x "*.git*" -x "*/node_modules/*")
  rm -rf "$stage"
  echo "Wrote $out"
  unzip -l "$out" | head -5
}

zip_module InternetArchiveInboundSync InternetArchiveInboundSync v1.3.0
zip_module InternetArchiveOutboundSync InternetArchiveOutboundSync v1.0.0
zip_module ContributeEnhancements ContributeEnhancements v1.3.3
zip_theme freedom-theme v1.1.3-custom.2

echo "Done. Upload each zip to the matching GitHub Release (asset name must match the URL in .env.example)."
