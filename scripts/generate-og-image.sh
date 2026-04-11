#!/usr/bin/env bash
#
# Regenerate assets/og-default.png — the default Open Graph card
# served as the social thumbnail for any page/post that doesn't
# override `image:` in its front matter.
#
# Run manually whenever the design changes:
#
#   bash scripts/generate-og-image.sh
#
# Requires: ImageMagick 7+ (`magick`) built with the pangocairo
# delegate (check with `magick -list format | grep -i pango`).
#
# Note: This machine's ImageMagick was compiled without FreeType,
# so the usual `-font file.ttf + -annotate` path silently produces
# a blank image. We use `pango:` (pangocairo) instead.

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$REPO_ROOT/assets/og-default.png"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

CANVAS_W=1200
CANVAS_H=630
GAP=20

# Render title and subtitle to their own transparent PNGs, then
# measure natural dimensions and composite with explicit offsets.
# Doing it this way sidesteps pango's lack of per-line alignment
# and ImageMagick's gravity/geometry interaction quirks.
magick -background none pango:'<span font_family="Noto Sans" font_weight="bold" font_size="80000" foreground="#111111">Connor Frank&apos;s Blog</span>' "$TMP/title.png"
magick -background none pango:'<span font_family="Noto Sans" font_size="36000" foreground="#555555">conjfrnk.github.io</span>' "$TMP/sub.png"

TW=$(identify -format '%w' "$TMP/title.png")
TH=$(identify -format '%h' "$TMP/title.png")
SW=$(identify -format '%w' "$TMP/sub.png")
SH=$(identify -format '%h' "$TMP/sub.png")

BLOCK_H=$(( TH + GAP + SH ))
BLOCK_TOP=$(( (CANVAS_H - BLOCK_H) / 2 ))
TITLE_X=$(( (CANVAS_W - TW) / 2 ))
TITLE_Y=$BLOCK_TOP
SUB_X=$(( (CANVAS_W - SW) / 2 ))
SUB_Y=$(( BLOCK_TOP + TH + GAP ))

magick -size "${CANVAS_W}x${CANVAS_H}" xc:white \
  "$TMP/title.png" -geometry "+${TITLE_X}+${TITLE_Y}" -composite \
  "$TMP/sub.png"   -geometry "+${SUB_X}+${SUB_Y}"     -composite \
  "$OUT"

echo "wrote $OUT"
identify "$OUT"
