#!/bin/sh
# Test suite opencode-termux-v1 — tanpa dependensi eksternal (sh murni).
# Struktur + sintaks + unit + (opsional) E2E: OCX_E2E=1 sh test/run.sh
set -eu
cd "$(dirname "$0")/.."

E2E=0
[ "${OCX_E2E:-0}" = "1" ] && E2E=1

pass=0; fail=0
t() { # t <nama> <cmd...>
  name=$1; shift
  if "$@" >/dev/null 2>&1; then echo "✅ $name"; pass=$((pass+1))
  else echo "❌ $name"; fail=$((fail+1)); fi
}

# ===== 1. struktur =====
t "VERSION ada" test -f VERSION
t "UPSTREAM ada" test -f UPSTREAM
t "wrapper ada" test -f bin/opencode-termux
t "installer ada" test -f scripts/installer.sh
t "build-release ada" test -f scripts/build-release.sh
t "prebuilt loader ada" test -f prebuilt/ld-musl-aarch64-termux.so
t "config ada" test -f config/opencode.json
t "README ada" test -f README.md
t "LICENSE MIT" sh -c 'grep -q "MIT License" LICENSE'
t "docs INSTALASI ada" test -f docs/INSTALASI.md

# ===== 2. versi semver =====
t "VERSION semver" sh -c 'grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$" VERSION'
t "UPSTREAM semver" sh -c 'grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$" UPSTREAM'
t "VERSION = UPSTREAM beda (paket vs upstream)" sh -c 'test "$(cat VERSION)" != "$(cat UPSTREAM)"'

# ===== 3. sintaks =====
t "sintaks installer" sh -n scripts/installer.sh
t "sintaks wrapper" sh -n bin/opencode-termux
t "sintaks build-release" bash -n scripts/build-release.sh
t "sintaks test" sh -n test/run.sh

# ===== 4. prebuilt loader =====
t "prebuilt ELF aarch64" sh -c 'head -c4 prebuilt/ld-musl-aarch64-termux.so | grep -q ELF'
t "prebuilt executable" test -x prebuilt/ld-musl-aarch64-termux.so

# ===== 5. config =====
t "config model ada" sh -c 'grep -q "\"model\"" config/opencode.json'

# ===== 6. git hygiene =====
t "vendor tidak di-track" sh -c '! git ls-files 2>/dev/null | grep -q "^vendor/"'
t "dist tidak di-track" sh -c '! git ls-files 2>/dev/null | grep -q "^dist/"'
t "tarball tidak di-track" sh -c '! git ls-files 2>/dev/null | grep -qE "\.(tgz|tar\.gz|zip)$"'

# ===== 7. E2E opsional (OCX_E2E=1) =====
if [ "$E2E" = 1 ]; then
  echo ""
  echo "🔧 mode E2E: build bundle + install ke lokasi uji + smoke test…"
  ARCH_NAME=aarch64
  [ "$(uname -m)" = "x86_64" ] && ARCH_NAME=x86_64
  t "build-release: 5 artefak" sh -c 'bash scripts/build-release.sh dist-e2e >/dev/null 2>&1 && test "$(ls dist-e2e | wc -l)" -eq 5'
  t "installer: install ke lokasi uji + smoke" sh -c '
    rm -rf .e2e-prefix && mkdir -p .e2e-prefix
    OCX_LIBDIR="$(pwd)/.e2e-prefix/lib" OCX_BINDIR="$(pwd)/.e2e-prefix/bin" \
      sh dist-e2e/opencode-termux-installer.sh >/dev/null 2>&1
    test -x .e2e-prefix/bin/opencode-termux
  '
  t "e2e: --version merespons" sh -c '.e2e-prefix/bin/opencode-termux --version | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+$"'
  t "e2e: subcommand version" sh -c '.e2e-prefix/bin/opencode-termux version | grep -q "upstream opencode"'
  t "e2e: subcommand doctor sehat" sh -c '.e2e-prefix/bin/opencode-termux doctor >/dev/null 2>&1'
  rm -rf dist-e2e .e2e-prefix
fi

echo ""
echo "=================================================="
echo "hasil: $pass lulus, $fail gagal"
[ "$fail" -eq 0 ] || exit 1