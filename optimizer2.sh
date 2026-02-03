#!/bin/bash

# ==========================================
# Script Name: Ultimate VPS Optimizer v7 (DevOps Edition)
# Features: Auto XanMod Install, Sysctl.d, Docker Aware, Hybrid DNS
# ==========================================

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging Function
log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')]${NC} $1"
}

clear
echo "=========================================="
echo "  VPS Optimizer v7 (DevOps Edition)"
echo "=========================================="
echo ""

# -----------------------------------------------------------
# 1. Auto Install XanMod Kernel (The Performance Booster)
# -----------------------------------------------------------
log "Checking Kernel Version..."
CURRENT_KERNEL=$(uname -r | cut -d. -f1,2)
log "Current Kernel: $CURRENT_KERNEL"

read -p "آیا می‌خواهید هسته XanMod را برای حداکثر سرعت نصب کنید؟ (پیشنهاد می‌شود) [y/N]: " INSTALL_KERNEL

if [[ "$INSTALL_KERNEL" =~ ^[Yy]$ ]]; then
    log "Installing XanMod Kernel... (This takes a minute)"
    
    # تشخیص سیستم عامل برای افزودن مخزن
    if [ -f /etc/debian_version ]; then
        echo "deb http://deb.xanmod.org releases main" > /etc/apt/sources.list.d/xanmod-kernel.list
        wget -qO - https://dl.xanmod.org/gpg.key | apt-key add - > /dev/null 2>&1
        apt update
        apt install -y linux-xanmod-lts
        echo -e "${GREEN}✅ XanMod Kernel نصب شد. نیاز به ریبوت (Reboot) دارید.${NC}"
        # ادامه نمی‌دهیم چون نیاز به ریبوت است
        read -p "آیا الان می‌خواهید ریبوت کنید؟ [y/N]: " REBOOT_NOW
        if [[ "$REBOOT_NOW" =~ ^[Yy]$ ]]; then
            reboot
        fi
        exit 0
    else
        echo "سیستم عامل شما دبیان/اوبونتو نیست، نصب خودکار لغو شد."
    fi
fi

# -----------------------------------------------------------
# 2. Install Dependencies
# -----------------------------------------------------------
log "Installing Tools..."
apt update -y
apt install -y curl wget git net-tools dnsutils bc jq htop vnstat nano sed uuid-runtime

# -----------------------------------------------------------
# 3. Clean Configuration Management (Sysctl.d)
# -----------------------------------------------------------
log "Applying System Tweaks (Professional Mode)..."
SYSCTL_FILE="/etc/sysctl.d/99-vps-optimizer.conf"

# خالی کردن فایل قبلی اگر وجود دارد
> $SYSCTL_FILE

echo "# Optimizations by VPS-Optimizer v7" >> $SYSCTL_FILE
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> $SYSCTL_FILE
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> $SYSCTL_FILE
echo "vm.swappiness = 10" >> $SYSCTL_FILE
echo "net.core.default_qdisc = fq" >> $SYSCTL_FILE
echo "net.ipv4.tcp_congestion_control = bbr" >> $SYSCTL_FILE

# UDP Buffers (Hysteria2/Tuic)
echo "net.core.rmem_max = 26214400" >> $SYSCTL_FILE
echo "net.core.wmem_max = 26214400" >> $SYSCTL_FILE
echo "net.ipv4.udp_rmem_min = 8192" >> $SYSCTL_FILE
echo "net.ipv4.udp_wmem_min = 8192" >> $SYSCTL_FILE

# اعمال تغییرات با پوشه sysctl.d (روش استاندارد)
sysctl --system > /dev/null 2>&1
log "System Tweaks applied via sysctl.d"

# -----------------------------------------------------------
# 4. Docker Check & DNS Handling
# -----------------------------------------------------------
log "Checking for Docker..."
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker تشخیص داده شد.${NC}"
    echo "به جای قفل کردن resolv.conf، تنظیمات Docker انجام می‌شود..."
    
    # تنظیم DNS برای داکر
    if [ ! -f /etc/docker/daemon.json ]; then
        mkdir -p /etc/docker
        echo '{"dns": ["8.8.8.8", "1.1.1.1"]}' > /etc/docker/daemon.json
        systemctl restart docker
        log "Docker DNS configured."
    fi
else
    # اگر داکر نیست، روش معمولی قفل کردن
    log "No Docker found. Applying direct DNS lock."
fi

# -----------------------------------------------------------
# 5. Swap Creation (Professional Way: fallocate)
# -----------------------------------------------------------
log "Checking Swap..."
if [ $(swapon --show | wc -l) -eq 0 ]; then
    log "Creating 1GB Swap file..."
    fallocate -l 1G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
else
    log "Swap already active."
fi

# -----------------------------------------------------------
# 6. GitHub Fix (Hosts)
# -----------------------------------------------------------
log "Fixing GitHub Access..."
if ! ping -c 1 github.com &> /dev/null; then
    if ! grep -q "github.com" /etc/hosts; then
        echo "140.82.112.4 github.com" >> /etc/hosts
        echo "185.199.108.133 assets-cdn.github.com" >> /etc/hosts
        log "GitHub hosts fixed."
    fi
fi

# -----------------------------------------------------------
# 7. Hybrid DNS Selection (Top Tier)
# -----------------------------------------------------------
log "Starting Hybrid DNS Scan..."

generate_dns() {
    echo "8.8.8.8" "1.1.1.1" "9.9.9.9" "208.67.222.222" "94.140.14.14" 
    for i in {1..50}; do echo "8.8.8.$i"; done
    for i in {1..50}; do echo "1.1.1.$i"; done
}
mapfile -t DNS_LIST < <(generate_dns)

TOP_CANDIDATES=()
for dns in "${DNS_LIST[@]}"; do
    PING=$(ping -c 1 -W 0.2 $dns 2>/dev/null | grep 'time=' | sed -n 's/.*time=\([0-9.]*\) ms.*/\1/p')
    if [[ -n "$PING" ]]; then
        if (( $(echo "$PING < 50" | bc -l) )); then
            TOP_CANDIDATES+=("$dns")
        fi
    fi
done

# Dig Speed Test
BEST_DNS="1.1.1.1"
MIN_TIME=999999
TARGET="google.com"

for dns in "${TOP_CANDIDATES[@]}"; do
    START=$(date +%s%N)
    if dig @$dns $TARGET +short +timeout=1 > /dev/null 2>&1; then
        END=$(date +%s%N)
        DIFF=$(( (END - START) / 1000000 ))
        if (( DIFF < MIN_TIME )); then
            MIN_TIME=$DIFF
            BEST_DNS=$dns
        fi
    fi
done

# Apply DNS
if ! command -v docker &> /dev/null; then
    chattr -i /etc/resolv.conf 2>/dev/null
    > /etc/resolv.conf
    echo "nameserver $BEST_DNS" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    chattr +i /etc/resolv.conf
    log "DNS locked to: $BEST_DNS (Query: ${MIN_TIME}ms)"
else
    log "Docker is running, skipping system DNS lock to prevent conflicts."
    log "Best detected DNS for manual use: $BEST_DNS"
fi

# -----------------------------------------------------------
# Finish
# -----------------------------------------------------------
echo ""
echo "=========================================="
echo "  DevOps Optimization Complete."
echo "=========================================="
echo -e "${GREEN}✅ Kernel: XanMod (if chosen) or Current${NC}"
echo -e "${GREEN}✅ Config: /etc/sysctl.d/99-vps-optimizer.conf${NC}"
echo -e "${GREEN}✅ Docker: Compatible${NC}"
echo -e "${GREEN}✅ DNS: $BEST_DNS${NC}"
echo ""
