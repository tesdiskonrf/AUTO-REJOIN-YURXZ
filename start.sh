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

# --- Fungsi: cek apakah proses masih hidup ---
is_running() {
    local pid_file=$1
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0  # masih hidup
        fi
    fi
    return 1  # tidak jalan
}

# --- Stop proses lama kalau ada ---
if is_running "$PID_BOT"; then
    echo -e "${YELLOW}⚠️  Bot lama masih jalan (PID $(cat $PID_BOT)), dihentikan...${RESET}"
    kill -TERM "$(cat $PID_BOT)" 2>/dev/null
    sleep 1
fi

if is_running "$PID_MAIN"; then
    echo -e "${YELLOW}⚠️  Auto-rejoin lama masih jalan (PID $(cat $PID_MAIN)), dihentikan...${RESET}"
    su -c "kill -TERM $(cat $PID_MAIN)" 2>/dev/null
    sleep 1
fi

# --- Install dependency kalau belum ada ---
if ! python -c "import discord" &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall discord.py...${RESET}"
    pip install discord.py -q
fi

if ! python -c "import requests" &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall requests...${RESET}"
    pip install requests -q
fi

# --- Jalankan bot Discord di background ---
echo -e "${GREEN}🤖 Menjalankan Bot Discord...${RESET}"
nohup python "$BOT" > "$LOG_BOT" 2>&1 &
BOT_PID=$!
echo $BOT_PID > "$PID_BOT"
sleep 2

if kill -0 $BOT_PID 2>/dev/null; then
    echo -e "${GREEN}   ✓ Bot berjalan (PID: $BOT_PID)${RESET}"
else
    echo -e "${RED}   ✗ Bot gagal start! Cek log: $LOG_BOT${RESET}"
    tail -5 "$LOG_BOT"
fi

# --- Jalankan Auto-Rejoin (main.py) via root di background ---
echo -e "${GREEN}🎮 Menjalankan Auto-Rejoin...${RESET}"
# Kirim input "2" otomatis untuk pilih menu "Start Rejoin App"
nohup su -c "echo 2 | python $MAIN" > "$LOG_MAIN" 2>&1 &
MAIN_PID=$!
echo $MAIN_PID > "$PID_MAIN"
sleep 2

if kill -0 $MAIN_PID 2>/dev/null; then
    echo -e "${GREEN}   ✓ Auto-Rejoin berjalan (PID: $MAIN_PID)${RESET}"
else
    echo -e "${RED}   ✗ Auto-Rejoin gagal start! Cek log: $LOG_MAIN${RESET}"
    tail -5 "$LOG_MAIN"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}✅ Semua program berjalan di background!${RESET}"
echo ""
echo "   Kontrol via Discord:"
echo "   !status  — lihat status akun"
echo "   !stop    — stop auto-rejoin"
echo "   !restart — restart auto-rejoin"
echo ""
echo "   Log files:"
echo "   Bot    : $LOG_BOT"
echo "   Rejoin : $LOG_MAIN"
echo "=================================================="
echo ""
