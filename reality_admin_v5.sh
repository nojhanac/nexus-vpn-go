#!/bin/bash

# ==========================================
# Script Name: Reality Admin v5 (Gaming Edition)
# Description: VLESS Reality with Massive Gaming & Tech List
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفا با دسترسی روت (root) اجرا کنید.${NC}"
  exit
fi

# -----------------------------------------------------------
# بانک اطلاعاتی (Tech + Gaming)
# -----------------------------------------------------------
declare -a HOSTS=(
    # --- Tech Giants (مهم‌ترین‌ها) ---
    "www.microsoft.com"      # 1
    "www.apple.com"          # 2
    "www.google.com"         # 3
    "www.amazon.com"         # 4
    "www.cloudflare.com"     # 5
    "www.oracle.com"         # 6
    "www.ibm.com"            # 7
    "www.cisco.com"          # 8
    
    # --- PC Gaming Platforms (پلتفرم‌های کامپیوتری) ---
    "store.steampowered.com" # 9 (Steam - بهترین برای پینگ)
    "www.epicgames.com"      # 10 (Epic Games)
    "www.ubisoft.com"        # 11 (Ubisoft Connect)
    "ea.com"                 # 12 (EA Games)
    "www.origin.com"         # 13 (Origin)
    "www.blizzard.com"       # 14 (Battle.net)
    "www.gog.com"            # 15 (GOG Galaxy)
    "itch.io"                # 16 (Itch.io)
    "www.discord.com"        # 17 (چت گیمرها - ترافیک بالا)
    
    # --- Console Gaming Brands (برندهای کنسول) ---
    "www.playstation.com"    # 18 (Sony PSN)
    "www.xbox.com"           # 19 (Microsoft Xbox)
    "www.nintendo.com"       # 20 (Nintendo Switch)
    "store.nintendo.com"     # 21 (Nintendo eShop)
    
    # --- Hardware & Peripherals (سخت‌افزار گیمینگ) ---
    "www.nvidia.com"         # 22 (GeForce)
    "www.amd.com"            # 23 (Radeon)
    "www.intel.com"          # 24 (CPUs)
    "www.asus.com"           # 25 (ROG)
    "www.msi.com"            # 26 (Gaming Laptops)
    "www.razersupport.com"   # 27 (Razer)
    "www.logitechg.com"      # 28 (Logitech G)
    
    # --- Popular Online Games (سایت بازی‌های آنلاین) ---
    "www.fortnite.com"       # 29
    "www.leagueoflegends.com"# 30
    "www.minecraft.net"      # 31
    "www.roblox.com"         # 32
    "www.valorantesports.com"# 33
    "www.dota2.com"          # 34
    "csgostats.com"          # 35 (CS:GO/CS2 Related)
    "www.brawlstars.com"     # 36
    "www.clashroyale.com"    # 37
    "www.genshinimpact.com"  # 38
    
    # --- Streaming (استریم گیمینگ) ---
    "www.twitch.tv"          # 39 (Twitch)
    "www.twitchcdn.net"      # 40
    
    # --- Other Tech Giants ---
    "www.mozilla.org"        # 41
    "www.adobe.com"          # 42
    "www.digitalocean.com"   # 43
    "www.atlassian.com"      # 44
    "www.vmware.com"         # 45
    "www.redhat.com"         # 46
    "www.autodesk.com"       # 47
    "www.canon.com"          # 48
    "www.panasonic.com"      # 49
    "www.toshiba.com"        # 50
    "www.lenovo.com"         # 51
    "www.dell.com"           # 52
    "www.hp.com"             # 53
    "www.samsung.com"        # 54
    "www.sony.com"           # 55
    "www.westerndigital.com" # 56 (HDDs)
    "www.seagate.com"        # 57 (HDDs)
)

clear
echo "=========================================="
echo -e "${MAGENTA}  نصب تونل VLESS Reality (Gaming Edition)${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}لیست هاست‌ها (تکنولوژی و گیمینگ):${NC}"
echo "--------------------------------------------------------"

# حلقه چاپ لیست
for i in "${!HOSTS[@]}"; do
    index=$((i + 1))
    host="${HOSTS[$i]}"
    
    # رنگ‌بندی هوشمند
    if [ $index -le 8 ]; then
        # Tech Giants
        printf "${BLUE}%-3d)${NC} %-35s ${GREEN}[Tech]${NC}\n" "$index" "$host"
    elif [ $index -le 21 ] || [ $index -eq 17 ] || [ $index -eq 39 ]; then
        # Gaming Platforms & Streaming
        printf "${MAGENTA}%-3d)${NC} %-35s ${YELLOW}[Gaming]${NC}\n" "$index" "$host"
    elif [ $index -le 28 ]; then
        # Hardware
        printf "${BLUE}%-3d)${NC} %-35s ${CYAN}[Hardware]${NC}\n" "$index" "$host"
    else
        # Others
        printf "${BLUE}%-3d)${NC} %-35s ${CYAN}[Other]${NC}\n" "$index" "$host"
    fi
done

echo "--------------------------------------------------------"
echo -e "${RED}0)  خروج / ورود دستی (Custom SNI)${NC}"
echo ""

read -p "لطفا شماره مورد نظر را انتخاب کنید: " sni_choice

# -----------------------------------------------------------
# پردازش انتخاب
# -----------------------------------------------------------

if [[ "$sni_choice" == "0" ]]; then
    read -p "آدرس کامل (مثلاً www.mysite.com): " SNI
    DEST=$SNI
elif [[ "$sni_choice" =~ ^[0-9]+$ ]] && [ "$sni_choice" -ge 1 ] && [ "$sni_choice" -le ${#HOSTS[@]} ]; then
    index=$((sni_choice - 1))
    SNI="${HOSTS[$index]}"
    DEST=$SNI
else
    echo -e "${RED}انتخاب نامعتبر است. از پیش‌فرض Steam استفاده می‌شود.${NC}"
    SNI="store.steampowered.com"
    DEST="store.steampowered.com"
fi

echo ""
echo -e "${GREEN}✅ هاست انتخاب شد: $SNI${NC}"
echo ""

# -----------------------------------------------------------
# پورت
# -----------------------------------------------------------
read -p "پورت تونل [443]: " PORT
PORT=${PORT:-443}

# -----------------------------------------------------------
# نصب Xray
# -----------------------------------------------------------
echo -e "${CYAN}در حال نصب Xray-core...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

if ! command -v xray &> /dev/null; then
    echo -e "${RED}نصب Xray با خطا مواجه شد!${NC}"
    exit
fi

# -----------------------------------------------------------
# کلیدها
# -----------------------------------------------------------
echo -e "${CYAN}در حال تولید کلیدهای امنیتی...${NC}"
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)
UUID=$(cat /proc/sys/kernel/random/uuid)

# -----------------------------------------------------------
# کانفیگ
# -----------------------------------------------------------
CONFIG_FILE="/usr/local/etc/xray/config.json"

cat <<EOF > $CONFIG_FILE
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$DEST:443",
          "serverNames": [
            "$SNI"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# فایروال
if command -v ufw &> /dev/null; then ufw allow $PORT/tcp > /dev/null 2>&1; fi
if command -v firewall-cmd &> /dev/null; then firewall-cmd --permanent --add-port=$PORT/tcp > /dev/null 2>&1; firewall-cmd --reload > /dev/null 2>&1; fi

# سرویس
systemctl restart xray
systemctl enable xray

# -----------------------------------------------------------
# خروجی
# -----------------------------------------------------------
SERVER_IP=$(curl -s -4 ip.sb)

clear
echo "=========================================="
echo -e "${MAGENTA}     تونل گیمینگ با موفقیت نصب شد!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}📋 اطلاعات اتصال:${NC}"
echo "----------------------------------------"
echo -e "آدرس سرور (IP): ${CYAN}$SERVER_IP${NC}"
echo -e "پورت (Port):     ${CYAN}$PORT${NC}"
echo -e "UUID:            ${CYAN}$UUID${NC}"
echo -e "SNI (Host):      ${CYAN}$SNI${NC}"
echo -e "PublicKey:       ${CYAN}$PUBLIC_KEY${NC}"
echo -e "ShortID:         ${CYAN}$SHORT_ID${NC}"
echo -e "Flow:            ${CYAN}xtls-rprx-vision${NC}"
echo "----------------------------------------"
echo ""
echo -e "${GREEN}🔗 لینک کپی-پیست:${NC}"
echo ""
echo "vless://$UUID@$SERVER_IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#Gaming-Tunnel"
echo ""
echo "=========================================="
echo ""
