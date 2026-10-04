#!/usr/bin/env bash
# build_guide.sh  SRC_DIR  OUT_DIR
#
# Renders every diagram and compiles the written guide into OUT_DIR
# (normally student_package/guide).
#
#   TikZ  -> pdflatex -> PDF -> pdftocairo -> PNG      (XDSM, N2)
#   .mmd  -> mermaid-cli     -> SVG and PNG            (flowcharts, sequence)
#   MATLAB figures are expected to be in figures_matlab/ already; run
#   make_matlab_figures.m first if they are missing.
#
# Needs: pdflatex (TeX Live, with pgf/tikz), pdftocairo, and node for npx.
# Everything else degrades with a warning rather than failing the build.

set -u

SRC="${1:-$(cd "$(dirname "$0")" && pwd)}"
OUT="${2:-$SRC/../student_package/guide}"
FIG="$OUT/figures"

mkdir -p "$FIG"
echo "guide source : $SRC"
echo "guide output : $OUT"

have() { command -v "$1" >/dev/null 2>&1; }

# mermaid-cli emits  <svg width="100%" ... viewBox="x y W H">  with NO height.
# An <img> cannot size that: naturalWidth/naturalHeight come back 0 and the
# image renders at zero size, so the diagram is invisible. Replace the
# percentage width with the real pixel width and height from the viewBox.
fix_svg_size() {
  local f="$1"
  [ -f "$f" ] || return 0
  grep -q 'width="100%"' "$f" || return 0
  local vb w h
  vb=$(grep -o 'viewBox="[^"]*"' "$f" | head -1 | sed 's/viewBox="//;s/"//')
  w=$(printf '%s' "$vb" | awk '{printf "%.0f", $3}')
  h=$(printf '%s' "$vb" | awk '{printf "%.0f", $4}')
  if [ -n "$w" ] && [ -n "$h" ] && [ "$w" -gt 0 ] && [ "$h" -gt 0 ]; then
    sed -i "s|width=\"100%\"|width=\"${w}\" height=\"${h}\"|" "$f"
    echo "  fix   $(basename "$f")  -> ${w}x${h} px"
  fi
}

# ---------------------------------------------------------------- TikZ ----
if have pdflatex; then
  for f in xdsm_L1 xdsm_L2 n2_L1_L2; do
    ( cd "$SRC/tikz" && pdflatex -interaction=nonstopmode -halt-on-error "$f.tex" >/dev/null 2>&1 ) \
      && echo "  tikz  $f.pdf" || echo "  tikz  $f FAILED"
    if have pdftocairo && [ -f "$SRC/tikz/$f.pdf" ]; then
      ( cd "$SRC/tikz" && pdftocairo -png -r 200 -singlefile "$f.pdf" "$f" ) \
        && echo "  png   $f.png"
    fi
    cp -f "$SRC/tikz/$f.pdf" "$FIG/" 2>/dev/null
    cp -f "$SRC/tikz/$f.png" "$FIG/" 2>/dev/null
  done
else
  echo "  pdflatex not found - skipping the TikZ diagrams"
fi

# ------------------------------------------------------------- mermaid ----
# Re-render only when the .mmd is newer than its .svg, because mermaid-cli
# downloads a browser on a cold cache and that is slow.
if have npx; then
  for f in flow_L1 flow_L2 sequence_L2 fidelity_ladder; do
    src="$SRC/mermaid/$f.mmd"
    if [ ! -f "$SRC/mermaid/$f.svg" ] || [ "$src" -nt "$SRC/mermaid/$f.svg" ]; then
      npx -y @mermaid-js/mermaid-cli@11 -i "$src" -o "$SRC/mermaid/$f.svg" -b white -s 1 >/dev/null 2>&1 \
        && echo "  mmd   $f.svg" || echo "  mmd   $f.svg FAILED"
      npx -y @mermaid-js/mermaid-cli@11 -i "$src" -o "$SRC/mermaid/$f.png" -b white -s 3 >/dev/null 2>&1 \
        && echo "  mmd   $f.png" || echo "  mmd   $f.png FAILED"
    else
      echo "  mmd   $f up to date"
    fi
    fix_svg_size "$SRC/mermaid/$f.svg"
    cp -f "$SRC/mermaid/$f.svg" "$FIG/" 2>/dev/null
    cp -f "$SRC/mermaid/$f.png" "$FIG/" 2>/dev/null
  done
  cp -f "$SRC"/mermaid/*.mmd "$FIG/" 2>/dev/null
else
  echo "  npx not found - shipping whatever mermaid output already exists"
  cp -f "$SRC"/mermaid/*.svg "$FIG/" 2>/dev/null
  cp -f "$SRC"/mermaid/*.png "$FIG/" 2>/dev/null
  cp -f "$SRC"/mermaid/*.mmd "$FIG/" 2>/dev/null
fi

# -------------------------------------------------------- MATLAB figures ---
if [ -d "$SRC/figures_matlab" ]; then
  cp -f "$SRC"/figures_matlab/*.png "$FIG/" 2>/dev/null && echo "  matlab figures copied"
else
  echo "  figures_matlab/ missing - run make_matlab_figures.m"
fi

# ------------------------------------------------------------- the PDF ----
if have pdflatex; then
  BUILD="$SRC/.texbuild"
  rm -rf "$BUILD"; mkdir -p "$BUILD/figures"
  cp -f "$SRC/Sizing_Guide.tex" "$BUILD/"
  cp -f "$FIG"/*.png "$BUILD/figures/" 2>/dev/null
  ( cd "$BUILD" && pdflatex -interaction=nonstopmode Sizing_Guide.tex >/dev/null 2>&1 \
                && pdflatex -interaction=nonstopmode Sizing_Guide.tex >/dev/null 2>&1 )
  if [ -f "$BUILD/Sizing_Guide.pdf" ]; then
    cp -f "$BUILD/Sizing_Guide.pdf" "$OUT/"
    echo "  PDF   Sizing_Guide.pdf  ($(du -h "$OUT/Sizing_Guide.pdf" | cut -f1))"
  else
    echo "  PDF   FAILED - see $BUILD/Sizing_Guide.log"
    grep -m5 -A4 '^!' "$BUILD/Sizing_Guide.log" 2>/dev/null
  fi
fi

# --------------------------------------------------- the lab worksheet ----
if have pdflatex; then
  LABOUT="$OUT/../lab"
  mkdir -p "$LABOUT"
  BUILD2="$SRC/.texbuild2"
  rm -rf "$BUILD2"; mkdir -p "$BUILD2"
  cp -f "$SRC/LAB_worksheet.tex" "$BUILD2/"
  ( cd "$BUILD2" && pdflatex -interaction=nonstopmode LAB_worksheet.tex >/dev/null 2>&1 \
                 && pdflatex -interaction=nonstopmode LAB_worksheet.tex >/dev/null 2>&1 )
  if [ -f "$BUILD2/LAB_worksheet.pdf" ]; then
    cp -f "$BUILD2/LAB_worksheet.pdf" "$LABOUT/"
    echo "  PDF   lab/LAB_worksheet.pdf"
  else
    echo "  PDF   LAB_worksheet FAILED - see $BUILD2/LAB_worksheet.log"
  fi
fi

# ------------------------------------------------- markdown + HTML viewer --
cp -f "$SRC/Sizing_Guide.md" "$OUT/" 2>/dev/null && echo "  MD    Sizing_Guide.md"
cp -f "$SRC/diagrams.html"   "$OUT/" 2>/dev/null && echo "  HTML  diagrams.html"

echo "guide build finished"
