# 🤖 Setup Discord Bot

Panduan lengkap setup Discord bot untuk mengontrol Auto-Rejoin dari HP atau PC manapun.

---

## Cara Kerja

Bot Discord berjalan langsung di **Termux** di HP Android kamu. Selama HP online dan Termux aktif, bot bisa menerima perintah dari Discord kapanpun dan dari mana saja.

```
HP Android kamu
├── Termux
│   ├── bot.py      ← Bot Discord (jalan di background)
│   └── main.py     ← Auto-rejoin engine
└── Roblox App
```

---

## Langkah 1 — Buat Bot Discord

1. Buka [discord.com/developers/applications](https://discord.com/developers/applications)
2. Klik **New Application** → beri nama (contoh: `Roblox Rejoin`)
3. Pergi ke tab **Bot** di sidebar kiri
4. Klik **Reset Token** → copy tokennya, simpan baik-baik
5. Scroll ke bawah, aktifkan **Message Content Intent**

> ⚠️ Token bot = password bot. Jangan share ke siapapun!

---

## Langkah 2 — Invite Bot ke Server Discord

1. Masih di halaman developer, pergi ke tab **OAuth2 → URL Generator**
2. Centang scope: `bot`
3. Centang permission: `Send Messages`, `Read Messages/View Channels`, `Embed Links`, `Attach Files`
4. Copy URL yang muncul di bawah → buka di browser → pilih server kamu → Authorize

---

## Langkah 3 — Cari Discord User ID Kamu

Ini dipakai supaya hanya kamu yang bisa kontrol bot.

1. Buka Discord → **Settings → Tampilan**
2. Aktifkan **Mode Pengembang**
3. Klik kanan nama kamu di mana saja → **Salin ID Pengguna**

---

## Langkah 4 — Isi Token di Setup

Saat menjalankan `setup.sh`, kamu akan diminta mengisi:
- **Bot Token** — dari langkah 1
- **Discord User ID** — dari langkah 3

Setup akan otomatis menyimpannya ke `bot.py`.

Atau edit manual di `bot.py`:
```python
BOT_TOKEN   = "token_bot_kamu_di_sini"
ALLOWED_IDS = [123456789012345678]  # Discord User ID kamu
```

---

## Perintah Bot

| Perintah | Fungsi |
|---|---|
| `!start` | Jalankan auto-rejoin |
| `!stop` | Hentikan auto-rejoin |
| `!restart` | Restart ulang auto-rejoin |
| `!status` | Lihat status semua akun (embed) |
| `!help` | Tampilkan daftar perintah |

---

## Menjalankan Bot

Bot otomatis jalan saat kamu pakai `start.sh`:
```bash
bash /sdcard/Auto-Rejoin/start.sh
```

Untuk jalankan bot saja (tanpa auto-rejoin):
```bash
cd /sdcard/Auto-Rejoin
python bot.py
```

---

## Auto-Start Saat Boot

Sudah di-handle otomatis oleh `setup.sh` via **Termux:Boot**. Setelah HP restart, bot + auto-rejoin langsung jalan sendiri setelah 15 detik.

Pastikan **Termux:Boot** sudah diinstall dari F-Droid dan sudah dibuka minimal sekali.

---

## Troubleshooting Bot

**Bot tidak merespons perintah**
- Pastikan **Message Content Intent** sudah aktif di dashboard developer Discord
- Cek apakah bot sudah di-invite ke server yang benar
- Lihat log: `cat /sdcard/Auto-Rejoin/bot.log`

**`!status` menampilkan "Tidak ada data"**
- Auto-rejoin belum berjalan. Ketik `!start` dulu

**Bot offline padahal sudah dijalankan**
- Cek koneksi internet HP
- Cek token bot: `cat /sdcard/Auto-Rejoin/bot.py | grep BOT_TOKEN`
