#!/bin/bash

# ==========================================
# Script Name: Reality Admin Tunnel Installer
# Description: Auto Install VLESS Reality (Secure & Fast)
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 1. بررسی دسترسی و سیستم عامل
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفا با دسترسی روت (root) اجرا کنید.${NC}"
  exit
fi

if [[ -f /etc/debian_version ]]; then
    echo -e "${GREEN}سیستم عامل سازگار تشخیص داده شد (Debian/Ubuntu).${NC}"
else
    echo -e "${RED}این اسکریپت فقط برای Debian/Ubuntu طراحی شده است.${NC}"
    exit
fi

# 2. دریافت تنظیمات از کاربر
clear
echo "=========================================="
echo "  نصب تونل حرفه‌ای VLESS Reality"
echo "=========================================="
echo ""

# پورت
read -p "پورت تونل را وارد کنید (پیشنهاد: 443) [بعد از اینتر پیش‌فرض استفاده می‌شود]: " PORT
PORT=${PORT:-443}

# SNI (Server Name)
echo "پیشنهاد SNI برای ایران: www.microsoft.com یا www.google.com"
read -p "SNI را وارد کنید [پیش‌فرض: www.microsoft.com]: " SNI
SNI=${SNI:-www.microsoft.com}

# تولید UUID تصادفی
UUID=$(cat /proc/sys/kernel/random/uuid)

echo ""
echo -e "${CYAN}در حال نصب Xray-core...${NC}"

# 3. نصب Xray-core رسمی
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# بررسی موفقیت نصب
if ! command -v xray &> /dev/null; then
    echo -e "${RED}نصب Xray با خطا مواجه شد!${NC}"
    exit
fi

echo -e "${GREEN}✅ Xray-core نصب شد.${NC}"

# 4. تولید کلیدهای Reality
echo -e "${CYAN}در حال تولید کلیدهای امنیتی Reality...${NC}"
# نکته: استفاده از xray برای تولید کلید نیاز به باینری دارد که الان نصب شده است
# دستور زیر Private Key و Public Key می‌سازد
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')

# تولید Short ID تصادفی
SHORT_ID=$(openssl rand -hex 8)

echo -e "${GREEN}✅ کلیدها تولید شدند.${NC}"

# 5. ساخت فایل کانفیگ JSON
CONFIG_FILE="/usr/local/etc/xray/config.json"

echo -e "${CYAN}در حال نوشتن کانفیگ...${NC}"

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
          "dest": "$SNI:443",
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

# 6. باز کردن پورت در فایروال (UFW)
if command -v ufw &> /dev/null; then
    ufw allow $PORT/tcp > /dev/null 2>&1
fi
if command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=$PORT/tcp > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
fi

# 7. راه‌اندازی مجدد سرویس
systemctl restart xray
systemctl enable xray

# دریافت آی‌پی اصلی سرور
SERVER_IP=$(curl -s -4 ip.sb)

# 8. نمایش اطلاعات نهایی
clear
echo "=========================================="
echo -e "${GREEN}     تونل VLESS Reality با موفقیت نصب شد!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}📋 اطلاعات اتصال:${NC}"
echo "----------------------------------------"
echo -e "آدرس سرور (IP): ${CYAN}$SERVER_IP${NC}"
echo -e "پورت (Port):     ${CYAN}$PORT${NC}"
echo -e "UUID:            ${CYAN}$UUID${NC}"
echo -e "SNI:             ${CYAN}$SNI${NC}"
echo -e "PublicKey:       ${CYAN}$PUBLIC_KEY${NC}"
echo -e "ShortID:         ${CYAN}$SHORT_ID${NC}"
echo -e "Flow:            ${CYAN}xtls-rprx-vision${NC}"
echo "----------------------------------------"
echo ""
echo -e "${GREEN}🔗 لینک کپی-پیست (VLESS):${NC}"
echo ""
echo "vless://$UUID@$SERVER_IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#Reality-Tunnel"
echo ""
echo "=========================================="
echo -e "${RED}نکته مهم:${NC} لینک بالا را کپی کرده و در اپلیکیشن V2RayNG (نسخه جدید) یا ClashMeta وارد کنید."
echo ""
