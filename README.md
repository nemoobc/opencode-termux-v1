# 📱 opencode-termux-v1

**[opencode](https://opencode.ai) CLI v1 native di Termux/Android — tanpa proot, tanpa root.**

[![release](https://img.shields.io/github/v/release/nemoobc/opencode-termux-v1?color=3B82F6)](https://github.com/nemoobc/opencode-termux-v1/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/nemoobc/opencode-termux-v1/test.yml?label=test&color=22C55E)](.github/workflows/test.yml)
[![platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-3DDC84)](#)
[![arch](https://img.shields.io/badge/arch-arm64-blue)](#)
[![sync upstream](https://img.shields.io/badge/sync-upstream%20otomatis-C9A227)](.github/workflows/sync-upstream.yml)
[![license](https://img.shields.io/badge/license-MIT-green)](#)

---

## 🙏 **Attribution & Terima Kasih**

### **Source Asli: opencode-ai (anomalyco)**
**opencode-termux HANYA membungkus & menyesuaikan binary resmi opencode-ai** agar jalan native di Termux/Android.

| Komponen | Source | Credit |
|----------|--------|--------|
| **Core CLI** | [opencode-ai](https://github.com/anomalyco/opencode) | 🏆 **FULL CREDIT** |
| **Agent System** | opencode-ai | 🏆 **FULL CREDIT** |
| **LLM Integration** | opencode-ai | 🏆 **FULL CREDIT** |
| **Architecture** | opencode-ai | 🏆 **FULL CREDIT** |
| **Musl Loader Build** | opencode-termux (custom) | nemoobc |
| **Termux Adaptation** | opencode-termux | nemoobc |
| **Agent Ecosystem** | opencode-termux (extended) | nemoobc |
| **Offline Installer** | opencode-termux | nemoobc |
| **Automation (CI/CD)** | opencode-termux | nemoobc |

> **opencode-ai** adalah upstream asli — semua inovasi fundamental, arsitektur agent, integrasi LLM, dan core CLI berasal dari **tim opencode-ai (anomalyco)**. Kami hanya menambal agar jalan di Termux (musl libc, Bionic compat, DNS patch) dan menambah ekosistem agent/automation.

🔗 **Upstream:** https://github.com/anomalyco/opencode  
📦 **npm:** https://www.npmjs.com/package/opencode-ai  
📖 **Docs:** https://opencode.ai  

---

## 🧹 **Tanpa Agent / Command / Skill Bawaan**

Paket ini **tidak** membundel agent, command, atau skill opencode — biar
lingkungan kamu bersih dan bebas konflik dengan setup sendiri. Kalau butuh,
pasang manual di `~/.config/opencode/`.

**Config default ikut terpasang:** model `opencode/big-pickle` — **tanpa API key**.

---

## 🔄 **Sync Upstream Otomatis**

Workflow GitHub mengecek [opencode-ai](https://github.com/anomalyco/opencode) baru setiap **6 jam** — begitu ada versi baru, paket ini otomatis menyesuaikan:

```
┌─────────────────────────────────────────────────────────────┐
│  sync-upstream.yml (cron 0 */6 * * *)                        │
├─────────────────────────────────────────────────────────────┤
│  1. Cek npm registry: opencode-ai latest version            │
│  2. Kalau baru: bump UPSTREAM + VERSION (patch +1)          │
│  3. Anti-bentrok: cek tag GitHub                            │
│  4. Commit + tag vX.Y.Z + push                              │
│  5. Trigger release.yml (build 5 artefak)                   │
└─────────────────────────────────────────────────────────────┘
```

**Commit memakai identitas nemoobc** — riwayat bersih, traceable.

---

## 🏗️ **Arsitektur: Kenapa Paket Ini Ada?**

Installer resmi `opencode-ai` gagal di Termux karena:
1. Tidak mengenali `process.platform === "android"`
2. Tidak menyediakan build untuk **Bionic libc** (Termux pakai Bionic, bukan glibc)

**Solusi opencode-termux — tanpa trik aneh:**

```
opencode-termux (Node shim)
   └─ vendor/opencode       ← binary resmi opencode-linux-arm64-musl
        ⤳ PT_INTERP → vendor/ld-musl.so   (patch ELF via patchelf)
        ⤳ RPATH    → vendor/              (libstdc++ / libgcc_s dari Alpine)
```

\* Path `/etc/resolv.conf` & `/etc/hosts` dipatch saat kompilasi menuju `$PREFIX/etc/` sehingga **DNS jalan tanpa root**.

**Kenapa patch ELF (bukan invoke loader)?** Dengan patch `PT_INTERP` +
`RPATH`, binary jalan **langsung** (tanpa `ld-musl.so vendor/opencode`).
Hasilnya: proses lebih bersih, server background (yang di-spawn opencode)
ikut jalan normal, dan tidak ada masalah path relatif.

**Auto-heal:** Kalau `postinstall` terlewat (mis. `--ignore-scripts`), binary dipasang otomatis saat pertama kali jalan.

**Auto-stop server:** Kalau TUI yang memulai server background, saat exit
(`/exit` / Ctrl-C) server ikut dimatikan otomatis (hemat RAM/baterai). Kalau
server sudah jalan duluan, dibiarkan — tidak membunuh sesi lain.

---

## 📦 **Paket Rilis (5 Artefak — Semua Versi Terpreservasi)**

Setiap rilis (via `release.yml` → `scripts/build-release.sh`) menghasilkan **5 artefak**:

| File | Format | Target | Deskripsi |
|------|--------|--------|-----------|
| `opencode-termux-{v}-aarch64.tar.gz` | `.tar.gz` | Termux ARM64 | **Offline bundle lengkap** (vendor musl + binary + wrapper) |
| `opencode-termux-{v}-x86_64.tar.gz` | `.tar.gz` | Emulator/x64 | Offline bundle x64 |
| `opencode-config.zip` | `.zip` | Manual | Config default saja (bebas versi) |
| `opencode-termux-installer.sh` | `.sh` | Universal | **POSIX sh installer** (tanpa Node, offline-capable) |
| `SHA256SUMS.txt` | `.txt` | Verify | Checksum sha256 semua file di atas |

> 💡 **Philosophy:** Semua artefak berbundle **versioned** di nama (kecuali
> `installer.sh` & `opencode-config.zip` yang deliberately bebas versi agar
> gampang ditimpa pada update). History tidak hilang — versi lama tetap di GitHub Releases.

---

## 🚀 **Instalasi Cepat**

### **Online (Recommended — Tanpa Node.js)**
```bash
# 1. Download installer dari GitHub Releases:
curl -fsSL -o opencode-termux-installer.sh \
  https://github.com/nemoobc/opencode-termux-v1/releases/latest/download/opencode-termux-installer.sh

# 2. Jalankan (unduh bundle otomatis sesuai arsitektur):
sh opencode-termux-installer.sh

# 3. Pakai:
opencode-termux --version
```

### **Offline (Tanpa Internet)**
```bash
# 1. Download 2 file dari GitHub Releases:
#    - opencode-termux-installer.sh
#    - opencode-termux-{v}-aarch64.tar.gz
#    - SHA256SUMS.txt (opsional, untuk verifikasi)

# 2. Taruh di folder yang sama, verifikasi:
sha256sum -c SHA256SUMS.txt

# 3. Jalankan installer (POSIX sh, no Node):
sh opencode-termux-installer.sh
```

### **Instalasi Per-Artefak**

Semua file diunduh dari **[GitHub Releases](https://github.com/nemoobc/opencode-termux-v1/releases)** (ganti `{v}` dengan versi, contoh `1.20.12`).

| # | Artefak | Cara Install / Pakai |
|---|---------|----------------------|
| 1 | `opencode-termux-{v}-aarch64.tar.gz` | **Bundle offline arm64.** Taruh di folder sama dengan installer lalu `sh opencode-termux-installer.sh` (atau ekstrak manual: `tar xzf opencode-termux-{v}-aarch64.tar.gz -C ~/.local/lib/opencode-termux --strip-components=1` lalu `ln -s ~/.local/lib/opencode-termux/bin/opencode-termux ~/.local/bin/opencode-termux`) |
| 2 | `opencode-termux-{v}-x86_64.tar.gz` | Sama seperti #1, tapi untuk emulator/PC **x64**. Bisa dijalankan manual: `./vendor/opencode --version` |
| 3 | `opencode-config.zip` | **Config default saja.** Ekstrak ke `~/.config/opencode/`: `unzip opencode-config.zip -d ~/.config/opencode` (tidak menimpa `opencode.json` yang sudah ada) |
| 4 | `opencode-termux-installer.sh` | **Installer universal.** `sh opencode-termux-installer.sh`. Baca bundle `-{arch}.tar.gz` di folder yang sama (offline) atau unduh otomatis dari Releases (online). Target instalasi: Termux → `$PREFIX/{lib,bin}`, selain itu → `~/.local/{lib,bin}` |
| 5 | `SHA256SUMS.txt` | **Verifikasi.** Sebelum install, cek keutuhan: `sha256sum -c SHA256SUMS.txt` (jalankan di folder berisi semua file artefak) |

> **Selalu verifikasi dulu:** `sha256sum -c SHA256SUMS.txt` sebelum mengekstrak/menjalankan artefak apa pun yang diunduh.

---

## ✅ **Verifikasi & Diagnostik**

```bash
opencode-termux --version   # Versi binary upstream
opencode-termux doctor      # Diagnosis lengkap environment
opencode-termux version     # Info versi paket + binary
opencode-termux update      # Update binary ke upstream terbaru
```

**Doctor output interpretation:**
| Output | Arti | Tindakan |
|--------|------|----------|
| ✅ semua baris | Sehat | Lanjut pakai |
| ❌ vendor lengkap | Bundle belum ada | `opencode-termux update` |
| ❌ tar tersedia | Utilitas hilang | `pkg install tar` |
| ⚠️ platform bukan android | Di luar Android | Wajar di CI/emulator |

---

## 🎯 **Pemakaian Pertama**

```bash
mkdir -p ~/project-coba && cd ~/project-coba
opencode-termux
```

**Config default** sudah terpasang otomatis dengan **model `opencode/big-pickle`** — **tanpa API key**.  
Lokasi: `~/.config/opencode/opencode.json` (milik user; installer **tidak pernah menimpa**).

**Keybind default:** **Tab = switch agent (build ↔ plan)** — sudah bawaan
opencode v1, tidak perlu konfigurasi tambahan.

---

## 🧪 **Testing**

```bash
sh test/run.sh          # Struktur + unit (cepat, tanpa unduhan besar)
OCX_E2E=1 sh test/run.sh  # E2E penuh: build bundle + install + smoke test + subcommand
```

CI GitHub menjalankan:
- Struktur test di setiap push
- **E2E ARM64 sungguhan** (native di runner `ubuntu-24.04-arm` via container Alpine — loader musl prebuilt Termux benar-benar dieksekusi)

---

## 🔒 **Keamanan**

- Tarball binary diverifikasi **sha512** terhadap metadata resmi registry npm
- Unduhan memakai retry + backoff eksponensial (tahan jaringan gemetar)
- gitleaks scan di CI untuk deteksi secrets
- Binary upstream tidak dimodifikasi — hanya dibungkus

---

## 📚 **Dokumentasi Lengkap (Termasuk di Setiap Rilis)**

| File | Deskripsi |
|------|-----------|
| **[INSTALASI.md](docs/INSTALASI.md)** | Panduan end-to-end: persyaratan → install → verifikasi → update/uninstall → troubleshooting → FAQ |
| **[RELEASE-HISTORY.md](RELEASE-HISTORY.md)** | Release notes adaptif semua versi (auto-generated) |
| **prebuilt/README.md** | Cara rebuild musl loader custom |

---

## 🛠 **Development & Build**

```bash
# Clone
git clone https://github.com/nemoobc/opencode-termux-v1.git
cd opencode-termux-v1

# Build semua artefak rilis (5 format)
./scripts/build-release.sh

# Output di ./dist/
ls -la dist/
```

**Scripts tersedia:**
| Script | Fungsi |
|--------|--------|
| `sh test/run.sh` | Struktur + unit test |
| `OCX_E2E=1 sh test/run.sh` | E2E test penuh |
| `./scripts/build-release.sh` | Build 5 artefak rilis |
| `./scripts/installer.sh` | Installer POSIX sh (tanpa Node) |

---

## 📦 **Versi & Rilis**

| Link | Deskripsi |
|------|-----------|
| [GitHub Releases](https://github.com/nemoobc/opencode-termux-v1/releases) | **Semua versi** (termasuk lama) + 5 artefak per versi |
| [RELEASE-HISTORY.md](RELEASE-HISTORY.md) | Release notes/riwayat perubahan per versi |

**Skema versi:** `paket.upstream.patch` — contoh: `1.20.12` (paket v1.20, upstream opencode 1.18.31, patch 12)

### 🔄 Alur Rilis Otomatis (kendali tunggal: `sync-upstream`)

Satu-satunya mekanisme yang menaikkan versi & menerbitkan rilis adalah workflow **`sync-upstream`** (otomatis tiap 6 jam + bisa manual via `workflow_dispatch`):

1. Cek versi terbaru **`opencode-ai`** di npm.
2. Berbeda dari `UPSTREAM`? → naikkan `UPSTREAM` + `VERSION` (patch +1), commit + tag `vX.Y.Z`.
3. Dispatch workflow **`release`** → build 5 artefak + unggah ke GitHub Releases.

Rilis manual (mis. commit fitur/perbaikan): naikkan `VERSION` → tag `vX.Y.Z` → push tag → workflow `release` otomatis build + GitHub release.

---

## 🤝 **Kontribusi**

1. Fork & branch
2. Commit conventional (`feat:`, `fix:`, `docs:`, `chore:`)
3. Push & buat PR
4. CI otomatis jalan (test + build)
5. Review & merge

**Ide kontribusi:**
- Perbaiki docs di `docs/`
- Optimasi musl loader build
- CI/CD improvement

---

## 📄 **Lisensi**

**MIT License** — bebas pakai, modifikasi, distribusi.

**Binary opencode resmi** dari upstream opencode-ai — paket ini hanya membungkus + menambah agent/automation.

---

## 🔗 **Link Penting**

| Link | Deskripsi |
|------|-----------|
| [GitHub Repo](https://github.com/nemoobc/opencode-termux-v1) | Source code & issues |
| [GitHub Releases](https://github.com/nemoobc/opencode-termux-v1/releases) | **Semua artefak rilis terpreservasi** |
| [opencode-ai (Upstream)](https://github.com/anomalyco/opencode) | **Source asli — credit utama** |
| [opencode.ai Docs](https://opencode.ai) | Dokumentasi upstream |
| [Termux F-Droid](https://f-droid.org/en/packages/com.termux/) | Termux yang benar (bukan Play Store) |

---

**Dibangun dengan ❤️ untuk komunitas Termux/Android**  
**Powered by [opencode-ai](https://github.com/anomalyco/opencode) — terima kasih tim anomalyco!** 🙏