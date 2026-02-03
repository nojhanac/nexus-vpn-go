#!/bin/bash

# ==========================================
# Blueprint: Professional Automated Installer
# Focus: Secure, Persistent, Modular
# ==========================================

# 1. تنظیمات و متغیرهای ایمن
# استفاده از متغیرها برای جلوگیری از خطای انسانی
INSTALL_DIR="/usr/local/etc/xray"
CONFIG_FILE="$INSTALL_DIR/config.json"
SERVICE_NAME="xray"
LOG_FILE="/var/log/xray_install.log"

# تابع برای لاگ‌گیری (حرفه‌ای بودن)
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# ==========================================
# مرحله ۱: نصب (Installation) - امن و خودکار
# ==========================================
secure_install() {
    log "Phase 1: Installing Dependencies..."
    
    # بروزرسانی لیست پکیج‌ها (برای امنیت)
    apt update -y >> "$LOG_FILE" 2>&1
    
    # نصب ابزارهای ضروری بدون تایید کاربر (Automated)
    # استفاده از --no-install-recommends برای کاهش حمله سطح (Attack Surface)
    DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends curl wget gnupg2 >> "$LOG_FILE" 2>&1
    
    # بررسی موفقیت آمیز بودن نصب
    if [ $? -eq 0 ]; then
        log "✅ Dependencies installed successfully."
    else
        log "❌ Failed to install dependencies."
        exit 1
    fi
}

# ==========================================
# مرحله ۲: تولید کلید (Key Generation) - محلی و امن
# ==========================================
generate_keys_securely() {
    log "Phase 2: Generating Cryptographic Keys..."
    
    # تولید کلیدهای X25519 با استفاده از ابزار Xray
    # این کلیدها روی سرور ساخته می‌شوند و هیچ جایی انتقال داده نمی‌شوند (امنیت بالا)
    KEYS=$(xray x25519)
    
    if [ -z "$KEYS" ]; then
        log "❌ Failed to generate keys. Is Xray installed?"
        exit 1
    fi
    
    # استخراج Private و Public Key
    PRIVATE_KEY=$(echo "$KEYS" | grep "Private key" | awk '{print $3}')
    PUBLIC_KEY=$(echo "$KEYS" | grep "Public key" | awk '{print $3}')
    
    log "✅ Keys generated securely (Local generation)."
}

# ==========================================
# مرحله ۳: نوشتن کانفیگ (Config Writing) - با دسترسی محدود
# ==========================================
write_config_professionally() {
    log "Phase 3: Writing Configuration File..."
    
    # ایجاد دایرکتوری اگر وجود ندارد
    mkdir -p "$INSTALL_DIR"
    
    # استفاده از Heredoc برای نوشتن JSON تمیز
    # سپس دسترسی فایل را روی 600 تنظیم می‌کنیم (فقط روت اجازه خواندن دارد)
    cat <<EOF > "$CONFIG_FILE"
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$(cat /proc/sys/kernel/random/uuid)",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": { "serviceName": "GoogleTalk" },
        "security": "reality",
        "realitySettings": {
          "dest": "www.google.com:443",
          "serverNames": ["www.google.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$(openssl rand -hex 8)"],
          "fingerprint": "chrome"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

    # تنظیم مجوزهای امنیتی (Permission Hardening)
    chmod 600 "$CONFIG_FILE"
    chown root:root "$CONFIG_FILE"
    
    log "✅ Config written to $CONFIG_FILE with restricted permissions (600)."
}

# ==========================================
# مرحله ۴: مدیریت سرویس (Service Management) - پایندار (Persistent)
# ==========================================
manage_service_persistently() {
    log "Phase 4: Managing System Service..."
    
    # فعال‌سازی سرویس برای شروع خودکار بعد از بوت (Persistence)
    systemctl enable "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
    
    # ریستارت سرویس برای اعمال تغییرات
    systemctl restart "$SERVICE_NAME" >> "$LOG_FILE" 2>&1
    
    # بررسی وضعیت سرویس (Health Check)
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log "✅ Service is running and persistent (Enabled on boot)."
    else
        log "❌ Service failed to start. Check logs via 'journalctl -u xray'."
        exit 1
    fi
}

# ==========================================
# اجرای مراحل (Main Execution)
# ==========================================
# اگر روت نباشد، خارج شو
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

echo "Starting Automated Professional Setup..."
secure_install
generate_keys_securely
write_config_professionally
manage_service_persistently

echo "=========================================="
echo -e "${GREEN}All 4 Phases Completed Successfully!${NC}"
echo "Installation is Secure, Persistent, and Automated."
echo "=========================================="
