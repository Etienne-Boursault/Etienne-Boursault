#!/usr/bin/env bash
# Régénère les deux images de la bannière à partir de source/banniere.html, avec Chrome sans fenêtre.
#   img/banniere.png         : version claire
#   img/banniere-sombre.png  : version sombre (Chrome simule un système en thème sombre)
# Capture à l'échelle 2 (2400 × 840 pixels) pour rester nette sur les écrans haute densité.
# Si Python et Pillow sont installés, les images sont ensuite réduites à 256 couleurs (environ 50 Ko chacune).
set -euo pipefail
ici="$(cd "$(dirname "$0")/.." && pwd)"
chrome="${CHROME:-}"
if [ -z "$chrome" ]; then
  for c in "/c/Program Files/Google/Chrome/Application/chrome.exe" "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" google-chrome chromium; do
    if command -v "$c" >/dev/null 2>&1 || [ -x "$c" ]; then chrome="$c"; break; fi
  done
fi
[ -n "$chrome" ] || { echo "Chrome introuvable : indiquer son chemin dans CHROME=" >&2; exit 1; }
# Sous Windows (Git Bash), Chrome attend des chemins Windows.
chemin() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else echo "$1"; fi; }
page="$(chemin "$ici/source/banniere.html")"
for theme in clair sombre; do
  if [ "$theme" = clair ]; then sortie="$ici/img/banniere.png"; option=""; else sortie="$ici/img/banniere-sombre.png"; option="--force-dark-mode"; fi
  "$chrome" --headless --disable-gpu --hide-scrollbars $option --force-device-scale-factor=2 \
    --window-size=1200,420 --virtual-time-budget=5000 --screenshot="$(chemin "$sortie")" "file:///${page#/}" 2>/dev/null
  echo "$theme : $sortie"
done
if python -c "import PIL" 2>/dev/null; then
  python - "$(chemin "$ici/img/banniere.png")" "$(chemin "$ici/img/banniere-sombre.png")" <<'PY'
import sys
from PIL import Image
for f in sys.argv[1:]:
    Image.open(f).convert("RGB").quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).save(f, optimize=True)
PY
fi
