#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║         🍪 Roblox Auto-Rejoin — ONE FILE SETUP          ║
# ║                                                          ║
# ║  Cara pakai:                                             ║
# ║  1. Taruh file ini di /sdcard/                           ║
# ║  2. Buka Termux                                          ║
# ║  3. Ketik: bash /sdcard/setup.sh                         ║
# ║  4. Ikuti instruksi di layar                             ║
# ╚══════════════════════════════════════════════════════════╝

DIR="/sdcard/Auto-Rejoin"
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"; BOLD="\033[1m"

clear
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║   🍪 Roblox Auto-Rejoin Setup Wizard    ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ─── STEP 1: Storage permission ──────────────────────────────
echo -e "${YELLOW}[1/6] Setup storage permission...${RESET}"
if [ ! -d "/sdcard/Download" ]; then
    termux-setup-storage
    echo "    Izinkan akses storage, lalu tunggu 3 detik..."
    sleep 3
else
    echo -e "${GREEN}    ✓ Storage sudah OK${RESET}"
fi

# ─── STEP 2: Install packages ────────────────────────────────
echo ""
echo -e "${YELLOW}[2/6] Install dependencies...${RESET}"
pkg update -y -q 2>/dev/null
pkg install -y python git -q 2>/dev/null
pip install requests discord.py -q 2>/dev/null
echo -e "${GREEN}    ✓ Python, requests, discord.py siap${RESET}"

# ─── STEP 3: Buat folder project ─────────────────────────────
echo ""
echo -e "${YELLOW}[3/6] Membuat folder project di $DIR...${RESET}"
mkdir -p "$DIR"
echo -e "${GREEN}    ✓ Folder siap${RESET}"

# ─── STEP 4: Input dari user ─────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║            ⚙️  KONFIGURASI               ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# Cookie
echo -e "${BOLD}🍪 Roblox Cookie (.ROBLOSECURITY)${RESET}"
echo "   Bisa diisi nanti jika belum punya (tool akan auto-extract)"
echo -n "   Paste cookie (Enter untuk skip): "
read ROBLOX_COOKIE

# PS Link
echo ""
echo -e "${BOLD}🔗 Private Server Link${RESET}"
echo "   Contoh: https://www.roblox.com/share?code=XXXXX&type=Server"
echo -n "   Paste PS Link: "
read PS_LINK

# User ID
echo ""
echo -e "${BOLD}🆔 Roblox User ID${RESET}"
echo "   Lihat di URL profil Roblox kamu"
echo -n "   User ID: "
read USER_ID

# Discord Bot Token
echo ""
echo -e "${BOLD}🤖 Discord Bot Token${RESET}"
echo "   Buat di: discord.com/developers/applications"
echo -n "   Bot Token: "
read BOT_TOKEN

# Discord User ID (untuk whitelist)
echo ""
echo -e "${BOLD}🔐 Discord User ID kamu (untuk keamanan bot)${RESET}"
echo "   Setting > Tampilan > Mode Developer ON, lalu klik kanan nama kamu"
echo -n "   Discord User ID: "
read DISCORD_ID

# Webhook (opsional)
echo ""
echo -e "${BOLD}📢 Discord Webhook URL (opsional, Enter untuk skip)${RESET}"
echo -n "   Webhook URL: "
read WEBHOOK_URL

# ─── STEP 5: Generate semua file ─────────────────────────────
echo ""
echo -e "${YELLOW}[4/6] Membuat file konfigurasi...${RESET}"

# config.json
cat > "$DIR/config.json" <<CONFIGEOF
{
  "check_interval": 30,
  "restart_delay": 15,
  "webhook_url": "${WEBHOOK_URL}",
  "accounts": [
    {
      "name": "Akun1",
      "user_id": ${USER_ID:-0},
      "package": "com.roblox.client",
      "roblox_cookie": "${ROBLOX_COOKIE}",
      "ps_link": "${PS_LINK}"
    }
  ]
}
CONFIGEOF
echo -e "${GREEN}    ✓ config.json dibuat${RESET}"

# ─── main.py ─────────────────────────────────────────────────
cat > "$DIR/main.py" <<'MAINEOF'
import os,sys,json,sqlite3,subprocess,requests,time,math,re
from pathlib import Path

CONFIG_FILE="config.json"
WHITELIST_PACKAGES=['com.termux','com.termux.boot','com.android.systemui','com.android.system','com.android.phone','com.android.settings','android','com.android.launcher','com.android.launcher3','com.miui.home','com.samsung.android.app.spage','com.huawei.android.launcher','com.android.inputmethod','com.google.android.inputmethod','com.android.bluetooth','com.android.nfc','com.android.wifi']

def clear_screen(): print("\033[H\033[2J",end=""); sys.stdout.flush()
def print_header():
    print("\n"+"="*50)
    print("  🍪 Roblox Auto-Rejoin Tool")
    print("="*50+"\n")
def check_root():
    try: return subprocess.run(['su','-c','id'],capture_output=True,timeout=5).returncode==0
    except: return False
def run_root_cmd(cmd):
    try:
        r=subprocess.run(['su','-c',cmd],capture_output=True,text=True,timeout=10)
        return r.returncode==0,((r.stdout or '')+'\n'+(r.stderr or '')).strip()
    except Exception as e: return False,str(e)

def kill_background_apps(roblox_packages):
    ok,output=run_root_cmd('pm list packages -3')
    if not ok or not output: return 0
    killed=0
    for line in output.splitlines():
        if 'package:' not in line: continue
        pkg=line.replace('package:','').strip()
        if pkg in roblox_packages: continue
        skip=any(pkg.startswith(w) or w in pkg for w in WHITELIST_PACKAGES)
        if skip: continue
        ok2,pid=run_root_cmd(f'pidof {pkg}')
        if ok2 and pid.strip():
            run_root_cmd(f'am force-stop {pkg}'); killed+=1
    log_activity(f"Killed {killed} background apps","INFO")
    return killed

def clear_roblox_cache(package_name):
    for cmd in [f'pm clear --cache-only {package_name}',f'rm -rf /data/data/{package_name}/cache/*',f'rm -rf /data/data/{package_name}/code_cache/*']:
        run_root_cmd(cmd)
    log_activity(f"Cache cleared for {package_name}","INFO")

def set_roblox_graphics_minimum(package_name):
    base=f"/data/data/{package_name}/shared_prefs"
    ok,output=run_root_cmd(f'find {base} -type f -name "*.xml" 2>/dev/null')
    if not ok or not output: return
    target=next((l.strip() for l in output.splitlines() if any(x in l for x in ['GlobalBasicSettings','RobloxSettings','AppSettings'])),output.splitlines()[0].strip())
    temp="/sdcard/roblox_gfx_temp.xml"
    ok,_=run_root_cmd(f'cp "{target}" "{temp}" && chmod 666 "{temp}"')
    if not ok: return
    try:
        content=open(temp,'r',encoding='utf-8',errors='ignore').read()
        for pattern,repl in [
            (r'(<string name="GraphicsQualityLevel">)[^<]*(</string>)',r'\g<1>1\g<2>'),
            (r'(<int name="GraphicsQualityLevel" value=")[^"]*(")',r'\g<1>1\g<2>'),
            (r'(<string name="SavedQualityLevel">)[^<]*(</string>)',r'\g<1>1\g<2>'),
            (r'(<string name="RenderingScaleFactor">)[^<]*(</string>)',r'\g<1>0.5\g<2>'),
            (r'(<float name="RenderingScaleFactor" value=")[^"]*(")',r'\g<1>0.5\g<2>'),
        ]: content=re.sub(pattern,repl,content)
        open(temp,'w',encoding='utf-8').write(content)
        run_root_cmd(f'cp "{temp}" "{target}" && chmod 660 "{target}"')
    except: pass
    run_root_cmd(f'rm "{temp}"')

def set_roblox_audio_mute(package_name):
    base=f"/data/data/{package_name}/shared_prefs"
    ok,output=run_root_cmd(f'find {base} -type f -name "*.xml" 2>/dev/null')
    if not ok or not output: return
    target=next((l.strip() for l in output.splitlines() if any(x in l for x in ['GlobalBasicSettings','RobloxSettings','AppSettings'])),output.splitlines()[0].strip())
    temp="/sdcard/roblox_audio_temp.xml"
    ok,_=run_root_cmd(f'cp "{target}" "{temp}" && chmod 666 "{temp}"')
    if not ok: return
    try:
        content=open(temp,'r',encoding='utf-8',errors='ignore').read()
        for pattern,repl in [
            (r'(<string name="MasterVolume">)[^<]*(</string>)',r'\g<1>0\g<2>'),
            (r'(<float name="MasterVolume" value=")[^"]*(")',r'\g<1>0\g<2>'),
            (r'(<string name="MusicVolume">)[^<]*(</string>)',r'\g<1>0\g<2>'),
            (r'(<float name="MusicVolume" value=")[^"]*(")',r'\g<1>0\g<2>'),
            (r'(<string name="SoundEffectVolume">)[^<]*(</string>)',r'\g<1>0\g<2>'),
            (r'(<float name="SoundEffectVolume" value=")[^"]*(")',r'\g<1>0\g<2>'),
        ]: content=re.sub(pattern,repl,content)
        open(temp,'w',encoding='utf-8').write(content)
        run_root_cmd(f'cp "{temp}" "{target}" && chmod 660 "{target}"')
    except: pass
    run_root_cmd(f'rm "{temp}"')

def check_package_installed(pkg): ok,out=run_root_cmd('pm list packages'); return ok and pkg in out
def find_roblox_packages():
    browsers={}; ok,out=run_root_cmd('pm list packages')
    if ok:
        for line in out.splitlines():
            if 'com.roblox' in line and 'package:' in line:
                pkg=line.replace('package:','').strip(); browsers[f"Roblox ({pkg})"]=pkg
    if not browsers: browsers['Roblox App']='com.roblox.client'
    installed={}
    for name,package in browsers.items():
        if check_package_installed(package): installed[name]=package
    return installed

def find_cookie_databases(package_name):
    base=f"/data/data/{package_name}"; found=[]
    for cmd in [f'find {base} -type f -name "Cookies" 2>/dev/null',f'find {base} -type f -name "cookies.sqlite" 2>/dev/null',f'find {base} -type f -name "*cookie*" 2>/dev/null']:
        ok,out=run_root_cmd(cmd)
        if ok and out:
            for p in out.split('\n'):
                p=p.strip()
                if p and p not in found and not p.endswith('-journal') and not p.endswith('.tmp'): found.append(p)
    return found

def copy_database(db,tmp): ok,_=run_root_cmd(f'cp "{db}" "{tmp}" && chmod 666 "{tmp}"'); return ok

def extract_cookie_chromium(db_path):
    tmp="/sdcard/tmp_chr.db"
    if not copy_database(db_path,tmp): return None
    try:
        import sqlite3; conn=sqlite3.connect(tmp); cur=conn.cursor()
        try: cur.execute("SELECT name,value FROM cookies WHERE host_key LIKE '%roblox.com%' AND name='.ROBLOSECURITY'"); r=cur.fetchone()
        except:
            try: cur.execute("SELECT name,value FROM cookies WHERE name='.ROBLOSECURITY'"); r=cur.fetchone()
            except: r=None
        conn.close(); run_root_cmd(f'rm "{tmp}"')
        return r[1] if r and len(r)>1 else (r[0] if r else None)
    except: run_root_cmd(f'rm "{tmp}"'); return None

def extract_cookie_firefox(db_path):
    tmp="/sdcard/tmp_fox.db"
    if not copy_database(db_path,tmp): return None
    try:
        import sqlite3; conn=sqlite3.connect(tmp); cur=conn.cursor()
        cur.execute("SELECT name,value FROM moz_cookies WHERE host LIKE '%roblox.com%' AND name='.ROBLOSECURITY'"); r=cur.fetchone()
        conn.close(); run_root_cmd(f'rm "{tmp}"')
        return r[1] if r else None
    except: run_root_cmd(f'rm "{tmp}"'); return None

def get_user_info(cookie):
    try:
        r=requests.get("https://users.roblox.com/v1/users/authenticated",cookies={".ROBLOSECURITY":cookie},timeout=5)
        if r.status_code==200: d=r.json(); return d.get('id'),d.get('name')
    except: pass
    return None,None

def get_current_resolution():
    for cmd,pattern in [("dumpsys window displays",r"cur=(\d+)x(\d+)"),("wm size",r"(\d+)x(\d+)")]:
        ok,out=run_root_cmd(cmd)
        if ok and out:
            m=re.search(pattern,out)
            if m: return int(m.group(1)),int(m.group(2))
    return 1080,2400

def get_grid_bounds(index,total,sw,sh):
    cols=math.ceil(math.sqrt(total)); rows=math.ceil(total/cols)
    if sw>sh:
        while cols<rows: cols+=1; rows=math.ceil(total/cols)
    cw=sw//cols; ch=sh//rows; idx=index-1; r=idx//cols; c=idx%cols
    return f"{c*cw},{r*ch},{(c+1)*cw},{(r+1)*ch}"

def get_memory_info():
    try:
        content=open("/proc/meminfo").read()
        mt=re.search(r"MemTotal:\s+(\d+)\s+kB",content); ma=re.search(r"MemAvailable:\s+(\d+)\s+kB",content) or re.search(r"MemFree:\s+(\d+)\s+kB",content)
        if mt and ma:
            tot=int(mt.group(1)); av=int(ma.group(1)); return f"{av//1024}MB",int((av/tot)*100)
    except: pass
    return "N/A",0

def draw_ui(accounts,sys_status,check_prog,next_wh=""):
    sys.stdout.write("\033[2J\033[H\033[?25l")
    C0,CC,CG,CY,CR,CGR="\033[0m","\033[36m","\033[32m","\033[33m","\033[31m","\033[90m"
    mem,mp=get_memory_info(); cols=65; c1=34; c2=cols-4-c1
    def trunc(s,l): s=str(s).replace('\n','').replace('\r',''); return s[:l-1]+"." if len(s)>l else s
    def sep(l,m,r,c='─'): sys.stdout.write(f"{CC}{l}{c*(c1+1)}{m}{c*(c2+1)}{r}{C0}\n")
    def row(t1,t2,col=C0): sys.stdout.write(f"{CC}│{C0} {trunc(t1,c1):<{c1}}{CC}│{C0} {col}{trunc(t2,c2):<{c2}}{C0}{CC}│{C0}\n")
    sep('┌','┬','┐'); row("PACKAGE","STATUS"); sep('├','┼','┤')
    st=check_prog if check_prog else sys_status
    if next_wh: st+=f" | {next_wh}"
    row("System",st or "Idle",CY); row("Memory",f"Free: {mem} ({mp}%)",CGR); sep('├','┼','┤')
    for a in accounts:
        s=a.get('status','Unknown'); c=CG
        if any(x in s for x in ['Restarting','Initializing','Waiting','Graphics','Audio','Cache','Killing']): c=CY
        elif any(x in s for x in ['Error','Stopped','Failed']): c=CR
        elif 'Checking' in s: c=CGR
        row(f"{a['package']} ({a.get('name','?')})",s,c)
    sep('└','┴','┘'); sys.stdout.flush()

def is_roblox_running(pkg):
    ok,out=run_root_cmd(f"pidof {pkg}")
    if ok and out.strip(): return True
    ok,out=run_root_cmd(f"ps -A | grep {pkg}")
    return ok and bool(out.strip())

def check_user_presence(uid,cookie):
    try:
        r=requests.post("https://presence.roblox.com/v1/presence/users",json={'userIds':[uid]},cookies={".ROBLOSECURITY":cookie} if cookie else {},headers={'User-Agent':'Mozilla/5.0'},timeout=5)
        if r.status_code==200 and r.json().get('userPresences'):
            p=r.json()['userPresences'][0]; return (p.get('userPresenceType')==2),p.get('gameId')
    except: pass
    return True,None

def open_ps_link(link,pkg,bounds=None):
    def try_launch(extras=""):
        for cmd in [f'am start {extras} -n {pkg}/com.roblox.client.ActivityProtocolLaunch -a android.intent.action.VIEW -d "{link}"',f'am start {extras} -a android.intent.action.VIEW -d "{link}" -p {pkg}']:
            ok,o=run_root_cmd(cmd)
            if ok and "Error:" not in o and "does not exist" not in o: return True
        return False
    if bounds and try_launch(f"--windowingMode 5 --bounds {bounds}"): return True
    return try_launch("")

def log_activity(msg,lvl="INFO"):
    try:
        with open("activity.log","a") as f: f.write(f"[{time.strftime('%H:%M:%S')}] [{lvl}] {msg}\n")
    except: pass

def send_webhook(webhook_url,accounts):
    if not webhook_url: return
    tmp="/data/local/tmp/screen.png"; local=os.path.join(os.getcwd(),"screen.png")
    ok,_=run_root_cmd(f"screencap -p {tmp} && cp {tmp} {local} && chmod 666 {local}")
    fields=[{"name":f"{a.get('name','?')} | {a.get('package','?')}","value":f"**Status:** {a.get('status','?')}","inline":False} for a in accounts]
    payload={"embeds":[{"title":"Roblox Account Status","color":3447003,"fields":fields,"timestamp":time.strftime("%Y-%m-%dT%H:%M:%SZ",time.gmtime())}]}
    files={}
    if ok and os.path.exists(local):
        f=open(local,"rb"); files["file"]=("screen.png",f,"image/png"); payload["embeds"][0]["image"]={"url":"attachment://screen.png"}
    try:
        if files: requests.post(webhook_url,data={"payload_json":json.dumps(payload)},files=files,timeout=15)
        else: requests.post(webhook_url,json=payload,timeout=10)
    except: pass
    finally:
        if "file" in files: files["file"][1].close()

def start_rejoin_app():
    if not os.path.exists(CONFIG_FILE): print("Config not found!"); time.sleep(2); return
    if not check_root(): print("Root required!"); time.sleep(2); return
    with open(CONFIG_FILE) as f: config=json.load(f)
    accounts_cfg=config.get("accounts",[])
    if not accounts_cfg: print("No accounts!"); time.sleep(2); return
    clear_screen(); run_root_cmd("setenforce 0")
    interval=config.get("check_interval",30); restart_delay=config.get("restart_delay",15); wh_url=config.get("webhook_url","")
    sw,sh=get_current_resolution(); tot=len(accounts_cfg)
    roblox_pkgs=set(a.get('package','') for a in accounts_cfg)
    accounts=[{'index':i+1,'name':a.get('name',f"User {a.get('user_id')}"),'user_id':a.get('user_id'),'package':a.get('package'),'cookie':a.get('roblox_cookie'),'ps_link':a.get('ps_link'),'status':'Pending','expected_game':None} for i,a in enumerate(accounts_cfg)]
    draw_ui(accounts,"Killing BG Apps...","")
    kill_background_apps(roblox_pkgs); time.sleep(1)
    for i,acc in enumerate(accounts):
        acc['status']='Starting...'; draw_ui(accounts,"Launching",f"[{i+1}/{tot}]")
        run_root_cmd(f"am force-stop {acc['package']}"); time.sleep(1)
        bounds=get_grid_bounds(acc['index'],tot,sw,sh)
        acc['status']='Launched (Wait)' if open_ps_link(acc['ps_link'],acc['package'],bounds) else 'Launch Failed'
        if i<tot-1:
            for t in range(restart_delay,0,-1): draw_ui(accounts,"Launching",f"Next in {t}s"); time.sleep(1)
    for t in range(10,0,-1): draw_ui(accounts,"Initializing",f"Wait {t}s"); time.sleep(1)
    for a in accounts:
        ingame,gid=check_user_presence(a['user_id'],a['cookie']); a['expected_game']=gid; a['status']="Online" if gid else "Waiting Game"
    last_wh=time.time()
    try:
        while True:
            nxt_wh=""
            if wh_url:
                diff=int(600-(time.time()-last_wh))
                if diff<=0: send_webhook(wh_url,accounts); last_wh=time.time(); diff=600
                nxt_wh=f"WH in {diff//60}m"
            for i,a in enumerate(accounts):
                draw_ui(accounts,"Monitoring",f"Check [{i+1}/{tot}]",nxt_wh)
                if not is_roblox_running(a['package']): needs,reason=True,"App closed"
                else:
                    ingame,cg=check_user_presence(a['user_id'],a['cookie'])
                    if not ingame: needs,reason=True,"Not in game"
                    elif a['expected_game'] and cg and str(cg)!=str(a['expected_game']): needs,reason=True,"Server switch"
                    else: needs,reason=False,""; a['expected_game']=cg or a['expected_game']
                if needs:
                    log_activity(f"{a['name']}: {reason}","WARN"); a['status']=f"Crash: {reason}"
                    if wh_url: send_webhook(wh_url,accounts)
                    for label,fn in [("Killing BG...",lambda: kill_background_apps(roblox_pkgs)),("Clearing Cache...",lambda: clear_roblox_cache(a['package'])),("Set Graphics...",lambda: set_roblox_graphics_minimum(a['package'])),("Muting Audio...",lambda: set_roblox_audio_mute(a['package']))]:
                        a['status']=label; draw_ui(accounts,"Monitoring",f"Prep {a['name']}",nxt_wh); fn()
                    time.sleep(1); a['status']="Restarting..."; draw_ui(accounts,"Monitoring",f"Fix {a['name']}",nxt_wh)
                    run_root_cmd(f"am force-stop {a['package']}"); time.sleep(2)
                    open_ps_link(a['ps_link'],a['package'],get_grid_bounds(a['index'],tot,sw,sh))
                    for t in range(25,0,-1): a['status']=f"Wait ({t}s)"; draw_ui(accounts,"Monitoring","Wait Launch",nxt_wh); time.sleep(1)
                    a['status']="Online"; a['expected_game']=None
                else: a['status']="Online"
            with open("status.json","w") as f: json.dump([{'name':x['name'],'status':x['status']} for x in accounts],f)
            for t in range(interval,0,-1): draw_ui(accounts,"Idle",f"Next Check: {t}s",nxt_wh); time.sleep(1)
    except KeyboardInterrupt: pass
    finally: sys.stdout.write("\033[?25h")

def main():
    while True:
        clear_screen(); print_header()
        print("  1. Create Config\n  2. Start Rejoin App\n  3. Exit\n"+"="*50)
        c=input("\nSelect: ").strip()
        if c=='1':
            # Auto-extract cookie
            if not check_root(): print("❌ Root required!"); input("Enter..."); continue
            pkgs=find_roblox_packages()
            if not pkgs: print("❌ Roblox not found!"); input("Enter..."); continue
            for name,pkg in pkgs.items():
                dbs=find_cookie_databases(pkg)
                for db in dbs:
                    cookie=extract_cookie_firefox(db) if 'firefox' in pkg else extract_cookie_chromium(db)
                    if cookie:
                        uid,uname=get_user_info(cookie)
                        if uid:
                            cfg=json.load(open(CONFIG_FILE)) if os.path.exists(CONFIG_FILE) else {}
                            accs=cfg.get('accounts',[])
                            exists=next((a for a in accs if str(a.get('user_id'))==str(uid)),None)
                            if exists: exists['roblox_cookie']=cookie; exists['name']=uname
                            else: accs.append({'name':uname,'user_id':uid,'package':pkg,'roblox_cookie':cookie,'ps_link':cfg.get('accounts',[{}])[0].get('ps_link','EDIT_PS_LINK')})
                            cfg['accounts']=accs
                            json.dump(cfg,open(CONFIG_FILE,'w'),indent=2)
                            print(f"✅ Cookie updated: {uname} ({uid})")
                        break
            input("\nEnter to continue...")
        elif c=='2': start_rejoin_app()
        elif c=='3': clear_screen(); break

if __name__=="__main__":
    main()
MAINEOF
echo -e "${GREEN}    ✓ main.py dibuat${RESET}"

# ─── bot.py ──────────────────────────────────────────────────
ALLOWED_LINE=""
if [ -n "$DISCORD_ID" ]; then
    ALLOWED_LINE="ALLOWED_IDS = [$DISCORD_ID]"
else
    ALLOWED_LINE="ALLOWED_IDS = []"
fi

cat > "$DIR/bot.py" <<BOTEOF
import discord, subprocess, os, json, time, signal, sys
from discord.ext import commands

BOT_TOKEN    = "${BOT_TOKEN}"
PREFIX       = "!"
${ALLOWED_LINE}
DIR          = os.path.dirname(os.path.abspath(__file__))
MAIN_PY      = os.path.join(DIR, "main.py")
STATUS_FILE  = os.path.join(DIR, "status.json")

intents = discord.Intents.default()
intents.message_content = True
bot = commands.Bot(command_prefix=PREFIX, intents=intents, help_command=None)
rejoin_proc = None

def allowed(ctx): return not ALLOWED_IDS or ctx.author.id in ALLOWED_IDS
def read_status():
    try:
        if os.path.exists(STATUS_FILE):
            return json.load(open(STATUS_FILE))
    except: pass
    return []

def status_embed():
    accounts = read_status()
    running = rejoin_proc is not None and rejoin_proc.poll() is None
    e = discord.Embed(title="📊 Status Akun", color=discord.Color.blue(), timestamp=discord.utils.utcnow())
    if not accounts:
        e.description = "Tidak ada data. Jalankan \`!start\` dulu."
    for a in accounts:
        s = a.get("status","?")
        icon = "🟢" if any(x in s for x in ["Online","Launched"]) else "🟡" if any(x in s for x in ["Restarting","Waiting","Starting","Clearing","Killing","Graphics","Audio"]) else "🔴" if any(x in s for x in ["Error","Failed","Crash"]) else "⚪"
        e.add_field(name=f"{icon} {a.get('name','?')}", value=f"\`{s}\`", inline=False)
    e.set_footer(text=f"Auto-Rejoin: {'🟢 Berjalan' if running else '🔴 Berhenti'}")
    return e

@bot.event
async def on_ready():
    print(f"[BOT] Login: {bot.user}")
    await bot.change_presence(activity=discord.Activity(type=discord.ActivityType.watching, name="Roblox Auto-Rejoin"))

@bot.command(name="start")
async def cmd_start(ctx):
    global rejoin_proc
    if not allowed(ctx): await ctx.send("⛔ No permission."); return
    if rejoin_proc and rejoin_proc.poll() is None: await ctx.send("⚠️ Sudah berjalan! Ketik \`!status\`"); return
    await ctx.send("🚀 Memulai Auto-Rejoin...")
    try:
        rejoin_proc = subprocess.Popen(["su","-c",f"echo 2 | python {MAIN_PY}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, preexec_fn=os.setsid)
        time.sleep(2)
        if rejoin_proc.poll() is None:
            await ctx.send(embed=discord.Embed(title="✅ Auto-Rejoin Dimulai", description=f"PID: \`{rejoin_proc.pid}\`", color=discord.Color.green()))
        else: await ctx.send("❌ Proses berhenti. Cek config.json.")
    except Exception as e: await ctx.send(f"❌ Error: \`{e}\`")

@bot.command(name="stop")
async def cmd_stop(ctx):
    global rejoin_proc
    if not allowed(ctx): await ctx.send("⛔ No permission."); return
    if not rejoin_proc or rejoin_proc.poll() is not None: await ctx.send("⚠️ Tidak sedang berjalan."); return
    try: os.killpg(os.getpgid(rejoin_proc.pid), signal.SIGTERM); rejoin_proc=None; await ctx.send("🛑 Auto-rejoin dihentikan.")
    except Exception as e: await ctx.send(f"❌ Error: \`{e}\`")

@bot.command(name="status")
async def cmd_status(ctx):
    if not allowed(ctx): await ctx.send("⛔ No permission."); return
    await ctx.send(embed=status_embed())

@bot.command(name="restart")
async def cmd_restart(ctx):
    global rejoin_proc
    if not allowed(ctx): await ctx.send("⛔ No permission."); return
    await ctx.send("🔄 Merestart Auto-Rejoin...")
    if rejoin_proc and rejoin_proc.poll() is None:
        try: os.killpg(os.getpgid(rejoin_proc.pid), signal.SIGTERM); rejoin_proc=None; time.sleep(2)
        except: pass
    try:
        rejoin_proc = subprocess.Popen(["su","-c",f"echo 2 | python {MAIN_PY}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, preexec_fn=os.setsid)
        time.sleep(2)
        if rejoin_proc.poll() is None:
            await ctx.send(embed=discord.Embed(title="✅ Direstart", description=f"PID: \`{rejoin_proc.pid}\`", color=discord.Color.green()))
        else: await ctx.send("❌ Gagal restart.")
    except Exception as e: await ctx.send(f"❌ Error: \`{e}\`")

@bot.command(name="help")
async def cmd_help(ctx):
    e = discord.Embed(title="🍪 Roblox Auto-Rejoin Bot", color=discord.Color.blurple())
    for cmd,desc in [("!start","Jalankan auto-rejoin"),("!stop","Hentikan auto-rejoin"),("!restart","Restart ulang"),("!status","Status semua akun"),("!help","Pesan ini")]:
        e.add_field(name=f"\`{cmd}\`", value=desc, inline=False)
    await ctx.send(embed=e)

if __name__ == "__main__":
    if BOT_TOKEN == "ISI_TOKEN_BOT_DISCORD_KAMU": print("❌ Isi BOT_TOKEN dulu!"); sys.exit(1)
    bot.run(BOT_TOKEN)
BOTEOF
echo -e "${GREEN}    ✓ bot.py dibuat${RESET}"

# ─── start.sh ────────────────────────────────────────────────
cat > "$DIR/start.sh" <<'STARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
is_running() { [ -f "$1" ] && kill -0 "$(cat $1)" 2>/dev/null; }
[ -f "$DIR/bot.pid" ] && is_running "$DIR/bot.pid" && kill -TERM "$(cat $DIR/bot.pid)" 2>/dev/null && sleep 1
[ -f "$DIR/main.pid" ] && is_running "$DIR/main.pid" && su -c "kill -TERM $(cat $DIR/main.pid)" 2>/dev/null && sleep 1
nohup python "$DIR/bot.py" > "$DIR/bot.log" 2>&1 & echo $! > "$DIR/bot.pid"
nohup su -c "echo 2 | python $DIR/main.py" > "$DIR/rejoin.log" 2>&1 & echo $! > "$DIR/main.pid"
sleep 2
echo "✅ Bot + Auto-Rejoin berjalan di background"
echo "   Kontrol via Discord: !start !stop !status !restart"
STARTEOF
chmod +x "$DIR/start.sh"
echo -e "${GREEN}    ✓ start.sh dibuat${RESET}"

# ─── STEP 6: Setup Termux:Boot ───────────────────────────────
echo ""
echo -e "${YELLOW}[5/6] Setup auto-start saat boot...${RESET}"
mkdir -p ~/.termux/boot
cat > ~/.termux/boot/autostart.sh <<BOOTEOF
#!/data/data/com.termux/files/usr/bin/bash
sleep 15
bash /sdcard/Auto-Rejoin/start.sh >> /sdcard/Auto-Rejoin/boot.log 2>&1
BOOTEOF
chmod +x ~/.termux/boot/autostart.sh
echo -e "${GREEN}    ✓ Auto-start saat boot aktif${RESET}"

# ─── STEP 7: Langsung jalankan! ──────────────────────────────
echo ""
echo -e "${YELLOW}[6/6] Menjalankan semua program...${RESET}"
cd "$DIR"
bash "$DIR/start.sh"

# ─── DONE ────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║            ✅ SETUP SELESAI!             ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  📁 Folder  : ${BOLD}$DIR${RESET}"
echo -e "  🤖 Bot     : ketik ${BOLD}!start${RESET} di Discord"
echo ""
echo -e "  ${YELLOW}⚠️  Install Termux:Boot dari F-Droid${RESET}"
echo -e "  ${YELLOW}   supaya auto-jalan saat HP restart!${RESET}"
echo ""
echo -e "  Lain kali cukup ketik:"
echo -e "  ${BOLD}bash /sdcard/Auto-Rejoin/start.sh${RESET}"
echo ""
