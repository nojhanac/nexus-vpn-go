#!/bin/bash

# ==========================================
# Script Name: Ultimate VPS Optimizer v5 (Massive + GitHub)
# Description: Network Opt, GitHub Check, Clean Up, Auto Best DNS (1000+ Gen)
# ==========================================

# بررسی دسترسی روت
if [ "$EUID" -ne 0 ]; then
  echo "لطفا با دسترسی روت (root) این اسکریپت را اجرا کنید."
  exit
fi

# تابع برای رنگی کردن خروجی
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo "=========================================="
echo "  بهینه‌ساز فوق پیشرفته VPS (نسخه ولتاژ بالا)"
echo "=========================================="
echo ""

# -----------------------------------------------------------
# بخش 1: تست پینگ به ای‌پی شخصی کاربر
# -----------------------------------------------------------
echo -e "${YELLOW}--- بخش 1: بررسی اتصال به اینترنت ایران شما ---${NC}"
read -p "لطفاً IP خود در ایران را وارد کنید (یا اینتر رابرای رد کردن): " MY_IRAN_IP

if [[ -n "$MY_IRAN_IP" ]]; then
    echo "در حال ارسال پینگ به آی‌پی شما: $MY_IRAN_IP ..."
    PING_RESULT=$(ping -c 5 -W 2 $MY_IRAN_IP 2>&1)
    if [[ $? -eq 0 ]]; then
        AVG_PING=$(echo "$PING_RESULT" | tail -1 | awk -F '/' '{print $5}')
        echo -e "${GREEN}✅ متصل شد. میانگین پینگ به شما: $AVG_PING میلی‌ثانیه${NC}"
    else
        echo -e "${RED}⛔ خطا: پینگ به $MY_IRAN_IP برقرار نشد (احتمالاً فایروال ایران بسته است).${NC}"
    fi
else
    echo "تست پینگ شخصی رد شد."
fi

# -----------------------------------------------------------
# بخش 2: تست پینگ به گیتهاب
# -----------------------------------------------------------
echo ""
echo -e "${YELLOW}--- بخش 2: بررسی اتصال به GitHub (جهت کلون کردن پروژه‌ها) ---${NC}"
echo "در حال بررسی دسترسی به github.com..."
GITHUB_PING=$(ping -c 5 -W 3 github.com 2>&1)

if [[ $? -eq 0 ]]; then
    G_AVG=$(echo "$GITHUB_PING" | tail -1 | awk -F '/' '{print $5}')
    echo -e "${GREEN}✅ GitHub قابل دسترس است. میانگین پینگ: $G_AVG میلی‌ثانیه${NC}"
else
    echo -e "${RED}⚠️  هشدار: پینگ به GitHub برقرار نشد (ICMP بسته شده یا قطعی).${NC}"
    echo "   اما پورت HTTPS (443) را چک می‌کنیم..."
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/github.com/443"; then
        echo -e "${GREEN}✅ پورت HTTPS باز است (امکان استفاده از git وجود دارد).${NC}"
    else
        echo -e "${RED}⛔ دسترسی به GitHub وجود ندارد (احتمالاً نیاز به تنظیم Proxy دارید).${NC}"
    fi
fi

echo ""
echo "در ادامه اسکریپت سرور را بهینه می‌کند..."
echo "=========================================="
echo ""

# 3. ابزارهای پایه
echo "[Step 1/6] نصب ابزارهای پایه..."
apt update -y
apt install -y curl wget git net-tools dnsutils bc jq htop vnstat nano sed

# 4. نصب ابزارهای پاکسازی و مانیتورینگ
echo "[Step 2/6] نصب ابزارهای کاربردی..."
apt install -y bleachbit htop vnstat

echo "پاکسازی سیستم..."
apt autoremove -y
apt autoclean -y

# 5. تنظیمات سیستم
echo "[Step 3/6] اعمال تنظیمات سیستمی..."
timedatectl set-timezone Asia/Tehran
sysctl vm.swappiness=10 >> /etc/sysctl.conf 2>/dev/null
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# 6. بهینه‌سازی شبکه (BBR)
echo "[Step 4/6] فعال‌سازی BBR..."
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi
sysctl -p > /dev/null 2>&1

# 7. بخش مهم: تولید لیست 1000+ دی‌ان‌س و اسکن
echo "[Step 5/6] تولید لیست دی‌ان‌س (1000+ مورد) و شروع اسکن..."
echo "این مرحله ممکن است 1 تا 2 دقیقه طول بکشد..."

# تابع تولید لیست دی‌ان‌س
generate_massive_dns_list() {
    # 1. دی‌ان‌س‌های دستی برتر (ایران و معروف‌های جهانی)
    echo "178.22.122.100" "178.22.122.101" "10.202.10.202" "185.51.200.2" "78.157.42.100"
    
    # 2. تولید رنج گوگل (تست تمام رنج‌ها که گاهی سرعت متفاوتی دارند)
    for i in {1..255}; do echo "8.8.8.$i"; done
    for i in {1..255}; do echo "8.8.4.$i"; done
    
    # 3. تولید رنج کلودفلار
    for i in {1..255}; do echo "1.1.1.$i"; done
    for i in {1..255}; do echo "1.0.0.$i"; done

    # 4. تولید رنج کواد ناین
    for i in {1..255}; do echo "9.9.9.$i"; done
    
    # 5. تولید رنج OpenDNS
    for i in {1..255}; do echo "208.67.222.$i"; done
    for i in {1..255}; do echo "208.67.220.$i"; done

    # 6. رنج AdGuard
    for i in {1..255}; do echo "94.140.14.$i"; done

    # 7. رنج Comcast (Level3 style)
    for i in {1..255}; do echo "75.75.75.$i"; done
    for i in {1..255}; do echo "75.75.76.$i"; done
}

# اجرای تولید لیست و ذخیره در آرایه
mapfile -t DNS_LIST < <(generate_massive_dns_list)

TARGET_DOMAIN="google.com"
BEST_DNS=""
BEST_PING=9999999
FOUND_COUNT=0
TOTAL_COUNT=${#DNS_LIST[@]}

echo "آزمایش روی $TOTAL_COUNT دی‌ان‌س ... (تایم‌اوت 200ms برای سرعت بالا)"

counter=0
for dns in "${DNS_LIST[@]}"; do
    counter=$((counter + 1))
    
    # نمایش نوار پیشرفت ساده
    if (( $counter % 100 == 0 )); then
        echo "扫描进度: $counter / $TOTAL_COUNT"
    fi

    # پینگ با تایم‌اوت بسیار کوتاه (0.2 ثانیه)
    # اگر سریع جواب ندهد، دی‌ان‌س خوبی برای ما نیست
    PING_TIME=$(ping -c 1 -W 0.2 $dns 2>/dev/null | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')

    if [[ -n "$PING_TIME" ]]; then
        # بررسی دسترسی به اینترنت (رزلوشن گوگل)
        if timeout 0.5 nslookup $TARGET_DOMAIN $dns > /dev/null 2>&1; then
            FOUND_COUNT=$((FOUND_COUNT + 1))
            # چاپ فقط اگر پینگ خیلی خوب باشد (زیر 10ms)
            if (( $(echo "$PING_TIME < 10" | bc -l) )); then
                 printf "${GREEN}✅%-3d %-20s   %-10sms   عالی${NC}\n" "$counter" "$dns" "${PING_TIME}"
            fi
            
            # مقایسه و انتخاب بهترین
            if (( $(echo "$PING_TIME < $BEST_PING" | bc -l) )); then
                BEST_PING=$PING_TIME
                BEST_DNS=$dns
            fi
        fi
    fi
done

echo ""
echo "=========================================="
echo "  پایان اسکن دی‌ان‌س‌ها."
echo "  دی‌ان‌س‌های یافت شده و متصل: $FOUND_COUNT"
echo "=========================================="

# اعمال نهایی
if [ -z "$BEST_DNS" ]; then
    echo -e "${RED}⛔ هیچ دی‌ان‌سی پیدا نشد. استفاده از پیش‌فرض 1.1.1.1${NC}"
    BEST_DNS="1.1.1.1"
else
    echo ""
    echo -e "${GREEN}🏆 برنده نهایی: $BEST_DNS${NC}"
    echo "🏆 کمترین پینگ: ${BEST_PING} میلی‌ثانیه"
fi

echo ">>> تنظیم دی‌ان‌س..."

# باز کردن قفل و تنظیم
chattr -i /etc/resolv.conf 2>/dev/null
> /etc/resolv.conf
echo "nameserver $BEST_DNS" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf 
chattr +i /etc/resolv.conf

echo ">>> دی‌ان‌س قفل شد."

# 8. پایان
echo ""
echo "=========================================="
echo "  پایان فرآیند کلی."
echo "=========================================="
echo " پینگ به IP شما: (بالا نمایش داده شد)"
echo " پینگ به GitHub: (بالا نمایش داده شد)"
echo " دی‌ان‌س نهایی: $BEST_DNS"
echo " ابزارها: BleachBit, htop, BBR Active"
echo ""
