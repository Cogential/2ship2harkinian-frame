#!/usr/bin/env bash
# Builds a ready-to-copy 2Ship folder for your Steam Frame from the release AppImage and your own
# ROM, so the game starts straight to the title screen with no first-run ROM step.
#
#   steamframe/make-personal-bundle.sh --rom <your .z64> [--appimage <file>] [--o2r <mm.o2r>] [--out <dir>]
#
#   --rom       Your Majora's Mask ROM (NTSC-U 1.0 or NTSC-U GameCube). Required.
#   --appimage  2ship-steam-frame-arm64.appimage from the GitHub release. If omitted, the script
#               tries `gh release download` for the newest frame-v* release.
#   --o2r       A pre-built mm.o2r made from your ROM. If omitted, the game builds it on the
#               Frame the first time you launch it.
#   --out       Output folder (default: ./2ship-frame-bundle). A .tar.gz of it is written next to it.
#
# The bundle holds your personal copy of the game. Keep it on your own devices; don't upload it
# to GitHub or share it.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="Cogential/2ship2harkinian-frame"
APPIMAGE_NAME="2ship-steam-frame-arm64.appimage"
ROM="" APPIMAGE="" O2R="" OUT="$PWD/2ship-frame-bundle"

usage() { sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }
die() { echo "error: $*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rom) ROM="$2"; shift 2 ;;
        --appimage) APPIMAGE="$2"; shift 2 ;;
        --o2r) O2R="$2"; shift 2 ;;
        --out) OUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) echo "unknown option: $1" >&2; usage 1 ;;
    esac
done

[[ -n "$ROM" ]] || { echo "error: --rom is required" >&2; usage 1; }
[[ -f "$ROM" ]] || die "ROM not found: $ROM"

sha1() {
    if command -v sha1sum >/dev/null; then sha1sum "$1" | cut -d' ' -f1; else shasum -a 1 "$1" | cut -d' ' -f1; fi
}

# Only ROMs 2Ship can extract are accepted; the list lives in docs/supportedHashes.json.
ROM_SHA1="$(sha1 "$ROM")"
grep -qi "\"$ROM_SHA1\"" "$ROOT/docs/supportedHashes.json" ||
    die "ROM SHA-1 $ROM_SHA1 isn't a supported version (see docs/supportedHashes.json). A .n64/.v64 dump needs converting to .z64 first."
echo "ROM ok: $ROM_SHA1"

if [[ -z "$APPIMAGE" ]]; then
    command -v gh >/dev/null || die "pass --appimage, or install the GitHub CLI (gh) so the script can download it"
    TAG="$(gh release list -R "$REPO" --limit 50 --json tagName -q '.[].tagName' | grep '^frame-v' | head -n1)"
    [[ -n "$TAG" ]] || die "no frame-v* release found in $REPO"
    echo "Downloading $APPIMAGE_NAME from $TAG"
    TMP="$(mktemp -d)"
    trap 'rm -rf "$TMP"' EXIT
    gh release download "$TAG" -R "$REPO" -p "$APPIMAGE_NAME" -D "$TMP"
    APPIMAGE="$TMP/$APPIMAGE_NAME"
fi
[[ -f "$APPIMAGE" ]] || die "AppImage not found: $APPIMAGE"
[[ -z "$O2R" || -f "$O2R" ]] || die "mm.o2r not found: $O2R"

mkdir -p "$OUT"
cp "$APPIMAGE" "$OUT/$APPIMAGE_NAME"
chmod +x "$OUT/$APPIMAGE_NAME"
# Kept in the bundle so 2Ship can rebuild mm.o2r by itself if a future update needs a new one.
cp "$ROM" "$OUT/"
[[ -n "$O2R" ]] && cp "$O2R" "$OUT/mm.o2r"

# Launcher: keeps saves, settings and mm.o2r in this folder whatever directory Steam starts it in.
cat > "$OUT/2ship.sh" <<EOF
#!/usr/bin/env bash
DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
cd "\$DIR"
export SHIP_HOME="\$DIR"
exec "\$DIR/$APPIMAGE_NAME" "\$@"
EOF
chmod +x "$OUT/2ship.sh"

cat > "$OUT/README.txt" <<'EOF'
2 Ship 2 Harkinian for the Steam Frame (personal bundle)

1. Copy this whole folder to the Frame, e.g. to ~/Games/2ship/.
2. In Desktop Mode, add 2ship.sh to Steam with "Add a Non-Steam Game"
   (choose "All files" in the file picker to see it).
3. Launch it from your library. Press View on the controller to open the menu.

Saves, settings and logs are kept in this folder. If FUSE is missing, add
--appimage-extract-and-run to the shortcut's launch options.

This folder contains your personal copy of the game. Don't share or upload it.
EOF

TARBALL="$OUT.tar.gz"
tar -czf "$TARBALL" -C "$(dirname "$OUT")" "$(basename "$OUT")"
echo
echo "Bundle: $OUT"
echo "Archive: $TARBALL"
[[ -n "$O2R" ]] || echo "note: no --o2r given; the Frame will build mm.o2r on first launch (one time)."
