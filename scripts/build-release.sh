#!/usr/bin/env bash
# Rakit seluruh artefak rilis opencode-termux-v1 (tanpa npm):
#   1. opencode-termux-installer.sh            — bootstrap tanpa Node
#   2. opencode-termux-<v>-aarch64.tar.gz      — bundle offline arm64
#   3. opencode-termux-<v>-x86_64.tar.gz       — bundle offline x64
#   4. opencode-config.zip                     — paket config
#   5. SHA256SUMS.txt                          — checksum semua di atas
set -euo pipefail
cd "$(dirname "$0")/.."

VER=$(cat VERSION)
UPSTREAM=$(cat UPSTREAM)
OUT="${1:-dist}"
TOOLS="$OUT/.tools"
rm -rf "$OUT"; mkdir -p "$OUT" "$TOOLS"

fetch() { curl -fsSL "$1" -o "$2"; }

echo "== patchelf =="
# prefer patchelf dari PATH (apt/pkg install); fallback: Alpine + loader musl
PATCHELF_BIN=""
PATCHELF_LOADER=""
if command -v patchelf >/dev/null 2>&1; then
  PATCHELF_BIN=$(command -v patchelf)
  echo "pakai patchelf sistem: $PATCHELF_BIN"
else
  case "$(uname -m)" in
    aarch64|arm64) HOST_ALPINE_ARCH=aarch64; LOADER="prebuilt/ld-musl-aarch64-termux.so" ;;
    x86_64|amd64)  HOST_ALPINE_ARCH=x86_64; LOADER="" ;;
    *) echo "❌ arsitektur host tidak didukung"; exit 1 ;;
  esac
  if [ -z "$LOADER" ] || [ ! -f "$LOADER" ]; then
    echo "❌ patchelf tidak tersedia — install dulu: apt-get install patchelf (CI) / pkg install patchelf (Termux)"
    exit 1
  fi
  PATCHELF_APK="patchelf-0.18.0-r3.apk"
  fetch "https://dl-cdn.alpinelinux.org/alpine/v3.20/main/$HOST_ALPINE_ARCH/$PATCHELF_APK" "$TOOLS/$PATCHELF_APK"
  mkdir -p "$TOOLS/patchelf-x"
  tar xzf "$TOOLS/$PATCHELF_APK" -C "$TOOLS/patchelf-x" usr/bin/patchelf
  PATCHELF_BIN="$TOOLS/patchelf-x/usr/bin/patchelf"
  PATCHELF_LOADER="$LOADER"
  chmod +x "$PATCHELF_BIN"
  echo "pakai patchelf Alpine via loader musl"
fi
patch_elf() { # patch_elf <binary> <args...>
  if [ -n "$PATCHELF_LOADER" ]; then "$PATCHELF_LOADER" "$PATCHELF_BIN" "$@"
  else "$PATCHELF_BIN" "$@"; fi
}

echo "== bundle offline per arsitektur =="
for ARCH in arm64 x64; do
  NAME=aarch64; [ "$ARCH" = "x64" ] && NAME=x86_64
  echo "-- build $ARCH ($NAME) upstream $UPSTREAM"
  WORK="$OUT/work-$NAME"
  mkdir -p "$WORK/vendor" "$WORK/bin" "$WORK/scripts" "$WORK/config"

  # binary musl resmi dari npm registry (curl — tanpa npm)
  fetch "https://registry.npmjs.org/opencode-linux-$ARCH-musl/-/opencode-linux-$ARCH-musl-$UPSTREAM.tgz" "$WORK/oc.tgz"
  tar xzf "$WORK/oc.tgz" -C "$WORK" package/bin/opencode
  mv "$WORK/package/bin/opencode" "$WORK/vendor/opencode"

  # loader musl prebuilt Termux (arm64) / Alpine CDN (x64)
  if [ "$NAME" = "aarch64" ]; then
    cp "prebuilt/ld-musl-$NAME-termux.so" "$WORK/vendor/ld-musl.so"
  else
    fetch "https://dl-cdn.alpinelinux.org/alpine/v3.20/main/x86_64/musl-1.2.5-r3.apk" "$WORK/musl.apk"
    mkdir -p "$WORK/musl-x"
    tar xzf "$WORK/musl.apk" -C "$WORK/musl-x" lib/ld-musl-x86_64.so.1
    cp "$WORK/musl-x/lib/ld-musl-x86_64.so.1" "$WORK/vendor/ld-musl.so"
  fi

  # libgcc + libstdc++ (binary opencode musl butuh keduanya)
  fetch "https://dl-cdn.alpinelinux.org/alpine/v3.20/main/$NAME/libgcc-13.2.1_git20240309-r1.apk" "$WORK/libgcc.apk"
  fetch "https://dl-cdn.alpinelinux.org/alpine/v3.20/main/$NAME/libstdc%2B%2B-13.2.1_git20240309-r1.apk" "$WORK/libstdc.apk"
  mkdir -p "$WORK/libs-x"
  tar xzf "$WORK/libgcc.apk" -C "$WORK/libs-x" usr/lib/libgcc_s.so.1
  tar xzf "$WORK/libstdc.apk" -C "$WORK/libs-x" usr/lib/libstdc++.so.6 usr/lib/libstdc++.so.6.0.32
  cp "$WORK/libs-x/usr/lib/libgcc_s.so.1" "$WORK/vendor/libgcc_s.so.1"
  cp "$WORK/libs-x/usr/lib/libstdc++.so.6" "$WORK/vendor/libstdc++.so.6"
  cp "$WORK/libs-x/usr/lib/libstdc++.so.6.0.32" "$WORK/vendor/libstdc++.so.6.0.32"

  # RPATH → $ORIGIN (relatif — valid di lokasi instalasi mana pun).
  # PT_INTERP TIDAK diubah: wrapper memanggil binary via loader musl
  # (ld-musl.so vendor/opencode) — cara yang aman untuk opencode v1.
  patch_elf "$WORK/vendor/opencode" --set-rpath '$ORIGIN'

  # wrapper + installer + config (substitusi versi)
  sed -e "s/@VERSION@/$VER/g" -e "s/@UPSTREAM@/$UPSTREAM/g" bin/opencode-termux > "$WORK/bin/opencode-termux"
  chmod +x "$WORK/bin/opencode-termux"
  sed "s/@VERSION@/$VER/" scripts/installer.sh > "$WORK/scripts/installer.sh"
  chmod +x "$WORK/scripts/installer.sh"
  cp config/opencode.json "$WORK/config/opencode.json"
  cp LICENSE README.md "$WORK/"

  tar czf "$OUT/opencode-termux-$VER-$NAME.tar.gz" \
    --transform "s|^|opencode-termux/|" \
    -C "$WORK" vendor bin scripts config LICENSE README.md
  rm -rf "$WORK"
done

echo "== paket config =="
python3 - "$OUT/opencode-config.zip" <<'PYEOF'
import sys, zipfile, os
out = sys.argv[1]
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk("config"):
        for f in files:
            p = os.path.join(root, f)
            z.write(p, p)
PYEOF

echo "== installer universal =="
sed "s/@VERSION@/$VER/" scripts/installer.sh > "$OUT/opencode-termux-installer.sh"
chmod +x "$OUT/opencode-termux-installer.sh"

echo "== checksums =="
( cd "$OUT" && find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -exec sha256sum {} \; | sed 's|^\./||' > SHA256SUMS.txt )
rm -rf "$TOOLS"

echo "== hasil =="
ls -la "$OUT"
[ "$(ls "$OUT" | wc -l)" -eq 5 ] || { echo "❌ jumlah artefak ≠ 5"; exit 1; }
echo "✅ 5 artefak siap di $OUT/"