#!/bin/bash

# ==========================================
# Script Name: Global Warp Rotator v2 (Massive List)
# Description: Switch between Global & Iranian Endpoints
# ==========================================

# رنگ‌ها
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# متغیرها
WARP_BIN="/usr/local/bin/warp-go"
WARP_PID_FILE="/var/run/warp-go.pid"
LOG_FILE="/var/log/warp-rotator.log"

# -----------------------------------------------------------
# 1. لیست超大 (Super Massive List) از Endpointهای جهانی
# هر آی‌پی در این لیست نماینده صدها سرور آنلاین است.
# -----------------------------------------------------------
declare -a ENDPOINTS=(
    # --- سرورهای جهانی کلادفلر (Global Anycast) ---
    # این دامنه‌ها به نزدیک‌ترین سرور در قاره شما وصل می‌شوند
    "engage.cloudflareclient.com:2408"
    "162.159.192.1:2408"
    "162.159.193.1:2408"
    "188.114.96.1:2408"
    "188.114.97.1:2408"
    "104.16.132.229:2408"
    "104.16.17.94:2408"

    # --- دیتاسنترهای آسیا و خاورمیانه (بسیار نزدیک به ایران) ---
    "104.18.46.38:2408"        # Hong Kong
    "104.18.46.197:2408"       # Singapore
    "162.159.208.1:2408"       # Mumbai (India)
    "104.16.254.23:2408"       # Dubai (UAE) - نزدیک‌ترین به ایران
    "172.64.144.58:2408"       # Dubai
    "104.18.55.185:2408"       # Tokyo (Japan)

    # --- رنج‌های خاص ایران (ترافیک داخلی/ترانزیت) ---
    # این‌ها آی‌پی‌های معتبر کلادفلر هستند که در ایران ریزپخش شده‌اند
    # برای تغییر سریع روتینگ در خاک ایران
    "178.22.122.1:2408"        # Tehran/Iran Route (Cloudflare Radar)
    "185.51.200.1:2408"        # Iran Route
    "78.157.42.1:2408"         # Iran Route

    # --- رنج‌های اروپا (برای پینگ عالی در شب) ---
    "104.26.8.23:2408"         # Germany/Frankfurt
    "172.67.73.155:2408"       # London/UK
    "104.21.94.4:2408"         # Amsterdam/Netherlands

    # --- رنج‌های آمریکای شمالی (برای سرعت محتوا) ---
    "104.16.85.20:2408"        # US West
    "172.67.215.249:2408"      # US East
    "104.26.3.95:2408"         # Canada

    # --- سرورهای خاص Other (High Anonymity) ---
    "1.1.1.1:2408"             # Cloudflare DNS Route
    "2606:4700:4700::1111:2408" # IPv6 Support (اگر VPS ipv6 دارد)
)

# تابع لاگ
log() {
    echo "[$(date +'%H:%M:%S')] $1" | tee -a $LOG_FILE
}

# -----------------------------------------------------------
# تابع 1: انتخاب هوشمند IP (وزن‌دهی تصادفی)
# -----------------------------------------------------------
smart_select_endpoint() {
    # انتخاب تصادفی از آرایه
    RAND_INDEX=$((RANDOM % ${#ENDPOINTS[@]}))
    SELECTED_ENDPOINT="${ENDPOINTS[$RAND_INDEX]}"
    
    # نمایش جغرافیای تقریبی (فقط برای زیبایی)
    if [[ $SELECTED_ENDPOINT == *"104.18.254.23"* ]] || [[ $SELECTED_ENDPOINT == *"172.64.144.58"* ]]; then
        REGION="${CYAN}[Dubai - Near Iran]${NC}"
    elif [[ $SELECTED_ENDPOINT == *"178.22.122"* ]] || [[ $SELECTED_ENDPOINT == *"185.51.200"* ]]; then
        REGION="${MAGENTA}[Iran Region]${NC}"
    elif [[ $SELECTED_ENDPOINT == *"162.159.208"* ]]; then
        REGION="${YELLOW}[India/Asia]${NC}"
    elif [[ $SELECTED_ENDPOINT == *"104.18.46"* ]]; then
        REGION="${YELLOW}[East Asia]${NC}"
    else
        REGION="${GREEN}[Global/EU/US]${NC}"
    fi
    
    echo "$SELECTED_ENDPOINT|$REGION"
}

# -----------------------------------------------------------
# تابع 2: تغییر IP (Rotate)
# -----------------------------------------------------------
rotate_ip() {
    log "شروع فرآیند تغییر IP..."
    
    # استفاده از تابع انتخاب هوشمند
    RESULT=$(smart_select_endpoint)
    NEW_ENDPOINT=$(echo "$RESULT" | cut -d'|' -f1)
    REGION_INFO=$(echo "$RESULT" | cut -d'|' -f2)
    
    log "Endpoint انتخاب شد: $NEW_ENDPOINT $REGION_INFO"
    
    # کشتن پروسه قبلی
    pkill -f "$WARP_BIN"
    sleep 2
    
    # اجرای جدید با Endpoint انتخاب شده
    nohup $WARP_BIN run --socks5 :40000 --endpoint "$NEW_ENDPOINT" > /dev/null 2>&1 &
    NEW_PID=$!
    echo $NEW_PID > $WARP_PID_FILE
    
    sleep 3
    
    if ps -p $NEW_PID > /dev/null; then
        clear
        echo "=========================================="
        echo -e "${GREEN}      IP با موفقیت تغییر کرد!${NC}"
        echo "=========================================="
        echo -e "منطقه خروجی: $REGION_INFO"
        echo -e "آدرس Endpoint: ${CYAN}$NEW_ENDPOINT${NC}"
        echo "=========================================="
        log "موفقیت: IP به $NEW_ENDPOINT تغییر یافت."
    else
        log -e "${RED}خطا: پروژه Warp راه اندازی نشد.${NC}"
        echo -e "${RED}❌ خطا در راه‌اندازی Warp.${NC}"
    fi
}

# -----------------------------------------------------------
# تابع 3: حالت Tor (تغییر دوره‌ای با زمان‌های تصادفی)
# -----------------------------------------------------------
start_tor_mode() {
    read -p "حداقل زمان تغییر (دقیقه) [پیش‌فرض 30]: " min_time
    read -p "حداکثر زمان تغییر (دقیقه) [پیش‌فرض 90]: " max_time
    
    min_time=${min_time:-30}
    max_time=${max_time:-90}
    
    log "حالت Tor Advanced فعال شد (تصادفی: ${min_time}-${max_time} دقیقه)."
    echo -e "${CYAN}اسکریپت در حال اجراست. Ctrl+C برای توقف.${NC}"
    
    while true; do
        rotate_ip
        
        # تولید یک زمان تصادفی بین مینیمم و ماکسیمم
        # برای اینکه رفتار رباتی نداشته باشیم
        RANDOM_SLEEP=$(( ( RANDOM % (max_time - min_time + 1) ) + min_time ))
        RANDOM_SEC=$((RANDOM_SLEEP * 60))
        
        HOURS=$((RANDOM_SEC / 3600))
        MINS=$(( (RANDOM_SEC % 3600) / 60 ))
        
        log "تغییر بعدی در $HOURS ساعت و $MINS دقیقه."
        sleep $RANDOM_SEC
    done
}

# -----------------------------------------------------------
# منوی اصلی
# -----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as Root${NC}"
  exit
fi

if [ ! -f "$WARP_BIN" ]; then
    echo "نصب ابزار warp-go..."
    curl -fsSL https://github.com/iPmartNetwork/warp-go/releases/download/v1.0.7/warp-go_amd64 -o $WARP_BIN
    chmod +x $WARP_BIN
    $WARP_BIN register > /dev/null 2>&1
fi

clear
echo "=========================================="
echo -e "${MAGENTA}   Global Warp Rotator v2${NC}"
echo "=========================================="
echo ""
echo "لیست Endpoints شامل:"
echo "- سرورهای جهانی (Global)"
echo "- دیتاسنترهای خاورمیانه (دبی - نزدیک ایران)"
echo "- رنج‌های IP ایران (ترانزیت)"
echo "- سرورهای آسیا و اروپا"
echo ""
echo "1) شروع تغییر دوره‌ای (Tor Advanced - Random Time)"
echo "2) تغییر فوری IP (Instant)"
echo "3) نمایش لیست کامل Endpoints"
echo "0) خروج"
echo "------------------------------------------"
read -p "انتخاب: " choice

case $choice in
    1)
        start_tor_mode
        ;;
    2)
        rotate_ip
        ;;
    3)
        echo -e "${CYAN}لیست IPهای موجود در بانک اطلاعاتی:${NC}"
        for ep in "${ENDPOINTS[@]}"; do
            echo "$ep"
        done
        echo "تعداد کل: ${#ENDPOINTS[@]}"
        ;;
    0)
        exit
        ;;
esac
