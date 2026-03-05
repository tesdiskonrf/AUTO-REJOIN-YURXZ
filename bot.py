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

rejoin_process = None


def is_allowed(user_id):
    if not ALLOWED_IDS:
        return True
    return user_id in ALLOWED_IDS


def read_status():
    try:
        if os.path.exists(STATUS_FILE):
            with open(STATUS_FILE, "r") as f:
                return json.load(f)
    except:
        pass
    return []


def build_status_embed():
    accounts = read_status()
    running = rejoin_process is not None and rejoin_process.poll() is None
    color = discord.Color.green() if running else discord.Color.red()
    embed = discord.Embed(
        title="🍪 Roblox Auto-Rejoin",
        color=color,
        timestamp=discord.utils.utcnow()
    )
    if not accounts:
        embed.description = "Tidak ada data. Tekan **▶️ Start** untuk mulai."
    else:
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
    embed.set_footer(text=f"Status: {'🟢 Berjalan' if running else '🔴 Berhenti'}")
    return embed


def make_buttons(running=False):
    view = discord.ui.View(timeout=None)
    view.add_item(discord.ui.Button(label="Start",   emoji="▶️", style=discord.ButtonStyle.success,   custom_id="btn_start",   disabled=running))
    view.add_item(discord.ui.Button(label="Stop",    emoji="⏹️", style=discord.ButtonStyle.danger,    custom_id="btn_stop",    disabled=not running))
    view.add_item(discord.ui.Button(label="Restart", emoji="🔄", style=discord.ButtonStyle.primary,   custom_id="btn_restart"))
    view.add_item(discord.ui.Button(label="Refresh", emoji="📊", style=discord.ButtonStyle.secondary, custom_id="btn_status"))
    return view


async def do_start():
    global rejoin_process
    if rejoin_process is not None and rejoin_process.poll() is None:
        return False, "⚠️ Auto-rejoin sudah berjalan!"
    if not os.path.exists(MAIN_PY_PATH):
        return False, "❌ main.py tidak ditemukan!"
    try:
        rejoin_process = subprocess.Popen(
            ["su", "-c", f"echo 2 | python {MAIN_PY_PATH}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setsid
        )
        time.sleep(2)
        if rejoin_process.poll() is None:
            return True, f"✅ Auto-Rejoin dimulai! PID: `{rejoin_process.pid}`"
        else:
            return False, "❌ Proses berhenti. Cek config.json."
    except Exception as e:
        return False, f"❌ Error: `{e}`"


async def do_stop():
    global rejoin_process
    if rejoin_process is None or rejoin_process.poll() is not None:
        return False, "⚠️ Auto-rejoin tidak sedang berjalan."
    try:
        os.killpg(os.getpgid(rejoin_process.pid), signal.SIGTERM)
        rejoin_process = None
        return True, "🛑 Auto-rejoin dihentikan."
    except Exception as e:
        return False, f"❌ Error: `{e}`"


async def do_restart():
    global rejoin_process
    if rejoin_process is not None and rejoin_process.poll() is None:
        try:
            os.killpg(os.getpgid(rejoin_process.pid), signal.SIGTERM)
            rejoin_process = None
            time.sleep(2)
        except:
            pass
    ok, msg = await do_start()
    return ok, f"🔄 Restart: {msg}"


@bot.event
async def on_ready():
    print(f"[BOT] Login sebagai {bot.user} (ID: {bot.user.id})")
    await bot.change_presence(activity=discord.Activity(type=discord.ActivityType.watching, name="Roblox Auto-Rejoin"))


@bot.event
async def on_interaction(interaction: discord.Interaction):
    if interaction.type != discord.InteractionType.component:
        return
    if not is_allowed(interaction.user.id):
        await interaction.response.send_message("⛔ Kamu tidak punya izin!", ephemeral=True)
        return
    custom_id = interaction.data.get("custom_id", "")

    if custom_id == "btn_start":
        await interaction.response.defer()
        ok, msg = await do_start()
    elif custom_id == "btn_stop":
        await interaction.response.defer()
        ok, msg = await do_stop()
    elif custom_id == "btn_restart":
        await interaction.response.defer()
        ok, msg = await do_restart()
    elif custom_id == "btn_status":
        await interaction.response.defer()
        ok, msg = True, "📊 Status diperbarui!"
    else:
        return

    running = rejoin_process is not None and rejoin_process.poll() is None
    embed = build_status_embed()
    embed.add_field(name="Aksi", value=msg, inline=False)
    await interaction.edit_original_response(embed=embed, view=make_buttons(running))


@bot.command(name="panel")
async def cmd_panel(ctx):
    """Tampilkan panel kontrol dengan button."""
    if not is_allowed(ctx.author.id): await ctx.send("⛔ No permission."); return
    running = rejoin_process is not None and rejoin_process.poll() is None
    await ctx.send(embed=build_status_embed(), view=make_buttons(running))


@bot.command(name="start")
async def cmd_start(ctx):
    if not is_allowed(ctx.author.id): await ctx.send("⛔ No permission."); return
    ok, msg = await do_start()
    running = rejoin_process is not None and rejoin_process.poll() is None
    embed = build_status_embed()
    embed.add_field(name="Aksi", value=msg, inline=False)
    await ctx.send(embed=embed, view=make_buttons(running))


@bot.command(name="stop")
async def cmd_stop(ctx):
    if not is_allowed(ctx.author.id): await ctx.send("⛔ No permission."); return
    ok, msg = await do_stop()
    embed = build_status_embed()
    embed.add_field(name="Aksi", value=msg, inline=False)
    await ctx.send(embed=embed, view=make_buttons(False))


@bot.command(name="restart")
async def cmd_restart(ctx):
    if not is_allowed(ctx.author.id): await ctx.send("⛔ No permission."); return
    ok, msg = await do_restart()
    running = rejoin_process is not None and rejoin_process.poll() is None
    embed = build_status_embed()
    embed.add_field(name="Aksi", value=msg, inline=False)
    await ctx.send(embed=embed, view=make_buttons(running))


@bot.command(name="status")
async def cmd_status(ctx):
    if not is_allowed(ctx.author.id): await ctx.send("⛔ No permission."); return
    running = rejoin_process is not None and rejoin_process.poll() is None
    await ctx.send(embed=build_status_embed(), view=make_buttons(running))


@bot.command(name="help")
async def cmd_help(ctx):
    embed = discord.Embed(title="🍪 Roblox Auto-Rejoin Bot", description="Gunakan `!panel` untuk panel tombol, atau command manual:", color=discord.Color.blurple())
    embed.add_field(name="`!panel`",   value="Panel kontrol dengan tombol", inline=False)
    embed.add_field(name="`!start`",   value="Jalankan auto-rejoin",        inline=False)
    embed.add_field(name="`!stop`",    value="Hentikan auto-rejoin",         inline=False)
    embed.add_field(name="`!restart`", value="Restart ulang",                inline=False)
    embed.add_field(name="`!status`",  value="Lihat status akun",            inline=False)
    await ctx.send(embed=embed)


if __name__ == "__main__":
    if BOT_TOKEN == "ISI_TOKEN_BOT_DISCORD_KAMU":
        print("❌ Isi BOT_TOKEN dulu di dalam bot.py!")
        sys.exit(1)
    bot.run(BOT_TOKEN)
            
