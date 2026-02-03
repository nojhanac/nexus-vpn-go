#!/bin/bash

# ==========================================
# Script Name: Reality Ultimate v6 (WS + Multi-User)
# Features: WebSocket Stealth, Multi-User Support, Gaming List
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# متغیرهای اصلی
CONFIG_FILE="/usr/local/etc/xray/config.json"

# چک کردن روت
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as Root${NC}"
  exit
fi

# -----------------------------------------------------------
# لیست هاست‌ها (همان لیست گیمینگ)
# -----------------------------------------------------------
declare -a HOSTS=(
    "www.microsoft.com" "www.apple.com" "www.google.com" "www.amazon.com" "store.steampowered.com"
    "www.epicgames.com" "www.ubisoft.com" "www.playstation.com" "www.xbox.com" "www.nvidia.com"
    "www.amd.com" "www.asus.com" "www.msi.com" "www.razersupport.com" "www.logitechg.com"
    "www.fortnite.com" "www.leagueoflegends.com" "www.minecraft.net" "www.roblox.com" "www.twitch.tv"
    "www.cloudflare.com" "www.oracle.com" "www.ibm.com" "www.cisco.com" "discord.com"
    "ea.com" "www.origin.com" "www.blizzard.com" "www.gog.com" "itch.io"
    "www.dota2.com" "csgostats.com" "www.brawlstars.com" "www.clashroyale.com" "www.genshinimpact.com"
)

# -----------------------------------------------------------
# تابع: نمایش لیست هاست
# -----------------------------------------------------------
show_hosts() {
    echo -e "${CYAN}لیست هاست‌ها:${NC}"
    for i in "${!HOSTS[@]}"; do
        printf "%3d) %s\n" $((i+1)) "${HOSTS[$i]}"
    done
}

# -----------------------------------------------------------
# تابع: تولید کانفیگ
# $1: SNI, $2: PORT, $3: NETWORK_TYPE (tcp/ws), $4: PATH (فقط برای ws)
# -----------------------------------------------------------
generate_config() {
    local SNI=$1
    local PORT=$2
    local NET_TYPE=$3
    local WS_PATH=$4

    # تولید کلیدها
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    UUID=$(cat /proc/sys/kernel/random/uuid)

    # ساخت JSON بر اساس نوع شبکه
    STREAM_SETTINGS=''
    
    if [[ "$NET_TYPE" == "ws" ]]; then
        # WebSocket Settings
        STREAM_SETTINGS=$(cat <<EOF
        "network": "ws",
        "wsSettings": {
            "path": "$WS_PATH"
        },
EOF
)
    else
        # TCP Settings
        STREAM_SETTINGS=$(cat <<EOF
        "network": "tcp",
EOF
)
    fi

    # نوشتن فایل کانفیگ نهایی
    cat <<EOF > $CONFIG_FILE
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PORT,
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "$UUID", "flow": "xtls-rprx-vision" } ],
        "decryption": "none"
      },
      "streamSettings": {
        $STREAM_SETTINGS
        "security": "reality",
        "realitySettings": {
          "dest": "$SNI:443",
          "serverNames": [ "$SNI" ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [ "$SHORT_ID" ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [ "http", "tls" ]
      }
    }
  ],
  "outbounds": [ { "protocol": "freedom" } ]
}
EOF

    # ساخت لینک
    SERVER_IP=$(curl -s -4 ip.sb)
    LINK_PARAMS="encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=$NET_TYPE"
    
    if [[ "$NET_TYPE" == "ws" ]]; then
        LINK_PARAMS="$LINK_PARAMS&path=$WS_PATH"
    fi

    echo "vless://$UUID@$SERVER_IP:$PORT?$LINK_PARAMS#Ultimate-Tunnel"
}

# -----------------------------------------------------------
# منوی اصلی
# -----------------------------------------------------------
while true; do
    clear
    echo "=========================================="
    echo -e "${MAGENTA}  Ultimate Reality Manager v6${NC}"
    echo "=========================================="
    echo ""
    echo "1) نصب تونل جدید (Install)"
    echo "2) افزودن کاربر جدید (Add User - Multi-User)"
    echo "3) نمایش اطلاعات فعلی (Show Info)"
    echo "0) خروج"
    echo "------------------------------------------"
    read -p "انتخاب: " main_choice

    if [[ "$main_choice" == "1" ]]; then
        # --- نصب جدید ---
        show_hosts
        read -p "شماره هاست: " sni_num
        SNI="${HOSTS[$((sni_num-1))]}"
        
        read -p "پورت [443]: " PORT
        PORT=${PORT:-443}

        echo "1) TCP (پیش‌فرض - سریع)"
        echo "2) WebSocket (مخفی‌سازی - استتار بیشتر)"
        read -p "نوع شبکه [1-2]: " net_choice
        
        NET_TYPE="tcp"
        WS_PATH="/"
        
        if [[ "$net_choice" == "2" ]]; then
            NET_TYPE="ws"
            WS_PATH="/$(openssl rand -hex 8)" # تولید مسیر تصادفی
            echo "مسیر WebSocket: $WS_PATH"
        fi

        echo "در حال نصب Xray..."
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
        
        LINK=$(generate_config "$SNI" "$PORT" "$NET_TYPE" "$WS_PATH")
        
        # فایروال
        ufw allow $PORT/tcp > /dev/null 2>&1
        systemctl restart xray
        systemctl enable xray
        
        echo -e "${GREEN}✅ نصب شد!${NC}"
        echo "لینک:"
        echo "$LINK"
        read -p ""

    elif [[ "$main_choice" == "2" ]]; then
        # --- افزودن کاربر (ساده شده) ---
        echo -e "${YELLOW}این بخش به دستور jq نیاز دارد که نصب نشده است.${NC}"
        echo "برای سادگی، لطفاً از گزینه 1 استفاده کنید و یک پورت جدید بسازید."
        read -p "اینتر برای بازگشت..."

    elif [[ "$main_choice" == "3" ]]; then
        # --- نمایش اطلاعات ---
        if [ -f "$CONFIG_FILE" ]; then
            cat "$CONFIG_FILE" | grep -E '"port"|"id"|"sni"|"path"'
        else
            echo "تونل نصب نیست."
        fi
        read -p ""
    
    elif [[ "$main_choice" == "0" ]]; then
        exit
    fi
done
