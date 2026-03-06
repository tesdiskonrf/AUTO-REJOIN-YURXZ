#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  start.sh — Jalankan bot Discord + Auto-Rejoin sekaligus
#  Cara pakai: bash start.sh
# ============================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOT="$DIR/bot.py"
MAIN="$DIR/main.py"
LOG_BOT="$DIR/bot.log"
LOG_MAIN="$DIR/rejoin.log"
PID_BOT="$DIR/bot.pid"
PID_MAIN="$DIR/main.pid"
PYTHON="/data/data/com.termux/files/usr/bin/python3"

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo ""
echo "=================================================="
echo "   🍪 Roblox Auto-Rejoin — Launcher"
echo "=================================================="
echo ""

# --- Cek root ---
if ! su -c "id" &>/dev/null; then
    echo -e "${RED}❌ Root tidak tersedia! Grant root ke Termux dulu.${RESET}"
    exit 1
fi

# --- WAKELOCK: Cegah Termux di-kill sistem ---
echo -e "${GREEN}🔒 Mengaktifkan Wakelock...${RESET}"
termux-wake-lock 2>/dev/null || true

# --- KEEP ALIVE: Cegah Roblox di-kill sistem ---
echo -e "${GREEN}🛡️  Melindungi Roblox dari kill sistem...${RESET}"

# Disable battery optimization untuk Roblox & Termux
su -c "dumpsys deviceidle whitelist +com.roblox.client" 2>/dev/null
su -c "dumpsys deviceidle whitelist +com.termux" 2>/dev/null

# Disable app standby
su -c "settings put global app_standby_enabled 0" 2>/dev/null

# Keep screen on
su -c "settings put global stay_on_while_plugged_in 3" 2>/dev/null
su -c "settings put system screen_off_timeout 2147483647" 2>/dev/null

# Disable aggressive memory killing
su -c "settings put global aggressive_wifi_mode 0" 2>/dev/null

# Set Roblox sebagai persistent app (tidak akan di-kill)
su -c "cmd appops set com.roblox.client RUN_IN_BACKGROUND allow" 2>/dev/null
su -c "cmd appops set com.roblox.client RUN_ANY_IN_BACKGROUND allow" 2>/dev/null

# Disable battery optimization via pm
su -c "cmd battery unplug" 2>/dev/null
su -c "dumpsys deviceidle disable" 2>/dev/null

echo -e "${GREEN}   ✓ Roblox dilindungi dari kill sistem${RESET}"

# --- Stop proses lama kalau ada ---
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

if is_running "$PID_BOT"; then
    echo -e "${YELLOW}⚠️  Bot lama masih jalan, dihentikan...${RESET}"
    kill -TERM "$(cat $PID_BOT)" 2>/dev/null
    sleep 1
fi

if is_running "$PID_MAIN"; then
    echo -e "${YELLOW}⚠️  Auto-rejoin lama masih jalan, dihentikan...${RESET}"
    su -c "kill -TERM $(cat $PID_MAIN)" 2>/dev/null
    sleep 1
fi

# --- Install dependency kalau belum ada ---
if ! $PYTHON -c "import discord" &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall discord.py...${RESET}"
    pip install discord.py -q
fi

if ! $PYTHON -c "import requests" &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall requests...${RESET}"
    pip install requests -q
fi

# --- Jalankan bot Discord di background ---
echo -e "${GREEN}🤖 Menjalankan Bot Discord...${RESET}"
nohup $PYTHON "$BOT" > "$LOG_BOT" 2>&1 &
BOT_PID=$!
echo $BOT_PID > "$PID_BOT"
sleep 2

if kill -0 $BOT_PID 2>/dev/null; then
    echo -e "${GREEN}   ✓ Bot berjalan (PID: $BOT_PID)${RESET}"
else
    echo -e "${RED}   ✗ Bot gagal start! Cek log: $LOG_BOT${RESET}"
    tail -5 "$LOG_BOT"
fi

# --- Jalankan Auto-Rejoin via root di background ---
echo -e "${GREEN}🎮 Menjalankan Auto-Rejoin...${RESET}"
nohup su -c "cd $DIR && echo 2 | $PYTHON $MAIN" > "$LOG_MAIN" 2>&1 &
MAIN_PID=$!
echo $MAIN_PID > "$PID_MAIN"
sleep 2

if kill -0 $MAIN_PID 2>/dev/null; then
    echo -e "${GREEN}   ✓ Auto-Rejoin berjalan (PID: $MAIN_PID)${RESET}"
else
    echo -e "${RED}   ✗ Auto-Rejoin gagal start! Cek log: $LOG_MAIN${RESET}"
    tail -5 "$LOG_MAIN"
fi

# --- Background watcher: pastikan Roblox tidak di-kill ---
echo -e "${GREEN}👁️  Menjalankan Roblox Watchdog...${RESET}"
cat > /tmp/roblox_watchdog.sh << 'WATCHDOG'
#!/data/data/com.termux/files/usr/bin/bash
PYTHON="/data/data/com.termux/files/usr/bin/python3"
while true; do
    # Cek apakah Roblox masih jalan
    ROBLOX_PID=$(su -c "pidof com.roblox.client" 2>/dev/null)
    if [ -n "$ROBLOX_PID" ]; then
        # Set Roblox sebagai foreground agar tidak di-kill
        su -c "renice -n -10 -p $ROBLOX_PID" 2>/dev/null
        # Prevent kill dengan oom_adj
        su -c "echo -1000 > /proc/$ROBLOX_PID/oom_score_adj" 2>/dev/null
    fi
    sleep 10
done
WATCHDOG
chmod +x /tmp/roblox_watchdog.sh
nohup bash /tmp/roblox_watchdog.sh > /dev/null 2>&1 &
echo $! > "$DIR/watchdog.pid"
echo -e "${GREEN}   ✓ Watchdog berjalan${RESET}"

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Bot + Auto-Rejoin berjalan di background${RESET}"
echo "   Kontrol via Discord: !start !stop !status !restart"
echo "=================================================="
echo ""
