# Riwayat Rilis

---

# v1.20.12 (2026-09-20)
Upstream: opencode v1.18.31

**Paket opencode v1 native untuk Termux/Android — tanpa root, tanpa proot:**

- **Upstream v1**: binary opencode 1.18.31 dari npm registry resmi
  (`opencode-linux-{arch}-musl`) — diverifikasi **sha512** terhadap metadata registry.
- **Patch ELF**: `PT_INTERP` → `vendor/ld-musl.so` + `RPATH` → `vendor` via
  patchelf (diunduh dari Alpine CDN). Binary jalan **langsung** tanpa invoke loader.
- **Wrapper**: eksekusi binary langsung + `cleanEnv()` (bersihkan LD_PRELOAD) +
  `ensureTmp()` (TMPDIR → `$PREFIX/tmp`) + `ensureDns()` (resolv.conf tanpa root).
- **Auto-stop server**: TUI yang memulai server → saat exit server ikut mati
  (hemat RAM/baterai); server yang sudah jalan duluan dibiarkan.
- **Auto-heal**: kalau `postinstall` terlewat (`--ignore-scripts`), bundle
  dipasang otomatis saat pertama kali jalan.
- **Command tetap `opencode-termux`** — subcommand `update`, `doctor`, `version`.
- **Keybind default**: Tab = switch agent (build ↔ plan) — bawaan opencode v1.
- **Bersih**: tanpa agent/command/skill bawaan — lingkungan bebas konflik.