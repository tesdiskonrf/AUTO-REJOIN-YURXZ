an issue sangat diterima!v
# 🍪 Roblox Auto-Rejoin Tool

> Auto rejoin Private Server Roblox di Android rooted — support multi akun, Discord bot control, grafik minimum, dan auto mute audio.

---

## ✨ Fitur

| Fitur | Keterangan |
|---|---|
| 🔄 Auto Rejoin | Otomatis masuk kembali jika crash, kicked, atau server switch |
| 👥 Multi Akun | Support banyak akun sekaligus dengan split screen otomatis |
| 🤖 Discord Bot | Kontrol via Discord: `!start` `!stop` `!status` `!restart` |
| 🗑️ Auto Clear Cache | Bersihkan cache Roblox setiap rejoin |
| 💀 Kill Background Apps | Matikan app tidak penting otomatis untuk bebaskan RAM |
| 🎨 Grafik Minimum | Set kualitas grafis & resolusi Roblox ke paling rendah |
| 🔇 Auto Mute Audio | Mute audio Roblox otomatis setiap rejoin (bisa dinaikkan manual) |
| 📢 Discord Webhook | Kirim status + screenshot ke Discord tiap 10 menit |
| 🔁 Auto Boot | Semua program jalan otomatis saat HP restart |

---

## 📋 Persyaratan

- Android **rooted** (Magisk / KernelSU)
- **Termux** — download dari [F-Droid](https://f-droid.org/packages/com.termux/) ⚠️ jangan dari Play Store
- **Termux:Boot** — download dari [F-Droid](https://f-droid.org/packages/com.termux.boot/)
- App **Roblox** terinstall dan sudah login
- Akun **Discord** + Bot Token (untuk fitur bot)

---

## 🚀 Instalasi (Super Simple)

Cukup **1 file, 1 perintah** — semua otomatis disetup.

### Langkah 1 — Siapkan aplikasi
1. Install **Termux** dari F-Droid
2. Install **Termux:Boot** dari F-Droid, lalu **buka sekali** supaya aktif
3. Buka Termux, grant root permission saat diminta Magisk/KernelSU

### Langkah 2 — Download setup script
Download file `setup.sh` dari halaman [Releases](../../releases) lalu taruh di `/sdcard/` via MT Manager atau file manager.

### Langkah 3 — Jalankan
```bash
bash /sdcard/setup.sh
```

Script akan otomatis:
- Install semua dependencies
- Minta input konfigurasi (cookie, PS link, bot token, dll)
- Generate semua file yang diperlukan
- Setup auto-boot saat HP restart
- Langsung jalankan bot + auto-rejoin

### Lain kali (setelah setup)
```bash
bash /sdcard/Auto-Rejoin/start.sh
```

---

## 📁 Struktur File

```
/sdcard/Auto-Rejoin/
├── setup.sh       ← Setup wizard (jalankan pertama kali)
├── main.py        ← Core auto-rejoin engine
├── bot.py         ← Discord bot controller
├── start.sh       ← Launcher (jalankan semua sekaligus)
├── config.json    ← Konfigurasi akun & settings
├── status.json    ← Status real-time (dibaca bot)
└── activity.log   ← Log aktivitas
```

---

## ⚙️ Konfigurasi (`config.json`)

```json
{
  "check_interval": 30,
  "restart_delay": 15,
  "webhook_url": "https://discord.com/api/webhooks/...",
  "accounts": [
    {
      "name": "NamaAkun",
      "user_id": 12345678,
      "package": "com.roblox.client",
      "roblox_cookie": "_|WARNING:...",
      "ps_link": "https://www.roblox.com/share?code=XXXXX&type=Server"
    }
  ]
}
```

| Parameter | Keterangan |
|---|---|
| `check_interval` | Seberapa sering cek status (detik). Rekomendasi: 30 |
| `restart_delay` | Jeda antar launch akun (detik). Rekomendasi: 15 |
| `webhook_url` | Discord Webhook URL untuk notifikasi (opsional) |
| `roblox_cookie` | Cookie `.ROBLOSECURITY` — auto diambil saat setup |
| `ps_link` | Link Private Server Roblox kamu |

---

## 📖 Dokumentasi Lengkap

- [🤖 Setup Discord Bot](./docs/BOT.md)
- [🍪 Cara Ambil Cookie Manual](./docs/COOKIE.md)
- [❓ Troubleshooting](./docs/TROUBLESHOOTING.md)

---

## ⚠️ Catatan Keamanan

- **Jangan share** `config.json` atau cookie `.ROBLOSECURITY` ke siapapun
- Cookie = akses penuh ke akun Roblox kamu
- Ganti password Roblox secara berkala
- Logout dari semua device akan mereset cookie (perlu setup ulang)

---

## 📝 Lisensi

Free to use dan modify.

---

## 🤝 Kontribusi

Pull request dan issue sangat diterima!
