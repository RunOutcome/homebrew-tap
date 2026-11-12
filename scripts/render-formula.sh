#!/bin/sh
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 COR Holdings, LLC
#
# Renders Formula/out.rb from Formula/out.rb.tmpl (F-0017-T4).
#
#   scripts/render-formula.sh --version <v> --base-url <url> --checksums <checksums.txt> [--out <file>]
#
# --base-url is where the binaries out-<os>-<arch> are: a release's download address, or a
# file:// folder in CI. --checksums is the release's checksums.txt ("<sha256>  out-<os>-<arch>"
# lines). Every darwin and linux binary must be listed; a missing or malformed checksum is
# refused and nothing is written.
set -eu

usage() { echo "usage: render-formula.sh --version <v> --base-url <url> --checksums <file> [--out <file>]" >&2; exit 2; }
refuse() { echo "refused: $*" >&2; exit 1; }

version="" base="" sums="" out="Formula/out.rb"
while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || usage; version="$2"; shift 2 ;;
    --base-url) [ $# -ge 2 ] || usage; base="${2%/}"; shift 2 ;;
    --checksums) [ $# -ge 2 ] || usage; sums="$2"; shift 2 ;;
    --out) [ $# -ge 2 ] || usage; out="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$version" ] && [ -n "$base" ] && [ -n "$sums" ] || usage
[ -f "$sums" ] || refuse "$sums not found"
case "$version" in v*) version="${version#v}" ;; esac
case "$version" in *[!0-9A-Za-z.-]*|"") refuse "version '$version' is not a version" ;; esac

here="$(cd "$(dirname "$0")/.." && pwd)"
tmpl="$here/Formula/out.rb.tmpl"
[ -f "$tmpl" ] || refuse "$tmpl not found"

sha() {
  s="$(sed -n "s/^\([0-9a-f]\{64\}\)  out-$1\$/\1/p" "$sums" | head -n 1)"
  [ -n "$s" ] || refuse "$sums has no checksum for out-$1"
  echo "$s"
}
da="$(sha darwin-arm64)"; di="$(sha darwin-amd64)"; la="$(sha linux-arm64)"; li="$(sha linux-amd64)"

tmp="$out.new"
sed -e "s|@VERSION@|$version|g" -e "s|@BASE_URL@|$base|g" \
    -e "s|@SHA256_DARWIN_ARM64@|$da|" -e "s|@SHA256_DARWIN_AMD64@|$di|" \
    -e "s|@SHA256_LINUX_ARM64@|$la|" -e "s|@SHA256_LINUX_AMD64@|$li|" \
    -e '/^# The template for Formula\/out.rb/,/^# formula is not published/c\
# Rendered by scripts/render-formula.sh from Formula/out.rb.tmpl (F-0017-T4). Not published\
# until the founder approves the public release (F-0017 @ac-7).' \
    "$tmpl" > "$tmp"
if grep -q '@[A-Z0-9_]*@' "$tmp"; then rm -f "$tmp"; refuse "a placeholder was left in $out"; fi
mv -f "$tmp" "$out"
echo "rendered $out: out $version from $base"
