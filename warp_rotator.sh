#!/bin/bash

# ==========================================
# Script Name: Warp IP Rotator (Tor-like Mode)
# Description: Auto-switch Warp Endpoints every X hours
# ==========================================

# رنگ‌ها
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# متغیرها
WARP_BIN="/usr/local/bin/warp-go"
WARP_PID_FILE="/var/run/warp-go.pid"
LOG_FILE="/var/log/warp-rotator.log"

# لیست بهترین Endpointهای Warp (Clean IPs)
# این‌ها آی‌پی‌های تمیز و پرسرعت در دیتاسنترهای مختلف هستند
declare -a ENDPOINTS=(
    "engage.cloudflareclient.com:2408"  # Global Default
    "162.159.192.1:2408"               # US (Cloudflare US)
    "188.114.96.1:2408"                # Europe (Cloudflare EU)
    "104.16.132.229:2408"              # Asia Pacific
    "104.16.17.94:2408"                # Backup
)

# تابع لاگ
log() {
    echo "[$(date +'%H:%M:%S')] $1" | tee -a $LOG_FILE
}

# -----------------------------------------------------------
# تابع 1: تغییر Endpoint (تغییر IP)
# -----------------------------------------------------------
rotate_ip() {
    log "در حال تغییر IP خروجی Warp..."
    
    # انتخاب یک Endpoint تصادفی از لیست
    RANDOM_INDEX=$((RANDOM % ${#ENDPOINTS[@]}))
    NEW_ENDPOINT="${ENDPOINTS[$RANDOM_INDEX]}"
    
    log "Endpoint جدید انتخاب شد: $NEW_ENDPOINT"
    
    # کشتن پروسه قبلی Warp
    pkill -f "$WARP_BIN"
    sleep 2
    
    # اجرای مجدد Warp با Endpoint جدید
    # نکته: warp-go از پرچم --endpoint پشتیبانی می‌کند
    nohup $WARP_BIN run --socks5 :40000 --endpoint "$NEW_ENDPOINT" > /dev/null 2>&1 &
    NEW_PID=$!
    
    # ذخیره PID برای مدیریت
    echo $NEW_PID > $WARP_PID_FILE
    
    sleep 3
    
    if ps -p $NEW_PID > /dev/null; then
        log -e "${GREEN}✅ IP با موفقیت تغییر کرد. PID: $NEW_PID${NC}"
        echo -e "${GREEN}IP جدید فعال شد: $NEW_ENDPOINT${NC}"
    else
        log -e "${RED}❌ خطا در تغییر IP.${NC}"
    fi
}

# -----------------------------------------------------------
# تابع 2: حلقه تغییر دوره‌ای (Tor Loop)
# -----------------------------------------------------------
start_tor_mode() {
    # دریافت زمان تغییر از کاربر (ساعت)
    read -p "هر چند ساعت یک بار IP عوض شود؟ (پیش‌فرض 2 ساعت): " hours
    hours=${hours:-2}
    
    SECONDS=$((hours * 3600))
    
    log "حالت Tor-like فعال شد. تغییر هر $hours ساعت."
    echo -e "${CYAN}اسکریپت در حال اجراست. برای خروج Ctrl+C را بزنید.${NC}"
    
    while true; do
        # اولین تغییر فوری
        rotate_ip
        
        log "منتظر $hours ساعت برای تغییر بعدی..."
        sleep $SECONDS
    done
}

# -----------------------------------------------------------
# تابع 3: تغییر فوری (دستی)
# -----------------------------------------------------------
instant_change() {
    if [ -f "$WARP_PID_FILE" ]; then
        OLD_PID=$(cat $WARP_PID_FILE)
        log "تغییر فوری درخواست شد (پروسه فعلی: $OLD_PID)..."
    else
        log "تغییر فوری درخواست شد..."
    fi
    rotate_ip
}

# -----------------------------------------------------------
# منوی اصلی
# -----------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run as Root${NC}"
  exit
fi

# چک کردن وجود warp-go
if [ ! -f "$WARP_BIN" ]; then
    echo "ابزار warp-go نصب نیست. در حال نصب..."
    curl -fsSL https://github.com/iPmartNetwork/warp-go/releases/download/v1.0.7/warp-go_amd64 -o $WARP_BIN
    chmod +x $WARP_BIN
    # ثبت نام اولیه
    $WARP_BIN register > /dev/null 2>&1
fi

clear
echo "=========================================="
echo -e "${CYAN}     Warp IP Rotator (Tor-Like)${NC}"
echo "=========================================="
echo ""
echo "1) شروع تغییر دوره‌ای (Tor Mode)"
echo "2) تغییر فوری IP (Instant Switch)"
echo "3) وضعیت فعلی"
echo "0) خروج"
echo "------------------------------------------"
read -p "انتخاب: " choice

case $choice in
    1)
        start_tor_mode
        ;;
    2)
        instant_change
        ;;
    3)
        echo "آخرین لاگ‌ها:"
        tail -n 10 $LOG_FILE
        echo ""
        if ps -p $(cat $WARP_PID_FILE 2>/dev/null) > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Warp در حال اجراست.${NC}"
        else
            echo -e "${RED}❌ Warp متوقف است.${NC}"
        fi
        ;;
    0)
        exit
        ;;
esac
