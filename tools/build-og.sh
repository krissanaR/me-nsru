#!/usr/bin/env bash
# Regenerate site/assets/img/og-cover.jpg from tools/og-card.html.
#
#   bash tools/build-og.sh
#
# Renders the card in headless Chrome at exactly 1200x630, then encodes it to
# JPEG. Chrome is used rather than an image library because the card contains
# Thai text: ffmpeg's drawtext has no complex-script shaping and would break
# vowels and tone marks. Served over HTTP rather than file:// so the local
# woff2 fonts load without CORS trouble.
#
# Needs: node, ffmpeg, and Chrome (or Edge — see CHROME below).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/site/assets/img/og-cover.jpg"
PORT=8799

CHROME="${CHROME:-/c/Program Files/Google/Chrome/Application/chrome.exe}"
[ -x "$CHROME" ] || CHROME="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
[ -x "$CHROME" ] || { echo "no Chrome/Edge found; set CHROME=/path/to/chrome" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"; [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true' EXIT

node -e '
const http=require("http"),fs=require("fs"),path=require("path");
const T={".html":"text/html; charset=utf-8",".css":"text/css; charset=utf-8",
         ".woff2":"font/woff2",".webp":"image/webp",".jpg":"image/jpeg"};
http.createServer((q,s)=>{
  const f=path.join(process.argv[1],decodeURIComponent(q.url.split("?")[0]));
  fs.readFile(f,(e,b)=>e?s.writeHead(404).end()
    :s.writeHead(200,{"Content-Type":T[path.extname(f)]||"application/octet-stream"}).end(b));
}).listen(process.argv[2]);
' "$ROOT" "$PORT" &
SRV=$!

# Give the server a moment to bind.
for _ in $(seq 1 40); do
  node -e 'require("http").get("http://localhost:'"$PORT"'/tools/og-card.html",r=>process.exit(r.statusCode===200?0:1)).on("error",()=>process.exit(1))' \
    && break || sleep 0.1
done

"$CHROME" --headless=new --disable-gpu --hide-scrollbars \
  --force-device-scale-factor=1 --virtual-time-budget=8000 \
  --window-size=1200,630 \
  --screenshot="$TMP/og.png" \
  "http://localhost:$PORT/tools/og-card.html" >/dev/null 2>&1

[ -s "$TMP/og.png" ] || { echo "chrome produced no screenshot" >&2; exit 1; }

ffmpeg -hide_banner -loglevel error -y -i "$TMP/og.png" -q:v 3 -pix_fmt yuvj420p "$OUT"

# og:image:width / :height in index.html hard-code these — fail loudly if they drift.
probe() { ffprobe -v error -select_streams v:0 -show_entries "stream=$1" -of default=nw=1:nk=1 "$OUT"; }
W="$(probe width)"; H="$(probe height)"
[ "$W" = "1200" ] && [ "$H" = "630" ] || { echo "expected 1200x630, got ${W}x${H}" >&2; exit 1; }

echo "wrote $OUT (${W}x${H}, $(wc -c < "$OUT") bytes)"
