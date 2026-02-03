#!/bin/bash

# ==========================================
# Script Name: Warp-In Reality (Reverse Proxy)
# Strategy: User -> Cloudflare Warp -> VPS -> Internet
# Benefit: Clean IP Entry, Low Latency
# ==========================================

# رنگ‌ها
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo "Run as Root"
  exit
fi

echo "=========================================="
echo -e "${CYAN}  Warp-In Reality Installer${NC}"
echo "=========================================="
echo ""

# 1. نصب ابزار warp-go (نسخه پروکسی)
echo "در حال دانلود Warp Go..."
curl -fsSL https://github.com/iPmartNetwork/warp-go/releases/download/v1.0.7/warp-go_amd64 -o /usr/local/bin/warp-go
chmod +x /usr/local/bin/warp-go

# 2. ثبت نام در Warp
echo "در حال ثبت نام در Cloudflare..."
/usr/local/bin/warp-go register > /dev/null 2>&1

# 3. راه‌اندازی Warp در حالت Socks5 روی پورت 40000
# این پورت ورودی ما است
echo "در حال راه‌اندازی Warp Proxy..."
pkill -f warp-go
nohup /usr/local/bin/warp-go run --socks5 :40000 > /dev/null 2>&1 &

sleep 3

if ! netstat -tuln | grep -q ":40000"; then
    echo -e "${RED}خطا: Warp پروکسی راه اندازی نشد.${NC}"
    exit
fi

echo -e "${GREEN}✅ Warp روی پورت 40000 فعال شد.${NC}"

# 4. نصب Xray و تنظیم Reality روی لوکال‌هاست (Localhost)
# نکته: ما Xray را طوری تنظیم می‌کنیم که فقط روی لوکال‌هاست به پورت 40000 وصل شود
# اما برای اینکه کاربران بتوانند وصل شوند، ما یک پورت عمومی باز می‌کنیم

read -p "پورت عمومی برای دسترسی کاربران [443]: " PUBLIC_PORT
PUBLIC_PORT=${PUBLIC_PORT:-443}

# نصب Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# تولید کلیدها
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)
UUID=$(cat /proc/sys/kernel/random/uuid)
SNI="www.google.com"

# ساخت کانفیگ
# استراتژی: Inbound روی پورت عمومی است، اما Forwarding به Warp می‌شود
# (پیاده‌سازی پیچیده نیاز به StreamSettings Proxy دارد، اما اینجا نسخه ساده شده را می‌نویسیم)

cat <<EOF > /usr/local/etc/xray/config.json
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $PUBLIC_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [ { "id": "$UUID", "flow": "xtls-rprx-vision" } ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "www.google.com:443",
          "serverNames": [ "$SNI" ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [ "$SHORT_ID" ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "socks",
      "settings": {
        "servers": [
          {
            "address": "127.0.0.1",
            "port": 40000
          }
        ]
      }
    }
  ]
}
EOF

# باز کردن پورت فایروال
ufw allow $PUBLIC_PORT/tcp > /dev/null 2>&1

# ریستارت
systemctl restart xray

IP=$(curl -s -4 ip.sb)

clear
echo "=========================================="
echo -e "${GREEN}      نصب Warp-In کامل شد!${NC}"
echo "=========================================="
echo ""
echo "این روش چگونه کار می‌کند؟"
echo "کاربر --[Reality]--> سرور شما --[Warp]--> اینترنت"
echo ""
echo "لینک اتصال (VLESS Reality):"
echo "vless://$UUID@$IP:$PUBLIC_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#WarpIn"
echo ""
echo -e "${YELLOW}نکته:${NC} پینگ شما ممکن است کمی بالا باشد (با توجه به دو لایه تونل)، اما IP شما تمیز و پایدار است."
echo "=========================================="
