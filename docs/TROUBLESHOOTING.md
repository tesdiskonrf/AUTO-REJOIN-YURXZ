# ❓ Troubleshooting

Solusi untuk masalah umum yang mungkin ditemui.

---

## Root & Permission

**"Root access required"**
- Pastikan Magisk atau KernelSU terinstall dan aktif
- Buka Termux → ketik `su` → grant permission saat popup muncul
- Cek status root: `su -c "id"`

**"SELinux error"**
```bash
su -c "getenforce"        # cek status
su -c "setenforce 0"      # set ke permissive manual
```
Script sudah otomatis handle ini saat startup, tapi bisa dilakukan manual jika perlu.

---

## Roblox Tidak Terbuka

**App tidak launch setelah rejoin**
```bash
# Test manual
su -c "am start -a android.intent.action.VIEW -d 'PS_LINK_KAMU' -p com.roblox.client"
```

**Package name salah**
```bash
# Cek package Roblox yang terinstall
su -c "pm list packages | grep roblox"
```
Update `package` di `config.json` sesuai hasil di atas.

---

## Cookie & Status

**"Cookie not found"**
- Pastikan Roblox sudah login di HP
- Coba extract manual via browser (lihat [COOKIE.md](./COOKIE.md))
- Cek apakah app Roblox ada di `/data/data/com.roblox.client/`

**Game ID tidak terdeteksi / status selalu "Not in game"**
- Pastikan `roblox_cookie` di `config.json` benar dan belum expired
- Cek validity cookie:
```bash
curl -s "https://users.roblox.com/v1/users/authenticated" \
  -H "Cookie: .ROBLOSECURITY=COOKIE_KAMU"
```
Jika response berisi `id` dan `name`, cookie masih valid.

**Script terus rejoin padahal sudah in-game**
- Naikkan `restart_delay` di `config.json` (coba 30-45 detik)
- Game mungkin belum fully loaded saat pertama kali dicek

---

## Performance

**RAM penuh / HP lemot**
- Turunkan jumlah akun yang dijalankan bersamaan
- Naikkan `check_interval` ke 60 detik
- Pastikan fitur kill background apps aktif (sudah default)

**Roblox sering crash**
- Clear cache manual: `su -c "pm clear --cache-only com.roblox.client"`
- Restart HP sebelum menjalankan script

---

## Discord Bot

Lihat troubleshooting bot di [BOT.md](./BOT.md#troubleshooting-bot).

---

## Log Files

Untuk debug lebih lanjut, cek file log:

```bash
# Log aktivitas rejoin
cat /sdcard/Auto-Rejoin/activity.log

# Log bot Discord
cat /sdcard/Auto-Rejoin/bot.log

# Log auto-rejoin engine
cat /sdcard/Auto-Rejoin/rejoin.log

# Log boot
cat /sdcard/Auto-Rejoin/boot.log
```

---

## Reset Total

Jika ada masalah yang tidak bisa diselesaikan, hapus semua file dan jalankan setup dari awal:

```bash
rm -rf /sdcard/Auto-Rejoin
bash /sdcard/setup.sh
```
