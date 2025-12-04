#!/bin/bash -eu
#
# first-boot-setup.sh
#
# First-boot setup script for TeslaUSB production devices.
# This script runs on first boot to configure rclone and other production settings.
#
# 产品化设备首次启动配置脚本
# 此脚本在首次启动时运行，用于配置 rclone 和其他生产设置。
#

SETUP_LOG="/var/log/teslausb-first-boot.log"
CONFIG_DIR="/root/.config/rclone"
TEMPLATE_FILE="$CONFIG_DIR/templates.conf"
CONFIG_FILE="$CONFIG_DIR/rclone.conf"
USER_CONFIG="/teslausb/rclone_user.conf"

function log_progress() {
    local msg
    msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$msg" | tee -a "$SETUP_LOG"
}

function check_rclone_installed() {
    if ! command -v rclone &> /dev/null; then
        log_progress "rclone not found, installing..."
        
        # Determine architecture
        local arch
        arch="$(uname -m)"
        case "$arch" in
            aarch64|arm64)
                arch="arm64"
                ;;
            armv7l|armhf)
                arch="arm-v7"
                ;;
            *)
                arch="arm"
                ;;
        esac
        
        # Download and install rclone
        local rclone_url="https://downloads.rclone.org/rclone-current-linux-${arch}.zip"
        local tmp_dir="/tmp/rclone_install"
        
        mkdir -p "$tmp_dir"
        cd "$tmp_dir"
        
        if curl -fsSL -o rclone.zip "$rclone_url"; then
            unzip -q rclone.zip
            cp rclone-*/rclone /usr/local/bin/
            chmod +x /usr/local/bin/rclone
            log_progress "rclone installed successfully"
        else
            log_progress "Failed to download rclone, trying apt-get..."
            apt-get update && apt-get install -y rclone
        fi
        
        rm -rf "$tmp_dir"
    else
        log_progress "rclone is already installed: $(rclone version 2>&1 | head -1)"
    fi
}

function setup_rclone_config() {
    mkdir -p "$CONFIG_DIR"
    
    # Check if user has provided pre-configured credentials
    if [ -f "$USER_CONFIG" ]; then
        log_progress "Found user-provided rclone configuration"
        cp "$USER_CONFIG" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        
        # Move user config to backup
        mv "$USER_CONFIG" "${USER_CONFIG}.used"
        
        # Test the configuration
        if rclone listremotes &> /dev/null; then
            log_progress "rclone configuration verified successfully"
        else
            log_progress "WARNING: rclone configuration may have issues"
        fi
    elif [ -f "$CONFIG_FILE" ]; then
        log_progress "rclone configuration already exists"
    else
        log_progress "No rclone configuration found"
        
        # Copy template for reference
        if [ -f "$TEMPLATE_FILE" ]; then
            cp "$TEMPLATE_FILE" "${CONFIG_FILE}.template"
            log_progress "Template copied to ${CONFIG_FILE}.template"
            log_progress "Please configure rclone using the template"
        fi
    fi
}

function setup_china_timezone() {
    local tz_file="/etc/localtime"
    local china_tz="/usr/share/zoneinfo/Asia/Shanghai"
    
    if [ -f "$china_tz" ]; then
        if [ ! -L "$tz_file" ] || [ "$(readlink -f "$tz_file")" != "$china_tz" ]; then
            log_progress "Setting timezone to Asia/Shanghai"
            ln -sf "$china_tz" "$tz_file"
            echo "Asia/Shanghai" > /etc/timezone
        fi
    fi
}

function install_required_packages() {
    local packages=("jq")
    local need_install=false
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l "$pkg" &> /dev/null; then
            need_install=true
            break
        fi
    done
    
    if [ "$need_install" = true ]; then
        log_progress "Installing required packages..."
        apt-get update
        apt-get install -y "${packages[@]}"
    fi
}

function check_and_fix_permissions() {
    # Ensure config directory has correct permissions
    if [ -d "$CONFIG_DIR" ]; then
        chmod 700 "$CONFIG_DIR"
        if [ -f "$CONFIG_FILE" ]; then
            chmod 600 "$CONFIG_FILE"
        fi
    fi
}

function create_helper_scripts() {
    local helper_dir="/root/bin"
    mkdir -p "$helper_dir"
    
    # Create rclone configuration helper
    cat > "$helper_dir/configure-rclone" << 'HELPER'
#!/bin/bash
#
# 快速配置 rclone 的辅助脚本
# Helper script for quick rclone configuration
#

CONFIG_DIR="/root/.config/rclone"
CONFIG_FILE="$CONFIG_DIR/rclone.conf"
TEMPLATE_FILE="$CONFIG_DIR/templates.conf"

echo "==================================="
echo "rclone 配置向导"
echo "rclone Configuration Wizard"
echo "==================================="
echo ""
echo "选择云存储服务 / Select cloud storage:"
echo "1) 阿里云 OSS (Aliyun)"
echo "2) 腾讯云 COS (Tencent)"
echo "3) 华为云 OBS (Huawei)"
echo "4) 七牛云 (Qiniu)"
echo "5) 坚果云 (Nutstore)"
echo "6) 自定义配置 (Custom - run 'rclone config')"
echo ""
read -p "请选择 [1-6]: " choice

case "$choice" in
    1)
        echo ""
        echo "配置阿里云 OSS..."
        read -p "Access Key ID: " access_key
        read -p "Secret Access Key: " secret_key
        read -p "区域端点 (默认 oss-cn-hangzhou.aliyuncs.com): " endpoint
        endpoint=${endpoint:-oss-cn-hangzhou.aliyuncs.com}
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" << EOF
[aliyunoss]
type = s3
provider = Alibaba
env_auth = false
access_key_id = $access_key
secret_access_key = $secret_key
endpoint = $endpoint
acl = private
EOF
        chmod 600 "$CONFIG_FILE"
        echo "配置完成！测试连接..."
        rclone lsd aliyunoss:
        ;;
    2)
        echo ""
        echo "配置腾讯云 COS..."
        read -p "Secret ID: " access_key
        read -p "Secret Key: " secret_key
        read -p "区域端点 (默认 cos.ap-guangzhou.myqcloud.com): " endpoint
        endpoint=${endpoint:-cos.ap-guangzhou.myqcloud.com}
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" << EOF
[tencentcos]
type = s3
provider = TencentCOS
env_auth = false
access_key_id = $access_key
secret_access_key = $secret_key
endpoint = $endpoint
acl = private
EOF
        chmod 600 "$CONFIG_FILE"
        echo "配置完成！测试连接..."
        rclone lsd tencentcos:
        ;;
    3)
        echo ""
        echo "配置华为云 OBS..."
        read -p "Access Key: " access_key
        read -p "Secret Key: " secret_key
        read -p "区域端点 (默认 obs.cn-north-4.myhuaweicloud.com): " endpoint
        endpoint=${endpoint:-obs.cn-north-4.myhuaweicloud.com}
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" << EOF
[huaweiobs]
type = s3
provider = HuaweiOBS
env_auth = false
access_key_id = $access_key
secret_access_key = $secret_key
endpoint = $endpoint
acl = private
EOF
        chmod 600 "$CONFIG_FILE"
        echo "配置完成！测试连接..."
        rclone lsd huaweiobs:
        ;;
    4)
        echo ""
        echo "配置七牛云..."
        read -p "Access Key: " access_key
        read -p "Secret Key: " secret_key
        read -p "区域端点 (默认 s3-cn-east-1.qiniucs.com): " endpoint
        endpoint=${endpoint:-s3-cn-east-1.qiniucs.com}
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" << EOF
[qiniukodo]
type = s3
provider = Qiniu
env_auth = false
access_key_id = $access_key
secret_access_key = $secret_key
endpoint = $endpoint
acl = private
EOF
        chmod 600 "$CONFIG_FILE"
        echo "配置完成！测试连接..."
        rclone lsd qiniukodo:
        ;;
    5)
        echo ""
        echo "配置坚果云..."
        read -p "邮箱账号: " email
        read -p "WebDAV 密码 (非登录密码): " webdav_pass
        
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_FILE" << EOF
[nutstore]
type = webdav
url = https://dav.jianguoyun.com/dav/
vendor = other
user = $email
pass = $webdav_pass
EOF
        chmod 600 "$CONFIG_FILE"
        echo "配置完成！测试连接..."
        rclone lsd nutstore:
        ;;
    6)
        rclone config
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "配置完成！"
echo "如需修改 teslausb_setup_variables.conf 中的 RCLONE_DRIVE 值"
HELPER

    chmod +x "$helper_dir/configure-rclone"
    log_progress "Helper scripts created in $helper_dir"
}

function main() {
    log_progress "======================================"
    log_progress "Starting TeslaUSB first-boot setup..."
    log_progress "======================================"
    
    # Check if this is actually first boot
    if [ -f "/var/lib/teslausb/first-boot-done" ]; then
        log_progress "First boot setup already completed, skipping..."
        exit 0
    fi
    
    install_required_packages
    check_rclone_installed
    setup_rclone_config
    setup_china_timezone
    check_and_fix_permissions
    create_helper_scripts
    
    # Mark first boot as done
    mkdir -p /var/lib/teslausb
    touch /var/lib/teslausb/first-boot-done
    
    log_progress "======================================"
    log_progress "First-boot setup completed!"
    log_progress "======================================"
    log_progress ""
    log_progress "下一步 / Next steps:"
    log_progress "1. 运行 'configure-rclone' 配置云存储"
    log_progress "   Run 'configure-rclone' to configure cloud storage"
    log_progress "2. 编辑 /root/teslausb_setup_variables.conf"
    log_progress "   Edit /root/teslausb_setup_variables.conf"
    log_progress "3. 运行 /root/bin/setup-teslausb"
    log_progress "   Run /root/bin/setup-teslausb"
}

main "$@"
