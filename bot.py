import discord
from discord.ext import commands
import subprocess
import os
import json
import sys
import time
import signal

# ============================================================
#  KONFIGURASI — isi sebelum jalankan!
# ============================================================
BOT_TOKEN    = "ISI_TOKEN_BOT_DISCORD_KAMU"
PREFIX       = "!"
ALLOWED_IDS  = []   # Kosongkan = semua bisa pakai. Isi user ID kamu: [123456789]
MAIN_PY_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "main.py")
STATUS_FILE  = os.path.join(os.path.dirname(os.path.abspath(__file__)), "status.json")
# ============================================================

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents, help_command=None)

# Simpan proses auto-rejoin yang sedang berjalan
rejoin_process = None


def is_allowed(ctx):
    if not ALLOWED_IDS:
        return True
    return ctx.author.id in ALLOWED_IDS


def read_status():
    """Baca status.json yang ditulis oleh main.py."""
    try:
        if os.path.exists(STATUS_FILE):
            with open(STATUS_FILE, "r") as f:
                return json.load(f)
    except:
        pass
    return []


def build_status_embed(title="📊 Status Akun", color=discord.Color.blue()):
    accounts = read_status()
    embed = discord.Embed(title=title, color=color,
                          timestamp=discord.utils.utcnow())

    if not accounts:
        embed.description = "Tidak ada data status. Pastikan auto-rejoin sudah berjalan."
        return embed

    for acc in accounts:
        name   = acc.get("name", "?")
        status = acc.get("status", "?")

        if any(x in status for x in ["Online", "Launched"]):
            icon = "🟢"
        elif any(x in status for x in ["Restarting", "Waiting", "Starting", "Clearing", "Killing", "Graphics", "Muting"]):
            icon = "🟡"
        elif any(x in status for x in ["Error", "Failed", "Crash"]):
            icon = "🔴"
        else:
            icon = "⚪"

        embed.add_field(name=f"{icon} {name}", value=f"`{status}`", inline=False)

    running = rejoin_process is not None and rejoin_process.poll() is None
    embed.set_footer(text=f"Auto-Rejoin: {'🟢 Berjalan' if running else '🔴 Berhenti'}")
    return embed


# ─── EVENT ───────────────────────────────────────────────────

@bot.event
async def on_ready():
    print(f"[BOT] Login sebagai {bot.user} (ID: {bot.user.id})")
    await bot.change_presence(
        activity=discord.Activity(
            type=discord.ActivityType.watching,
            name="Roblox Auto-Rejoin"
        )
    )


@bot.event
async def on_command_error(ctx, error):
    if isinstance(error, commands.CommandNotFound):
        return
    await ctx.send(f"❌ Error: `{error}`")


# ─── COMMANDS ────────────────────────────────────────────────

@bot.command(name="start")
async def cmd_start(ctx):
    """Jalankan auto-rejoin."""
    global rejoin_process

    if not is_allowed(ctx):
        await ctx.send("⛔ Kamu tidak punya izin.")
        return

    # Cek kalau sudah jalan
    if rejoin_process is not None and rejoin_process.poll() is None:
        await ctx.send("⚠️ Auto-rejoin **sudah berjalan**. Ketik `!status` untuk cek.")
        return

    if not os.path.exists(MAIN_PY_PATH):
        await ctx.send(f"❌ `main.py` tidak ditemukan di:\n`{MAIN_PY_PATH}`")
        return

    await ctx.send("🚀 Memulai **Auto-Rejoin**...")

    try:
        # Jalankan main.py dengan input otomatis pilih menu "2" (Start Rejoin App)
        rejoin_process = subprocess.Popen(
            ["su", "-c", f"echo 2 | python {MAIN_PY_PATH}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid
        )
        time.sleep(2)

        if rejoin_process.poll() is None:
            embed = discord.Embed(
                title="✅ Auto-Rejoin Dimulai",
                description=f"PID: `{rejoin_process.pid}`\nGunakan `!status` untuk memantau.",
                color=discord.Color.green()
            )
            await ctx.send(embed=embed)
        else:
            await ctx.send("❌ Proses langsung berhenti. Cek apakah `config.json` sudah dibuat.")
    except Exception as e:
        await ctx.send(f"❌ Gagal memulai: `{e}`")


@bot.command(name="stop")
async def cmd_stop(ctx):
    """Stop auto-rejoin."""
    global rejoin_process

    if not is_allowed(ctx):
        await ctx.send("⛔ Kamu tidak punya izin.")
        return

    if rejoin_process is None or rejoin_process.poll() is not None:
        await ctx.send("⚠️ Auto-rejoin **tidak sedang berjalan**.")
        return

    try:
        os.killpg(os.getpgid(rejoin_process.pid), signal.SIGTERM)
        rejoin_process = None
        await ctx.send("🛑 Auto-rejoin **dihentikan**.")
    except Exception as e:
        await ctx.send(f"❌ Gagal menghentikan: `{e}`")


@bot.command(name="status")
async def cmd_status(ctx):
    """Lihat status semua akun."""
    if not is_allowed(ctx):
        await ctx.send("⛔ Kamu tidak punya izin.")
        return

    embed = build_status_embed()
    await ctx.send(embed=embed)


@bot.command(name="restart")
async def cmd_restart(ctx):
    """Restart auto-rejoin (stop lalu start ulang)."""
    global rejoin_process

    if not is_allowed(ctx):
        await ctx.send("⛔ Kamu tidak punya izin.")
        return

    await ctx.send("🔄 Merestart **Auto-Rejoin**...")

    # Stop dulu kalau masih jalan
    if rejoin_process is not None and rejoin_process.poll() is None:
        try:
            os.killpg(os.getpgid(rejoin_process.pid), signal.SIGTERM)
            rejoin_process = None
            time.sleep(2)
        except Exception as e:
            await ctx.send(f"⚠️ Gagal stop proses lama: `{e}`")

    # Start ulang
    if not os.path.exists(MAIN_PY_PATH):
        await ctx.send(f"❌ `main.py` tidak ditemukan di:\n`{MAIN_PY_PATH}`")
        return

    try:
        rejoin_process = subprocess.Popen(
            ["su", "-c", f"echo 2 | python {MAIN_PY_PATH}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid
        )
        time.sleep(2)

        if rejoin_process.poll() is None:
            embed = discord.Embed(
                title="✅ Auto-Rejoin Direstart",
                description=f"PID baru: `{rejoin_process.pid}`\nGunakan `!status` untuk memantau.",
                color=discord.Color.green()
            )
            await ctx.send(embed=embed)
        else:
            await ctx.send("❌ Proses langsung berhenti setelah restart.")
    except Exception as e:
        await ctx.send(f"❌ Gagal start ulang: `{e}`")


@bot.command(name="help")
async def cmd_help(ctx):
    """Tampilkan daftar perintah."""
    embed = discord.Embed(
        title="🍪 Roblox Auto-Rejoin Bot",
        description="Daftar perintah yang tersedia:",
        color=discord.Color.blurple()
    )
    embed.add_field(name="`!start`",   value="Jalankan auto-rejoin",        inline=False)
    embed.add_field(name="`!stop`",    value="Hentikan auto-rejoin",         inline=False)
    embed.add_field(name="`!restart`", value="Restart ulang auto-rejoin",    inline=False)
    embed.add_field(name="`!status`",  value="Lihat status semua akun",      inline=False)
    embed.add_field(name="`!help`",    value="Tampilkan pesan ini",          inline=False)
    await ctx.send(embed=embed)


# ─── RUN ─────────────────────────────────────────────────────
if __name__ == "__main__":
    if BOT_TOKEN == "ISI_TOKEN_BOT_DISCORD_KAMU":
        print("❌ Isi BOT_TOKEN dulu di dalam bot.py!")
        sys.exit(1)
    bot.run(BOT_TOKEN)
