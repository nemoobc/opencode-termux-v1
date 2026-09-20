# 📥 Panduan Instalasi Lengkap — opencode-termux-v1

Panduan end-to-end: persyaratan → instalasi → verifikasi → pemakaian pertama →
update/uninstall → troubleshooting → FAQ.

> **Tanpa Node.js, tanpa npm, tanpa root, tanpa proot.** Cukup `sh` + `tar`.

---

## 1️⃣ Persyaratan

| Butuh | Nilai | Cara cek |
|---|---|---|
| Perangkat | Android 9+ **arm64** | jalankan `uname -m` di Termux → harus `aarch64` |
| Termux | Build **F-Droid / GitHub** — *bukan* Play Store | lihat [FAQ](#-faq) |
| Ruang | ± 500 MB bebas | `df -h $HOME \| tail -1` |
| Jaringan | Internet stabil (untuk unduh bundle) | installer punya retry otomatis |

> ⚠️ Perangkat arm32 (`uname -m` → `armv7*`/`armv8l`) **belum didukung** karena
> upstream tidak menyediakan binary musl untuk arsitektur itu.

## 2️⃣ Siapkan Termux

```bash
pkg update -y && pkg upgrade -y
pkg install -y tar curl
```

## 3️⃣ Instalasi

### Online (Recommended)

```bash
# 1. Unduh installer dari GitHub Releases:
curl -fsSL -o opencode-termux-installer.sh \
  https://github.com/nemoobc/opencode-termux-v1/releases/latest/download/opencode-termux-installer.sh

# 2. Jalankan (unduh bundle otomatis sesuai arsitektur):
sh opencode-termux-installer.sh
```

Installer otomatis: mengunduh bundle resmi (binary opencode v1 musl yang sudah
di-patch ELF), memasang ke `$PREFIX/lib/opencode-termux`, membuat perintah
`opencode-termux` di `$PREFIX/bin`, membetulkan DNS tanpa root, lalu menjalankan
smoke test. Selesai dalam ± 1 menit di jaringan normal.

### Offline (Tanpa Internet)

1. Unduh 2 file dari [Releases](https://github.com/nemoobc/opencode-termux-v1/releases):
   - `opencode-termux-installer.sh`
   - `opencode-termux-<versi>-aarch64.tar.gz` (sesuai arsitektur)
2. Taruh **di folder yang sama**, lalu:
   ```bash
   sha256sum -c SHA256SUMS.txt   # verifikasi (semua harus 'OK')
   sh opencode-termux-installer.sh
   ```

Installer mendeteksi bundle offline di sebelahnya otomatis — tanpa internet,
tanpa Node.js.

### **Instalasi per-artefak (dari GitHub Releases)**

Semua file diunduh dari
**[Releases](https://github.com/nemoobc/opencode-termux-v1/releases)**. Ganti `{v}`
dengan versi (contoh `1.20.12`), dan `-aarch64` dengan `-x86_64` kalau kamu di
emulator/PC. **Verifikasi dulu sebelum dipakai:** `sha256sum -c SHA256SUMS.txt`.

| # | Artefak | Cara install / pakai |
|---|---------|----------------------|
| 1 | `opencode-termux-{v}-aarch64.tar.gz` | **Bundle offline arm64.** Taruh di folder yang sama dengan installer lalu `sh opencode-termux-installer.sh`. (Manual: `tar xzf ... -C ~/.local/lib/opencode-termux --strip-components=1` lalu `ln -s ~/.local/lib/opencode-termux/bin/opencode-termux ~/.local/bin/opencode-termux`) |
| 2 | `opencode-termux-{v}-x86_64.tar.gz` | Bundle offline untuk emulator/PC x64. Sama seperti #1. |
| 3 | `opencode-config.zip` | Config default saja. `unzip opencode-config.zip -d ~/.config/opencode` (tidak menimpa `opencode.json` yang sudah ada). |
| 4 | `opencode-termux-installer.sh` | **Installer universal.** `sh opencode-termux-installer.sh`. Di Termux memasang ke `$PREFIX/lib/opencode-termux` + `$PREFIX/bin`; di luar Termux ke `~/.local/{lib,bin}`. Bisa offline (bundle di sampingnya) atau online (unduh otomatis). |
| 5 | `SHA256SUMS.txt` | Verifikasi keutuhan semua artefak: `sha256sum -c SHA256SUMS.txt`. |

## 4️⃣ Verifikasi

```bash
opencode-termux --version   # contoh: opencode v1.18.31
opencode-termux doctor      # diagnosis lengkap lingkungan
opencode-termux version     # info versi paket + binary
```

Interpretasi `doctor`:

| Output | Arti | Tindakan |
|---|---|---|
| ✅ semua baris | sehat | lanjut pakai |
| ❌ binary opencode | bundle belum ada | `opencode-termux update` |
| ❌ tar tersedia | utilitas hilang | `pkg install tar` |
| ❌ jaringan registry npm | internet bermasalah | cek koneksi |

## 5️⃣ Pemakaian pertama

```bash
mkdir -p ~/project-coba && cd ~/project-coba
opencode-termux
```

Config default sudah terpasang otomatis dengan **model
`opencode/big-pickle`** — tanpa API key. Lokasi config:
`~/.config/opencode/opencode.json` (milik user; installer tidak pernah menimpa).

**Keybind default:** **Tab = switch agent (build ↔ plan)** — bawaan opencode v1,
tidak perlu konfigurasi tambahan.

## 6️⃣ Update & uninstall

```bash
opencode-termux update                        # perbarui bundle ke rilis terbaru
rm -rf $PREFIX/lib/opencode-termux            # hapus bundle
rm -f $PREFIX/bin/opencode-termux             # hapus perintah
```

Config dan riwayat di `~/.config/opencode/` tidak disentuh saat uninstall.

---

## 🩺 Troubleshooting

| Gejala | Penyebab | Solusi |
|---|---|---|
| `tar: not found` saat install | utilitas tar belum ada | `pkg install tar` lalu jalankan installer lagi |
| `curl: not found` | utilitas curl belum ada | `pkg install curl` (atau pakai wget) |
| Timeout DNS / host not found | resolv.conf belum terbentuk | jalankan sekali: `opencode-termux` (dibuat otomatis), cek `$PREFIX/etc/resolv.conf` |
| `Exec format error` | CPU bukan arm64/x64 | cek `uname -m`; arm32 tidak didukung |
| Bundle gagal unduh berkali-kali | jaringan operator bermasalah | coba WiFi / ganti DNS hotspot; installer retry otomatis |
| `smoke test gagal` saat install | bundle korup / arsitektur salah | unduh ulang bundle, verifikasi `sha256sum -c SHA256SUMS.txt` |
| Termux dari Play Store crash/versi jadul | build Play Store dihentikan | pindah ke [build F-Droid](https://f-droid.org/en/packages/com.termux/) |

## ❓ FAQ

**Butuh root?** Tidak. Semua berjalan di ruang user Termux.

**Butuh Node.js/npm?** Tidak. Installer murni POSIX `sh` — cukup `tar` + `curl`/`wget`.

**Kenapa tidak pakai proot/chroot seperti lainnya?** Bisa saja — tapi overhead
I/O proot besar di HP. Paket ini menjalankan binary musl langsung: lebih cepat,
lebih hemat baterai.

**Data apa yang disimpan?**
- `~/.config/opencode/` — config kamu
- `$PREFIX/lib/opencode-termux/vendor/` — binary + loader (± 200 MB)

**Apakah binary-nya resmi?** Ya — diunduh dari npm `opencode-linux-arm64-musl`
resmi milik upstream opencode (versi v1), lalu di-patch ELF (`PT_INTERP` +
`RPATH`) agar jalan langsung di Termux. Paket ini hanya membungkus + menambal
loader libc agar ramah Termux.

**Bisa dipakai di emulator/Waydroid/x64?** Bisa — unduh bundle `-x86_64` dan
jalankan installer yang sama.