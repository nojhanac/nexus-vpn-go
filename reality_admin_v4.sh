#!/bin/bash

# ==========================================
# Script Name: Reality Admin v4 (Smart Manager)
# Features: Menu System, Auto-Detect SNI, QR Code, Link Recovery
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# آدرس فایل کانفیگ
CONFIG_FILE="/usr/local/etc/xray/config.json"

# -----------------------------------------------------------
# تابع 1: چک کردن نصب بودن Xray
# -----------------------------------------------------------
check_install() {
    if ! command -v xray &> /dev/null; then
        return 1
    else
        return 0
    fi
}

# -----------------------------------------------------------
# تابع 2: نمایش لینک و QR Code
# -----------------------------------------------------------
show_link() {
    if ! check_install; then
        echo -e "${RED}Xray نصب نیست!${NC}"
        return
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}فایل کانفیگ یافت نشد!${NC}"
        return
    fi

    echo -e "${CYAN}در حال استخراج اطلاعات...${NC}"
    
    # استخراج اطلاعات با jq یا grep/sed
    # فرض بر این است که ساختار JSON طبق اسکریپت ماست
    UUID=$(grep -oP '"id":\s*"\K[^"]+' "$CONFIG_FILE")
    PORT=$(grep -oP '"port":\s*\K[0-9]+' "$CONFIG_FILE")
    SNI=$(grep -oP '"serverNames":\s*\[\s*"\K[^"]+' "$CONFIG_FILE")
    PBK=$(grep -oP '"publicKey":\s*"\K[^"]+' "$CONFIG_FILE")
    SID=$(grep -oP '"shortIds":\s*\[\s*"\K[^"]+' "$CONFIG_FILE")
    IP=$(curl -s -4 ip.sb)

    if [[ -z "$UUID" || -z "$PORT" ]]; then
        echo -e "${RED}خطا در خواندن کانفیگ.${NC}"
        return
    fi

    LINK="vless://$UUID@$IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PBK&sid=$SID&type=tcp#Reality-$SNI"

    clear
    echo "=========================================="
    echo -e "${GREEN}     اطلاعات اتصال شما${NC}"
    echo "=========================================="
    echo -e "IP: ${CYAN}$IP${NC}"
    echo -e "SNI: ${CYAN}$SNI${NC}"
    echo ""
    echo -e "${YELLOW}لینک وی‌لس (VLESS):${NC}"
    echo "$LINK"
    echo ""
    
    # نمایش QR Code (اگر نصب باشد)
    if command -v qrencode &> /dev/null; then
        echo -e "${YELLOW}QR Code (اسکن کنید):${NC}"
        qrencode -t ANSIUTF8 "$LINK"
    else
        echo -e "${YELLOW}نکته:${NC} برای نمایش کد QR، دستور زیر را بزنید:"
        echo "apt install qrencode -y"
    fi
    echo "=========================================="
}

# -----------------------------------------------------------
# تابع 3: تشخیص هوشمند بهترین SNI
# -----------------------------------------------------------
auto_detect_sni() {
    echo -e "${CYAN}در حال اسکن سریع ۵ هاست برتر...${NC}"
    
    # لیست کاندیداهای تست سرعت
    CANDIDATES=(
        "www.microsoft.com"
        "www.apple.com"
        "www.google.com"
        "www.amazon.com"
        "www.cloudflare.com"
    )

    BEST_HOST=""
    MIN_TIME=99999

    for host in "${CANDIDATES[@]}"; do
        # زمان اتصال (Connect time) را می‌سنجیم
        TIME=$(curl -o /dev/null -s -w '%{time_connect}\n' --connect-timeout 2 https://$host)
        
        # اگر خطایی رخ داد، TIME شاید رشته خالی یا غیرعددی باشد
        if [[ "$TIME" =~ ^[0-9.]+$ ]]; then
            # تبدیل به عدد صحیح برای مقایسه ساده (یا bc استفاده کنیم)
            INT_TIME=$(echo "$TIME * 1000" | bc | cut -d. -f1)
            
            echo "测试 $host: ${TIME}s"
            
            if (( INT_TIME < MIN_TIME )); then
                MIN_TIME=$INT_TIME
                BEST_HOST=$host
            fi
        fi
    done

    if [[ -n "$BEST_HOST" ]]; then
        echo -e "${GREEN}✅ بهترین هاست تشخیص داده شد: $BEST_HOST (${MIN_TIME}ms)${NC}"
        SNI=$BEST_HOST
        DEST=$BEST_HOST
    else
        echo -e "${YELLOW}⚠️  نتوانستم هاست را تست کنم، از مایکروسافت استفاده می‌کنم.${NC}"
        SNI="www.microsoft.com"
        DEST="www.microsoft.com"
    fi
}

# -----------------------------------------------------------
# تابع 4: نصب / آپدیت
# -----------------------------------------------------------
install_reality() {
    echo -e "${CYAN}--- شروع فرآیند نصب ---${NC}"
    
    # بخش هوشمند: سوال برای خودکار یا دستی
    echo ""
    echo "1) انتخاب دستی از لیست (35 گزینه)"
    echo "2) انتخاب هوشمند (خودکار سریع‌ترین)"
    echo "0) بازگشت"
    read -p "انتخاب: " mode_choice

    if [[ "$mode_choice" == "1" ]]; then
        # نمایش لیست کامل (مشابه نسخه v3)
        declare -a HOSTS=(
            "www.microsoft.com" "www.apple.com" "www.google.com" "www.amazon.com" "www.nvidia.com"
            "www.intel.com" "www.adobe.com" "www.oracle.com" "www.samsung.com" "www.sony.com"
            "store.steampowered.com" "www.epicgames.com" "www.ibm.com" "www.cisco.com" "www.dell.com"
            "www.hp.com" "www.lenovo.com" "www.wikipedia.org" "www.mozilla.org" "www.cloudflare.com"
            "www.digitalocean.com" "www.atlassian.com" "www.autodesk.com" "www.qualcomm.com" "www.broadcom.com"
            "www.vmware.com" "www.redhat.com" "www.canon.com" "www.panasonic.com" "www.toshiba.com"
            "www.asus.com" "www.accenture.com" "www.capgemini.com" "www.bcg.com" "www.mckinsey.com"
        )
        
        echo "لیست هاست‌ها:"
        for i in "${!HOSTS[@]}"; do
            printf "%2d) %s\n" $((i+1)) "${HOSTS[$i]}"
        done
        read -p "شماره را وارد کنید: " sni_choice
        
        if [[ "$sni_choice" =~ ^[0-9]+$ ]] && [ "$sni_choice" -ge 1 ] && [ "$sni_choice" -le ${#HOSTS[@]} ]; then
            index=$((sni_choice - 1))
            SNI="${HOSTS[$index]}"
            DEST=$SNI
        else
            SNI="www.microsoft.com"; DEST="www.microsoft.com"
        fi
    elif [[ "$mode_choice" == "2" ]]; then
        auto_detect_sni
    else
        return
    fi

    read -p "پورت [443]: " PORT
    PORT=${PORT:-443}

    # نصب Xray
    echo "در حال نصب Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

    # تولید کلید
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
    SHORT_ID=$(openssl rand -hex 8)
    UUID=$(cat /proc/sys/kernel/random/uuid)

    # ساخت کانفیگ
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
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$DEST:443",
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

    # فایروال و سرویس
    ufw allow $PORT/tcp > /dev/null 2>&1
    systemctl restart xray
    systemctl enable xray

    echo -e "${GREEN}✅ نصب کامل شد.${NC}"
    show_link
}

# -----------------------------------------------------------
# تابع 5: حذف
# -----------------------------------------------------------
uninstall_reality() {
    read -p "آیا مطمئن هستید؟ تونل حذف خواهد شد. (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove
        echo -e "${RED}Xray حذف شد.${NC}"
    fi
}

# -----------------------------------------------------------
# منوی اصلی (Main Loop)
# -----------------------------------------------------------
while true; do
    clear
    echo "=========================================="
    echo -e "${GREEN}   VLESS Reality Manager (Smart)${NC}"
    echo "=========================================="
    
    # وضعیت سیستم
    if check_install; then
        STATUS="${GREEN}✅ نصب و فعال${NC}"
    else
        STATUS="${RED}❌ نصب نیست${NC}"
    fi
    
    echo -e "وضعیت: $STATUS"
    echo "------------------------------------------"
    echo "1) نصب یا آپدیت تونل (Install/Update)"
    echo "2) نمایش لینک و QR Code (Show Link)"
    echo "3) حذف تونل (Uninstall)"
    echo "0) خروج"
    echo "=========================================="
    
    read -p "لطفا گزینه را انتخاب کنید: " main_choice

    case $main_choice in
        1)
            install_reality
            read -p "اینتر برای بازگشت..."
            ;;
        2)
            show_link
            read -p "اینتر برای بازگشت..."
            ;;
        3)
            uninstall_reality
            read -p "اینتر برای بازگشت..."
            ;;
        0)
            echo "خداحافظ!"
            exit 0
            ;;
        *)
            echo "گزینه نامعتبر."
            sleep 1
            ;;
    esac
done
