#!/bin/bash

# ==========================================
# Script Name: Warp Manager (Integrated with Reality)
# Description: Install & Configure Cloudflare Warp (Normal & Proxied)
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفا با دسترسی روت (root) اجرا کنید.${NC}"
  exit
fi

# -----------------------------------------------------------
# تابع: نصب ابزارهای لازم
# -----------------------------------------------------------
install_warp_dependencies() {
    echo -e "${CYAN}در حال نصب ابزارهای لازم برای Warp...${NC}"
    apt update -y
    apt install -y curl gnupg lsb-release
    
    # نصب wg-easy اگر نیاز بود، اما اینجا از سرویس رسمی cloudflare-warp استفاده می‌کنیم
    # دانلود باینری رسمی Warp
    if [ ! -f "/usr/local/bin/warp-cli" ]; then
        echo "دانلود Warp CLI..."
        # نکته: warp-cli برای لینوکس سرور معمولا GUI دارد، پس از warp-go یا wgcf استفاده می‌کنیم
        # که مخصوص سرور و بدون رابط کاربری است.
        
        # نصب wgcf (رایگان و محبوب برای سرور)
        curl -fsSL https://github.com/ViRb3/wgcf/releases/latest/download/wgcf_2.2.22_linux_amd64.tar.gz -o wgcf.tar.gz
        tar xzf wgcf.tar.gz
        mv wgcf /usr/local/bin/
        rm wgcf.tar.gz
        chmod +x /usr/local/bin/wgcf
        
        echo -e "${GREEN}✅ ابزار wgcf نصب شد.${NC}"
    else
        echo "ابزار wgcf قبلاً نصب شده است."
    fi
}

# -----------------------------------------------------------
# تابع: ثبت نام در Warp و دریافت کانفیگ
# -----------------------------------------------------------
register_warp() {
    if [ -f "wgcf-account.toml" ]; then
        echo -e "${YELLOW}فایل اکانت قبلی وجود دارد. آیا می‌خواهید دوباره ثبت نام کنید؟ (y/n)${NC}"
        read -p ">" re_reg
        if [[ "$re_reg" != "y" ]]; then
            echo "استفاده از اکانت قبلی..."
        else
            rm -f wgcf-account.toml wgcf-profile.conf
            register_warp
            return
        fi
    fi

    echo -e "${CYAN}در حال ثبت نام در Cloudflare Warp...${NC}"
    wgcf register
    echo -e "${GREEN}✅ ثبت نام موفقیت‌آمیز بود.${NC}"
}

# -----------------------------------------------------------
# تابع: حالت معمولی (Normal Mode)
# -----------------------------------------------------------
warp_normal_mode() {
    echo -e "${CYAN}در حال فعال‌سازی Warp (حالت معمولی برای کل سرور)...${NC}"
    
    # ساخت کانفیگ
    wgcf generate
    
    # ایجاد کانفیگ Wireguard
    # معمولاً فایل wgcf-profile.conf تولید می‌شود که باید تبدیل شود یا مستقیماً استفاده شود
    # اینجا ساده‌ترین روش (فقط اتصال) را پیاده می‌کنیم
    
    # نصب wireguard-tools
    apt install -y wireguard-tools
    
    # کپی کانفیگ
    cp wgcf-profile.conf /etc/wireguard/wgcf.conf
    
    # فعال‌سازی سرویس
    wg-quick up wgcf
    systemctl enable wg-quick@wgcf
    
    echo -e "${GREEN}✅ Warp در حالت معمولی فعال شد.${NC}"
    echo "برای تست پینگ: ping cloudflare.com"
}

# -----------------------------------------------------------
# تابع: حالت پارکسی (Proxied Mode) - پیشرفته
# -----------------------------------------------------------
# این حالت Warp را روی یک پورت (مثلاً 40000) باز می‌کند تا Reality از آن استفاده کند
warp_proxied_mode() {
    echo -e "${CYAN}در حال فعال‌سازی Warp (حالت پارکسی برای تونل Reality)...${NC}"
    
    # تولید کانفیگ
    wgcf generate
    
    # تغییر پورت listened در کانفیگ برای استفاده به عنوان socks5 یا http proxy
    # اما روش استاندارد برای اتصال Xray به Warp این است که Warp را به عنوان Outbound تنظیم کنیم.
    # برای سادگی در این اسکریپت، Warp را روی پورت 40000 به عنوان Proxy HTTP/SOCKS راه‌اندازی می‌کنیم (با کمک tinyproxy یا گو-ورپ)
    
    # در اینجا ما روش "WireGuard to Socks" را استفاده می‌کنیم
    
    # نصب ابزار تبدیل WireGuard به Socks (wgsocks)
    # یا استفاده از گو-ورپ گوگل
    # برای سادگی و سرعت، از اسکریپت warp-go (gvisor-tun2socks) استفاده می‌کنیم که مستقیماً ساکس می‌دهد.
    
    # دانلود warp-go (نسخه سبک و سریع برای سرور)
    echo "در حال دانلود warp-go (Proxy Server)..."
    curl -fsSL https://github.com/iPmartNetwork/warp-go/releases/download/v1.0.7/warp-go_amd64 -o /usr/local/bin/warp-go
    chmod +x /usr/local/bin/warp-go
    
    # ثبت نام با warp-go
    /usr/local/bin/warp-go register
    
    # اجرای warp-go در بک‌گراند روی پورت 40000
    # این دستور یک پروکسی SOCKS5 روی پورت 40000 می‌سازد که از Warp عبور می‌کند
    nohup /usr/local/bin/warp-go run --socks5 :40000 > /dev/null 2>&1 &
    
    echo -e "${GREEN}✅ Warp Proxy روی پورت 40000 فعال شد.${NC}"
    echo -e "${YELLOW}برای استفاده در Xray، باید Outbound را به 127.0.0.1:40000 تغییر دهید.${NC}"
}

# -----------------------------------------------------------
# تابع: اتصال به منوی اصلی Reality (پل ارتباطی)
# -----------------------------------------------------------
connect_to_reality_config() {
    CONFIG_FILE="/usr/local/etc/xray/config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}فایل کانفیگ Reality یافت نشد!${NC}"
        echo "لطفاً ابتدا تونل Reality را نصب کنید."
        return
    fi

    read -p "آیا می‌خواهید ترافیک تونل Reality را از Warp عبور دهید؟ (y/n): " choice
    
    if [[ "$choice" == "y" ]]; then
        echo -e "${CYAN}در حال تغییر کانفیگ Xray برای استفاده از Warp...${NC}"
        
        # تغییر فایل JSON به صورت دستی با sed
        # ما outbound "freedom" را به outbound socks5 تغییر می‌دهیم
        
        # ساختن بکاپ
        cp $CONFIG_FILE $CONFIG_FILE.bak
        
        # جایگزینی outbound
        # این یک روش ساده است. در حالت واقعی باید با jq جیسون را پارس کرد
        sed -i 's/"protocol": "freedom"/"protocol": "socks", "settings": { "servers": [ { "address": "127.0.0.1", "port": 40000 } ] }/g' $CONFIG_FILE
        
        systemctl restart xray
        
        echo -e "${GREEN}✅ تونل Reality اکنون از Warp عبور می‌کند!${NC}"
        echo "IP خروجی شما IP ابری کلادفلر خواهد بود."
    fi
}

# -----------------------------------------------------------
# منوی اصلی Warp
# -----------------------------------------------------------
while true; do
    clear
    echo "=========================================="
    echo -e "${CYAN}     Warp Manager (Manager)${NC}"
    echo "=========================================="
    echo ""
    echo "1) نصب Warp (Normal Mode) - برای کل سرور"
    echo "2) نصب Warp (Proxied Mode) - روی پورت 40000"
    echo "3) اتصال Warp به Reality (Integrate)"
    echo "4) حذف Warp"
    echo "0) بازگشت"
    echo "------------------------------------------"
    read -p "انتخاب: " warp_choice

    case $warp_choice in
        1)
            install_warp_dependencies
            register_warp
            warp_normal_mode
            read -p "اینتر برای بازگشت..."
            ;;
        2)
            install_warp_dependencies
            # register_warp # warp-go خودش ثبت نام می‌کند اگر فایل نباشد
            warp_proxied_mode
            read -p "اینتر برای بازگشت..."
            ;;
        3)
            connect_to_reality_config
            read -p "اینتر برای بازگشت..."
            ;;
        4)
            wg-quick down wgcf > /dev/null 2>&1
            pkill -f warp-go
            echo -e "${RED}Warp غیرفعال شد.${NC}"
            read -p "اینتر برای بازگشت..."
            ;;
        0)
            exit
            ;;
        *)
            echo "گزینه نامعتبر."
            sleep 1
            ;;
    esac
done
