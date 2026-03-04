# 🍪 Cara Ambil Cookie Roblox (.ROBLOSECURITY)

Cookie `.ROBLOSECURITY` digunakan untuk verifikasi status in-game kamu via Roblox API. **Jangan share ke siapapun** — cookie ini setara dengan password akun Roblox kamu.

---

## Metode A — Auto Extract (Direkomendasikan)

Saat menjalankan `setup.sh` atau memilih menu **"1. Create Config"** di `main.py`, script otomatis mencari dan mengambil cookie dari app Roblox yang terinstall di HP kamu.

Syarat:
- HP sudah di-root
- App Roblox sudah terinstall dan sudah login

Jika berhasil, cookie langsung tersimpan ke `config.json` tanpa perlu langkah manual.

---

## Metode B — Manual via Browser Android (Chrome)

1. Install ekstensi **Cookie Editor** di Chrome Android (via Kiwi Browser yang support ekstensi)
2. Buka [roblox.com](https://www.roblox.com) dan login
3. Buka Cookie Editor → cari cookie bernama `.ROBLOSECURITY`
4. Copy seluruh value-nya (dimulai dari `_|WARNING:...`)

---

## Metode C — Manual via Browser PC

1. Buka [roblox.com](https://www.roblox.com) di Chrome/Firefox dan login
2. Tekan **F12** → buka tab **Application** (Chrome) atau **Storage** (Firefox)
3. Klik **Cookies** → pilih `https://www.roblox.com`
4. Cari cookie bernama `.ROBLOSECURITY`
5. Copy seluruh isinya

Setelah dapat, paste ke `config.json`:
```json
"roblox_cookie": "_|WARNING:-DO-NOT-SHARE-THIS...|_NILAI_COOKIE_KAMU"
```

---

## Cookie Expired / Invalid

Cookie bisa expired jika:
- Kamu logout dari Roblox
- Kamu ganti password
- Roblox reset sesi secara otomatis

Solusi: login ulang ke Roblox lalu extract cookie lagi dengan menjalankan menu **"1. Create Config"** di `main.py`.

---

## Keamanan

- Simpan `config.json` dengan aman, jangan upload ke tempat publik
- Jangan screenshot cookie kamu
- Gunakan `ALLOWED_IDS` di `bot.py` untuk membatasi akses bot hanya ke kamu
