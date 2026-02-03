#!/bin/bash

# ==========================================
# Script Name: Ultimate VPS Manager v8 (Smart AI)
# Description: Auto-Detect, Warp Integration, Reality Optimizer
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# متغیرهای سراسری
CONFIG_FILE="/usr/local/etc/xray/config.json"
WARP_PROXIED_PORT=40000

# -----------------------------------------------------------
# تابع 1: چک کردن سرعت سرور (Speed Test)
# -----------------------------------------------------------
check_server_speed() {
    clear
    echo "=========================================="
    echo -e "${CYAN}  بررسی کیفیت سرور (Speed Test)${NC}"
    echo "=========================================="
    
    if ! command -v curl &> /dev/null; then
        apt update -y && apt install -y curl
    fi

    echo "در حال دانلود تست فایل از کلادفلر..."
    # دانلود یک فایل کوچک برای تست پینگ و دانلود
    START=$(date +%s%N)
    DL_SPEED=$(curl -o /dev/null -s -w '%{speed_download}\n' --connect-timeout 5 https://speed.cloudflare.com/__down?bytes=10000000)
    END=$(date +%s%N)
    PING=$(( (END - START) / 1000000 )) # میلی‌ثانیه

    # چک کردن کیفیت IP
    IP_TYPE=$(curl -s https://ipapi.co/json | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
    
    echo "----------------------------------------"
    echo -e "پینگ سرور: ${CYAN}${PING}ms${NC}"
    echo -e "سرعت دانلود: ${CYAN}${DL_SPEED} bytes/s${NC}"
    echo -e "نوع IP: ${YELLOW}${IP_TYPE}${NC}"
    echo "----------------------------------------"
    
    if [[ "$IP_TYPE" == "reserved" ]] || [[ "$IP_TYPE" == "bogon" ]]; then
        echo -e "${RED}⚠️  هشدار: IP شما خاکستری یا محفوظ است. استفاده از Warp پیشنهاد می‌شود.${NC}"
        return 1
    else
        echo -e "${GREEN}✅ IP سرور تمیز و به اصطلاح Clean است.${NC}"
        return 0
    fi
    read -p "اینتر برای ادامه..."
}

# -----------------------------------------------------------
# تابع 2: مدیریت Warp (هوشمند)
# -----------------------------------------------------------
manage_warp() {
    clear
    echo "=========================================="
    echo -e "${MAGENTA}  مدیریت Warp (Cloudflare)${NC}"
    echo "=========================================="
    echo "1) فعال‌سازی Warp Proxied (پیشنهاد برای IP خاکستری)"
    echo "2) غیرفعال‌سازی Warp"
    echo "0) بازگشت"
    read -p "انتخاب: " w_choice

    if [[ "$w_choice" == "1" ]]; then
        echo "در حال نصب ابزار warp-go..."
        if [ ! -f "/usr/local/bin/warp-go" ]; then
            curl -fsSL https://github.com/iPmartNetwork/warp-go/releases/download/v1.0.7/warp-go_amd64 -o /usr/local/bin/warp-go
            chmod +x /usr/local/bin/warp-go
        fi
        
        echo "در حال ثبت نام و راه‌اندازی پروکسی روی پورت $WARP_PROXIED_PORT..."
        /usr/local/bin/warp-go register > /dev/null 2>&1
        pkill -f warp-go # کشتن نسخه قبلی
        nohup /usr/local/bin/warp-go run --socks5 :$WARP_PROXIED_PORT > /dev/null 2>&1 &
        
        sleep 3
        if netstat -tuln | grep -q ":$WARP_PROXIED_PORT "; then
            echo -e "${GREEN}✅ Warp با موفقیت روی پورت $WARP_PROXIED_PORT فعال شد.${NC}"
            
            # سوال برای اتصال به Reality
            if [ -f "$CONFIG_FILE" ]; then
                read -p "آیا می‌خواهید Reality را از طریق Warp عبور دهید؟ (y/n): " connect_reality
                if [[ "$connect_reality" == "y" ]]; then
                    cp $CONFIG_FILE $CONFIG_FILE.bak
                    # جایگزینی outbound در JSON
                    # نکته: این یک جایگزینی ساده متنی است و به ساختار فایل وابسته است.
                    # در حالت ایده آل باید از jq استفاده شود اما برای سبکی sed را استفاده می‌کنیم.
                    sed -i 's/"protocol": "freedom"/"protocol": "socks", "settings": { "servers": [ { "address": "127.0.0.1", "port": '$WARP_PROXIED_PORT' } ] }/g' $CONFIG_FILE
                    systemctl restart xray
                    echo -e "${GREEN}✅ Reality اکنون از Warp عبور می‌کند.${NC}"
                fi
            fi
        else
            echo -e "${RED}❌ خطا در راه‌اندازی Warp.${NC}"
        fi
    elif [[ "$w_choice" == "2" ]]; then
        pkill -f warp-go
        # بازگرداندن فایل بکاپ
        if [ -f "$CONFIG_FILE.bak" ]; then
            cp $CONFIG_FILE.bak $CONFIG_FILE
            systemctl restart xray
            echo -e "${GREEN}✅ Warp غیرفعال و کانفیگ قبلی بازگردانی شد.${NC}"
        fi
    fi
    read -p "اینتر برای بازگشت..."
}

# -----------------------------------------------------------
# تابع 3: نصب Reality (هوشمند و زیبا)
# -----------------------------------------------------------
install_reality() {
    clear
    echo "=========================================="
    echo -e "${BLUE}  نصب تونل Reality (Smart)${NC}"
    echo "=========================================="
    
    # لیست هاست‌ها (گیمینگ + تکنولوژی)
    declare -a HOSTS=(
        "www.microsoft.com" "store.steampowered.com" "www.google.com" "www.amazon.com" "www.nvidia.com"
        "www.epicgames.com" "www.apple.com" "www.playstation.com" "www.xbox.com" "discord.com"
        "www.twitch.tv" "www.cloudflare.com" "www.oracle.com" "www.ubisoft.com" "www.blizzard.com"
    )
    
    echo "1) انتخاب خودکار (سریع‌ترین گزینه)"
    echo "2) انتخاب دستی از لیست"
    read -p "انتخاب: " mode
    
    SNI="www.microsoft.com" # پیش‌فرض
    
    if [[ "$mode" == "1" ]]; then
        echo "در حال پینگ گرفتن از هاست‌ها..."
        BEST_HOST=""
        MIN_PING=99999
        
        for host in "${HOSTS[@]}"; do
            PING=$(ping -c 1 -W 1 $host 2>/dev/null | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
            if [[ -n "$PING" ]]; then
                if (( $(echo "$PING < $MIN_PING" | bc -l) )); then
                    MIN_PING=$PING
                    BEST_HOST=$host
                fi
            fi
        done
        SNI=${BEST_HOST:-"www.microsoft.com"}
        echo -e "${GREEN}بهترین هاست پیدا شد: $SNI (Ping: $MIN_PING)${NC}"
    else
        PS3="لطفا شماره هاست را انتخاب کنید: "
        select opt in "${HOSTS[@]}"; do
            SNI=$opt
            break
        done
    fi

    read -p "پورت [443]: " PORT
    PORT=${PORT:-443}
    
    echo "انتخاب پروتکل:"
    echo "1) gRPC (پیشنهاد: پایدارترین و امن‌ترین)"
    echo "2) WebSocket"
    read -p "انتخاب [1-2]: " proto
    NET_TYPE="grpc"
    PATH_VAL="GoogleTalk"
    if [[ "$proto" == "2" ]]; then
        NET_TYPE="ws"
        PATH_VAL="/$(openssl rand -hex 8)"
    fi

    # نصب Xray
    echo "نصب Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    # تولید کلید
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    UUID=$(cat /proc/sys/kernel/random/uuid)

    # ساخت JSON
    STREAM_JSON=""
    if [[ "$NET_TYPE" == "grpc" ]]; then
        STREAM_JSON=$(cat <<EOF
        "network": "grpc",
        "grpcSettings": { "serviceName": "$PATH_VAL" },
        "security": "reality",
        "realitySettings": {
            "dest": "$SNI:443", "serverNames": ["$SNI"], "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"], "fingerprint": "chrome"
        }
EOF
)
    else
        STREAM_JSON=$(cat <<EOF
        "network": "ws", "wsSettings": { "path": "$PATH_VAL" },
        "security": "reality",
        "realitySettings": {
            "dest": "$SNI:443", "serverNames": ["$SNI"], "privateKey": "$PRIVATE_KEY", "shortIds": ["$SHORT_ID"], "fingerprint": "chrome"
        }
EOF
)
    fi

    cat <<EOF > $CONFIG_FILE
{
  "log": { "loglevel": "warning" },
  "inbounds": [{
    "port": $PORT, "protocol": "vless",
    "settings": { "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }], "decryption": "none" },
    "streamSettings": { $STREAM_JSON },
    "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
  }],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

    ufw allow $PORT/tcp > /dev/null 2>&1
    systemctl restart xray
    systemctl enable xray

    # نمایش لینک
    LINK_PARAMS="encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=$NET_TYPE"
    if [[ "$NET_TYPE" == "ws" ]]; then LINK_PARAMS="$LINK_PARAMS&path=$PATH_VAL"; else LINK_PARAMS="$LINK_PARAMS&serviceName=$PATH_VAL"; fi
    
    clear
    echo -e "${GREEN}✅ تونل نصب شد!${NC}"
    echo "لینک:"
    echo "vless://$UUID@$(curl -s -4 ip.sb):$PORT?$LINK_PARAMS#Smart-Tunnel"
    read -p "اینتر برای بازگشت..."
}

# -----------------------------------------------------------
# منوی اصلی (Main Loop)
# -----------------------------------------------------------
while true; do
    clear
    echo "=========================================="
    echo -e "${GREEN}   VPS Ultimate Manager v8${NC}"
    echo "=========================================="
    echo "1) بررسی کیفیت سرور (Speed & IP Check)"
    echo "2) نصب / مدیریت تونل Reality"
    echo "3) مدیریت Warp (IP Cleaner)"
    echo "4) نمایش اطلاعات تونل"
    echo "0) خروج"
    echo "------------------------------------------"
    read -p "انتخاب: " main_choice

    case $main_choice in
        1) check_server_speed ;;
        2) install_reality ;;
        3) manage_warp ;;
        4) 
            if [ -f "$CONFIG_FILE" ]; then
                cat "$CONFIG_FILE" | grep -E '"port"|"id"|"network"|"serviceName"|"path"'
            else
                echo "تونل نصب نیست."
            fi
            read -p ""
            ;;
        0) exit ;;
        *) echo "نامعتبر" && sleep 1 ;;
    esac
done
