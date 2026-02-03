#!/bin/bash

# ==========================================
# Script Name: Ultimate VPS Optimizer v6 (Pro Edition)
# Features: Hybrid DNS, UDP Buffers, GitHub Fix, Auto Swap
# ==========================================

# بررسی دسترسی روت
if [ "$EUID" -ne 0 ]; then
  echo "لطفا با دسترسی روت (root) این اسکریپت را اجرا کنید."
  exit
fi

# رنگ‌ها
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear
echo "=========================================="
echo "  بهینه‌ساز حرفه‌ای VPS (نسخه 6 Pro)"
echo "=========================================="
echo ""

# -----------------------------------------------------------
# 1. نصب ابزارهای اولیه (شامل dnsutils برای دستور dig)
# -----------------------------------------------------------
echo -e "${CYAN}[1/7] نصب ابزارهای مورد نیاز...${NC}"
apt update -y
apt install -y curl wget git net-tools dnsutils bc jq htop vnstat nano sed uuid-runtime

# -----------------------------------------------------------
# 2. ایجاد Swap File پویا (Dynamic Swap)
# -----------------------------------------------------------
echo -e "${CYAN}[2/7] بررسی و ایجاد حافظه Swap...${NC}"
SWAP_FILE="/swapfile"

# چک کردن اینکه آیا قبلاً ساخته شده است
if [ ! -f "$SWAP_FILE" ]; then
    if [ $(swapon --show | wc -l) -eq 0 ]; then
        echo "هیچ Swap یافت نشد. در حال ایجاد 1 گیگابایت Swap..."
        fallocate -l 1G $SWAP_FILE
        chmod 600 $SWAP_FILE
        mkswap $SWAP_FILE
        swapon $SWAP_FILE
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
        echo -e "${GREEN}✅ 1 گیگابایت Swap با موفقیت ساخته شد.${NC}"
    else
        echo "Swap فعال است."
    fi
else
    echo "فایل Swap قبلاً وجود دارد."
fi

# -----------------------------------------------------------
# 3. اصلاح فایل hosts برای دسترسی به GitHub
# -----------------------------------------------------------
echo -e "${CYAN}[3/7] بررسی و رفع مشکل دسترسی به GitHub...${NC}"
if ! ping -c 1 github.com &> /dev/null; then
    echo "دسترسی پینگ به GitHub مسدود است. در حال اصلاح /etc/hosts..."
    # بررسی تکراری نبودن
    if ! grep -q "github.com" /etc/hosts; then
        echo "140.82.112.4 github.com" >> /etc/hosts
        echo "140.82.114.9 codeload.github.com" >> /etc/hosts
        echo "185.199.108.133 assets-cdn.github.com" >> /etc/hosts
        echo -e "${GREEN}✅ آی‌پی‌های گیت‌هاب به فایل hosts اضافه شد.${NC}"
    else
        echo "تنظیمات گیت‌هاب قبلاً در hosts وجود دارد."
    fi
else
    echo -e "${GREEN}✅ GitHub قابل دسترس است.${NC}"
fi

# -----------------------------------------------------------
# 4. تست پینگ به IP کاربر و GitHub (بخش اطلاع‌رسانی)
# -----------------------------------------------------------
echo ""
echo -e "${YELLOW}--- بخش 1: بررسی اتصال به اینترنت ایران شما ---${NC}"
read -p "لطفاً IP خود در ایران را وارد کنید (یا اینتر رابرای رد کردن): " MY_IRAN_IP

if [[ -n "$MY_IRAN_IP" ]]; then
    echo "در حال ارسال پینگ به آی‌پی شما: $MY_IRAN_IP ..."
    PING_RESULT=$(ping -c 5 -W 2 $MY_IRAN_IP 2>&1)
    if [[ $? -eq 0 ]]; then
        AVG_PING=$(echo "$PING_RESULT" | tail -1 | awk -F '/' '{print $5}')
        echo -e "${GREEN}✅ متصل شد. میانگین پینگ به شما: $AVG_PING میلی‌ثانیه${NC}"
    else
        echo -e "${RED}⛔ خطا: پینگ برقرار نشد.${NC}"
    fi
fi

echo -e "${YELLOW}--- بخش 2: بررسی اتصال به GitHub ---${NC}"
if timeout 3 bash -c "cat < /dev/null > /dev/tcp/github.com/443"; then
    echo -e "${GREEN}✅ پورت HTTPS باز است (امکان استفاده از git وجود دارد).${NC}"
else
    echo -e "${RED}⛔ دسترسی به GitHub قطع است (مشکل فایروال).${NC}"
fi

echo ""
echo "در ادامه اسکریپت سرور را بهینه می‌کند..."
echo "=========================================="
echo ""

# -----------------------------------------------------------
# 5. تنظیمات سیستم و شبکه (All-in-One + UDP Buffers)
# -----------------------------------------------------------
echo -e "${CYAN}[4/7] اعمال تنظیمات سیستمی و TCP/UDP...${NC}"
timedatectl set-timezone Asia/Tehran

# بهینه‌سازی Swap
sysctl vm.swappiness=10 >> /etc/sysctl.conf 2>/dev/null

# غیرفعال کردن IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# بهینه‌سازی TCP (BBR)
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi

# بهینه‌سازی UDP (حیاتی برای Hysteria2 / Tuic)
echo "net.core.rmem_max = 26214400" >> /etc/sysctl.conf
echo "net.core.rmem_default = 26214400" >> /etc/sysctl.conf
echo "net.core.wmem_max = 26214400" >> /etc/sysctl.conf
echo "net.core.wmem_default = 26214400" >> /etc/sysctl.conf
echo "net.ipv4.udp_rmem_min = 8192" >> /etc/sysctl.conf
echo "net.ipv4.udp_wmem_min = 8192" >> /etc/sysctl.conf
echo "net.ipv4.udp_mem = 65536 131072 262144" >> /etc/sysctl.conf

# اعمال تغییرات
sysctl -p > /dev/null 2>&1

# -----------------------------------------------------------
# 6. پاکسازی و ابزارها
# -----------------------------------------------------------
echo -e "${CYAN}[5/7] پاکسازی و نصب مانیتورینگ...${NC}"
apt install -y bleachbit htop vnstat
apt autoremove -y
apt autoclean -y

# -----------------------------------------------------------
# 7. انتخاب دی‌ان‌س هوشمند (Hybrid: Ping + Dig)
# -----------------------------------------------------------
echo -e "${CYAN}[6/7] اسکن دی‌ان‌س‌ها (Ping + Dig Speed Test)...${NC}"

# مولد لیست بزرگ
generate_massive_dns_list() {
    # ایرانی‌ها
    echo "178.22.122.100" "178.22.122.101" "10.202.10.202" "185.51.200.2" "78.157.42.100" "94.182.36.12"
    # رنج گوگل
    for i in {1..255}; do echo "8.8.8.$i"; done
    # رنج کلودفلر
    for i in {1..255}; do echo "1.1.1.$i"; done
    # رنج کواد ناین
    for i in {1..255}; do echo "9.9.9.$i"; done
    # رنج OpenDNS
    for i in {1..255}; do echo "208.67.222.$i"; done
    # رنج AdGuard
    for i in {1..255}; do echo "94.140.14.$i"; done
}

mapfile -t DNS_LIST < <(generate_massive_dns_list)
TARGET_DOMAIN="google.com"
TOP_CANDIDATES=()
MIN_PING_FOUND=999999

echo "مرحله 1: فیلتر بر اساس پینگ (ICMP)..."

counter=0
for dns in "${DNS_LIST[@]}"; do
    counter=$((counter + 1))
    if (( $counter % 200 == 0 )); then echo "Checking: $counter / ${#DNS_LIST[@]}"; fi

    # پینگ سریع (تایم‌اوت 200 میلی‌ثانیه)
    PING_TIME=$(ping -c 1 -W 0.2 $dns 2>/dev/null | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')

    if [[ -n "$PING_TIME" ]]; then
        # ذخیره کسانی که پینگ زیر 50 میلی‌ثانیه دارند
        if (( $(echo "$PING_TIME < 50" | bc -l) )); then
             TOP_CANDIDATES+=("$dns")
        fi

        # ذخیره کمترین پینگ برای فال‌بک
        if (( $(echo "$PING_TIME < $MIN_PING_FOUND" | bc -l) )); then
            MIN_PING_FOUND=$PING_TIME
        fi
    fi
done

echo "مرحله 2: تست سرعت رزلوشن (DIG) روی کاندیداهای برتر..."

# اگر کاندیدایی پیدا نشد، از بهترین پینگ پیدا شده در کل اسکن استفاده می‌کنیم (فال‌بک)
if [ ${#TOP_CANDIDATES[@]} -eq 0 ]; then
    echo -e "${YELLOW}هیچ دی‌ان‌س سریعتر از 50ms پیدا نشد. استفاده از بهترین گزینه کلی...${NC}"
    # پیدا کردن آن دی‌ان‌س دوباره (ساده‌ترین راه برای اینجا: استفاده از گوگل به عنوان فال‌بک قوی)
    TOP_CANDIDATES=("1.1.1.1" "8.8.8.8" "9.9.9.9")
fi

BEST_DNS=""
FASTEST_DIG_TIME=9999999

for dns in "${TOP_CANDIDATES[@]}"; do
    # تست سرعت کوئری با دستور dig
    # +timeout=1 برای سرعت بیشتر
    START=$(date +%s%N)
    dig @$dns $TARGET_DOMAIN +short +timeout=1 > /dev/null 2>&1
    RESULT=$?
    END=$(date +%s%N)

    if [ $RESULT -eq 0 ]; then
        DIFF=$(( (END - START) / 1000000 )) # تبدیل نانوثانیه به میلی‌ثانیه
        
        echo "DNS: $dns | زمان کوئری: ${DIFF}ms"
        
        if (( DIFF < FASTEST_DIG_TIME )); then
            FASTEST_DIG_TIME=$DIFF
            BEST_DNS=$dns
        fi
    fi
done

# اعمال نهایی
if [ -z "$BEST_DNS" ]; then
    echo -e "${RED}هیچ دی‌ان‌سی در تست DIG موفق نشد. استفاده از 1.1.1.1${NC}"
    BEST_DNS="1.1.1.1"
fi

echo -e "${CYAN}[7/7] تنظیم دی‌ان‌س نهایی...${NC}"
chattr -i /etc/resolv.conf 2>/dev/null
> /etc/resolv.conf
echo "nameserver $BEST_DNS" >> /etc/resolv.conf
echo "nameserver 1.1.1.1" >> /etc/resolv.conf 
chattr +i /etc/resolv.conf

# -----------------------------------------------------------
# پایان
# -----------------------------------------------------------
echo ""
echo "=========================================="
echo "  پایان فرآیند بهینه‌سازی نهایی."
echo "=========================================="
echo -e "${GREEN}✅ Swap: ایجاد/وجود دارد${NC}"
echo -e "${GREEN}✅ GitHub: اصلاح شد (اگر لازم بود)${NC}"
echo -e "${GREEN}✅ UDP Buffers: برای Hysteria2/Tuic تنظیم شد${NC}"
echo -e "${GREEN}✅ DNS: $BEST_DNS (سریع‌ترین رزلوشن)${NC}"
echo "=========================================="
echo ""
