# reality_admin_v3
#!/bin/bash

# ==========================================
# Script Name: Reality Admin v3 (Massive List)
# Description: VLESS Reality with 35+ Premium SNI Options
# ==========================================

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}لطفا با دسترسی روت (root) اجرا کنید.${NC}"
  exit
fi

# -----------------------------------------------------------
# بانک اطلاعاتی بهترین هاست‌ها (SNI Database)
# -----------------------------------------------------------
declare -a HOSTS=(
    "www.microsoft.com"      # 1
    "www.apple.com"          # 2
    "www.google.com"         # 3
    "www.amazon.com"         # 4
    "www.nvidia.com"         # 5
    "www.intel.com"          # 6
    "www.adobe.com"          # 7
    "www.oracle.com"         # 8
    "www.samsung.com"        # 9
    "www.sony.com"           # 10
    "store.steampowered.com" # 11 (Gaming)
    "www.epicgames.com"      # 12 (Gaming)
    "www.ibm.com"            # 13
    "www.cisco.com"          # 14
    "www.dell.com"           # 15
    "www.hp.com"             # 16
    "www.lenovo.com"         # 17
    "www.wikipedia.org"      # 18
    "www.mozilla.org"        # 19
    "www.cloudflare.com"     # 20
    "www.digitalocean.com"   # 21
    "www.atlassian.com"      # 22
    "www.autodesk.com"       # 23
    "www.qualcomm.com"       # 24
    "www.broadcom.com"       # 25
    "www.vmware.com"         # 26
    "www.redhat.com"         # 27
    "www.canon.com"          # 28
    "www.panasonic.com"      # 29
    "www.toshiba.com"        # 30
    "www.asus.com"           # 31
    "www.accenture.com"      # 32
    "www.capgemini.com"      # 33
    "www.bcg.com"            # 34
    "www.mckinsey.com"       # 35
)

clear
echo "=========================================="
echo -e "${GREEN}  نصب تونل VLESS Reality (نسخه حرفه‌ای)${NC}"
echo "=========================================="
echo ""
echo -e "${CYAN}لیست بهترین هاست‌ها برای استتار تونل:${NC}"
echo "--------------------------------------------------------"

# چاپ لیست به صورت حلقه برای جلوگیری از شلوغی کد
for i in "${!HOSTS[@]}"; do
    index=$((i + 1))
    host="${HOSTS[$i]}"
    
    # رنگ‌بندی متفاوت برای دسته‌بندی‌ها (اختیاری برای زیبایی)
    if [ $index -le 5 ]; then
        printf "${BLUE}%-2d)${NC} %-35s ${GREEN}[Tech Giant]${NC}\n" "$index" "$host"
    elif [ $index -le 12 ]; then
        printf "${BLUE}%-2d)${NC} %-35s ${YELLOW}[Gaming/HW]${NC}\n" "$index" "$host"
    else
        printf "${BLUE}%-2d)${NC} %-35s ${CYAN}[Enterprise]${NC}\n" "$index" "$host"
    fi
done

echo "--------------------------------------------------------"
echo -e "${RED}0)  خروج و دستی وارد کردن آدرس (Custom SNI)${NC}"
echo ""

read -p "لطفا شماره مورد نظر را انتخاب کنید: " sni_choice

# -----------------------------------------------------------
# پردازش انتخاب کاربر
# -----------------------------------------------------------

if [[ "$sni_choice" == "0" ]]; then
    read -p "آدرس کامل (مثلاً www.mysite.com): " SNI
    DEST=$SNI
elif [[ "$sni_choice" =~ ^[0-9]+$ ]] && [ "$sni_choice" -ge 1 ] && [ "$sni_choice" -le ${#HOSTS[@]} ]; then
    index=$((sni_choice - 1))
    SNI="${HOSTS[$index]}"
    DEST=$SNI
else
    echo -e "${RED}انتخاب نامعتبر است. از پیش‌فرض مایکروسافت استفاده می‌شود.${NC}"
    SNI="www.microsoft.com"
    DEST="www.microsoft.com"
fi

echo ""
echo -e "${GREEN}✅ هاست انتخاب شد: $SNI${NC}"
echo ""

# -----------------------------------------------------------
# انتخاب پورت
# -----------------------------------------------------------
read -p "پورت تونل را وارد کنید [پیش‌فرض: 443]: " PORT
PORT=${PORT:-443}

# -----------------------------------------------------------
# نصب Xray
# -----------------------------------------------------------
echo -e "${CYAN}در حال نصب آخرین نسخه Xray-core...${NC}"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

if ! command -v xray &> /dev/null; then
    echo -e "${RED}نصب Xray با خطا مواجه شد!${NC}"
    exit
fi

# -----------------------------------------------------------
# تولید کلیدها
# -----------------------------------------------------------
echo -e "${CYAN}در حال تولید کلیدهای امنیتی...${NC}"
KEYS=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)
UUID=$(cat /proc/sys/kernel/random/uuid)

# -----------------------------------------------------------
# ساخت کانفیگ
# -----------------------------------------------------------
CONFIG_FILE="/usr/local/etc/xray/config.json"

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
          "dest": "$DEST:443",
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

# فایروال
if command -v ufw &> /dev/null; then ufw allow $PORT/tcp > /dev/null 2>&1; fi
if command -v firewall-cmd &> /dev/null; then firewall-cmd --permanent --add-port=$PORT/tcp > /dev/null 2>&1; firewall-cmd --reload > /dev/null 2>&1; fi

# ریستارت سرویس
systemctl restart xray
systemctl enable xray

# -----------------------------------------------------------
# نمایش اطلاعات نهایی
# -----------------------------------------------------------
SERVER_IP=$(curl -s -4 ip.sb)

clear
echo "=========================================="
echo -e "${GREEN}     تونل با موفقیت نصب شد!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}📋 اطلاعات اتصال:${NC}"
echo "----------------------------------------"
echo -e "آدرس سرور (IP): ${CYAN}$SERVER_IP${NC}"
echo -e "پورت (Port):     ${CYAN}$PORT${NC}"
echo -e "UUID:            ${CYAN}$UUID${NC}"
echo -e "SNI (Host):      ${CYAN}$SNI${NC}"
echo -e "PublicKey:       ${CYAN}$PUBLIC_KEY${NC}"
echo -e "ShortID:         ${CYAN}$SHORT_ID${NC}"
echo -e "Flow:            ${CYAN}xtls-rprx-vision${NC}"
echo "----------------------------------------"
echo ""
echo -e "${GREEN}🔗 لینک کپی-پیست (برای V2RayNG):${NC}"
echo ""
echo "vless://$UUID@$SERVER_IP:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#Reality-$SNI"
echo ""
echo "=========================================="
echo ""
