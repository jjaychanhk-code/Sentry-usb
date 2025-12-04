#!/bin/bash -eu
#
# build-production-image.sh
# 
# This script builds a production-ready TeslaUSB image with pre-installed
# rclone and China-optimized configurations for mass deployment.
#
# Usage: sudo ./production/build-production-image.sh [options]
#
# Options:
#   --output-dir DIR    Directory to place the output image (default: ./deploy)
#   --skip-rclone       Skip rclone pre-installation
#   --china-mirror      Use China mirrors for faster download
#   --help              Show this help message
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${REPO_DIR}/deploy"
USE_CHINA_MIRROR=false
SKIP_RCLONE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

function print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

function show_help() {
    head -20 "$0" | tail -15 | sed 's/^# //'
    exit 0
}

function check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (sudo)"
        exit 1
    fi
}

function check_dependencies() {
    local deps=(git curl wget parted kpartx qemu-user-static)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_warn "Missing dependencies: ${missing[*]}"
        print_info "Installing missing dependencies..."
        apt-get update
        apt-get install -y "${missing[@]}"
    fi
}

function setup_pi_gen() {
    local pi_gen_dir="/tmp/pi-gen"
    
    print_info "Setting up pi-gen build environment..."
    
    if [ -d "$pi_gen_dir" ]; then
        rm -rf "$pi_gen_dir"
    fi
    
    git clone --depth 1 https://github.com/RPi-Distro/pi-gen.git "$pi_gen_dir"
    
    # Apply TeslaUSB customizations
    cd "$pi_gen_dir"
    "${REPO_DIR}/pi-gen-sources/prepare.sh"
    
    # Add production customizations
    add_production_stage
    
    echo "$pi_gen_dir"
}

function add_production_stage() {
    local stage_dir="stage_production"
    
    print_info "Adding production customizations..."
    
    mkdir -p "$stage_dir/00-production-setup"
    
    # Create the package list for production
    if [ "$SKIP_RCLONE" = false ]; then
        cat > "$stage_dir/00-production-setup/00-packages" << 'PACKAGES'
rclone
jq
PACKAGES
    else
        cat > "$stage_dir/00-production-setup/00-packages" << 'PACKAGES'
jq
PACKAGES
    fi

    # Create the production setup script
    cat > "$stage_dir/00-production-setup/01-run.sh" << 'RUNSCRIPT'
#!/bin/bash -e

# Install China-optimized configuration templates
install -m 666 files/teslausb_setup_china.conf.sample "${ROOTFS_DIR}/boot/firmware/"

# Pre-configure rclone templates for Chinese cloud providers
mkdir -p "${ROOTFS_DIR}/root/.config/rclone"
install -m 600 files/rclone_templates.conf "${ROOTFS_DIR}/root/.config/rclone/templates.conf"

# Install first-boot setup script for consumers
install -m 755 files/first-boot-setup.sh "${ROOTFS_DIR}/root/bin/"

# Set production marker
touch "${ROOTFS_DIR}/boot/firmware/PRODUCTION_BUILD"
RUNSCRIPT

    chmod +x "$stage_dir/00-production-setup/01-run.sh"
    
    # Create the files directory
    mkdir -p "$stage_dir/00-production-setup/files"
    
    # Copy production files
    cp "${SCRIPT_DIR}/files/teslausb_setup_china.conf.sample" "$stage_dir/00-production-setup/files/" 2>/dev/null || \
        create_china_config "$stage_dir/00-production-setup/files/"
    
    cp "${SCRIPT_DIR}/files/rclone_templates.conf" "$stage_dir/00-production-setup/files/" 2>/dev/null || \
        create_rclone_templates "$stage_dir/00-production-setup/files/"
    
    cp "${SCRIPT_DIR}/files/first-boot-setup.sh" "$stage_dir/00-production-setup/files/" 2>/dev/null || \
        create_first_boot_script "$stage_dir/00-production-setup/files/"
    
    # Add production stage to build
    sed -i 's/STAGE_LIST="\(.*\)"/STAGE_LIST="\1 stage_production"/' config
    
    touch "$stage_dir/EXPORT_IMAGE"
}

function create_china_config() {
    local dest_dir="$1"
    
    cat > "$dest_dir/teslausb_setup_china.conf.sample" << 'CHINACONFIG'
#####################################################################
# TeslaUSB 中国用户配置模板
# China-optimized Configuration Template for TeslaUSB
#####################################################################

# WiFi 配置 / WiFi Configuration
export SSID='你的WiFi名称'
export WIFIPASS='你的WiFi密码'

# 云存储配置 / Cloud Storage Configuration
# 选择以下存储方案之一 / Choose one of the following storage options:

# 方案1: 阿里云 OSS (推荐国内用户)
# Option 1: Aliyun OSS (Recommended for China)
export ARCHIVE_SYSTEM=rclone
export RCLONE_DRIVE="aliyunoss"
export RCLONE_PATH="TeslaCam"

# 方案2: 腾讯云 COS
# Option 2: Tencent COS
#export ARCHIVE_SYSTEM=rclone
#export RCLONE_DRIVE="tencentcos"
#export RCLONE_PATH="TeslaCam"

# 方案3: 本地 NAS (CIFS/SMB)
# Option 3: Local NAS (CIFS/SMB)
#export ARCHIVE_SYSTEM=cifs
#export ARCHIVE_SERVER=192.168.1.100
#export SHARE_NAME='TeslaCam'
#export SHARE_USER=username
#export SHARE_PASSWORD='password'

# 存储空间配置 / Storage Configuration
# 行车记录仪空间（推荐40G-60G）
export CAM_SIZE=40G
# 音乐空间（可选）
#export MUSIC_SIZE=4G

# 时区配置 / Timezone Configuration
export TIME_ZONE="Asia/Shanghai"

# 设备名称 / Device Hostname
export TESLAUSB_HOSTNAME=teslausb

# 通知配置（可选）/ Notification Configuration (Optional)
# 微信推送可通过 Webhook 实现
#export WEBHOOK_ENABLED=true
#export WEBHOOK_URL="https://your-wechat-webhook-url"
CHINACONFIG
}

function create_rclone_templates() {
    local dest_dir="$1"
    
    cat > "$dest_dir/rclone_templates.conf" << 'RCLONETEMPLATE'
# Rclone Configuration Templates for Chinese Cloud Providers
# 中国云存储配置模板
#
# To use a template, copy the relevant section to /root/.config/rclone/rclone.conf
# and fill in your credentials.
#
# 使用方法：将相应配置复制到 /root/.config/rclone/rclone.conf 并填写您的凭据

# =====================================================
# Aliyun OSS (阿里云对象存储)
# =====================================================
# [aliyunoss]
# type = s3
# provider = Alibaba
# env_auth = false
# access_key_id = YOUR_ACCESS_KEY_ID
# secret_access_key = YOUR_SECRET_ACCESS_KEY
# endpoint = oss-cn-hangzhou.aliyuncs.com
# acl = private

# =====================================================
# Tencent COS (腾讯云对象存储)
# =====================================================
# [tencentcos]
# type = s3
# provider = TencentCOS
# env_auth = false
# access_key_id = YOUR_SECRET_ID
# secret_access_key = YOUR_SECRET_KEY
# endpoint = cos.ap-guangzhou.myqcloud.com
# acl = private

# =====================================================
# Huawei OBS (华为云对象存储)
# =====================================================
# [huaweiobs]
# type = s3
# provider = HuaweiOBS
# env_auth = false
# access_key_id = YOUR_ACCESS_KEY
# secret_access_key = YOUR_SECRET_KEY
# endpoint = obs.cn-north-4.myhuaweicloud.com
# acl = private

# =====================================================
# Qiniu Kodo (七牛云存储)
# =====================================================
# [qiniukodo]
# type = s3
# provider = Qiniu
# env_auth = false
# access_key_id = YOUR_ACCESS_KEY
# secret_access_key = YOUR_SECRET_KEY
# endpoint = s3-cn-east-1.qiniucs.com
# acl = private

# =====================================================
# WebDAV (通用 WebDAV 存储)
# =====================================================
# [webdav]
# type = webdav
# url = https://your-webdav-server.com/dav
# vendor = other
# user = YOUR_USERNAME
# pass = YOUR_PASSWORD (use: rclone obscure YOUR_PASSWORD)
RCLONETEMPLATE
}

function create_first_boot_script() {
    local dest_dir="$1"
    
    cat > "$dest_dir/first-boot-setup.sh" << 'FIRSTBOOTSCRIPT'
#!/bin/bash -eu
#
# First-boot setup script for TeslaUSB production devices
# 产品化首次启动配置脚本
#

SETUP_LOG="/var/log/teslausb-first-boot.log"

function log_progress() {
    local msg="$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$msg" | tee -a "$SETUP_LOG"
}

function check_rclone_installed() {
    if ! command -v rclone &> /dev/null; then
        log_progress "rclone not found, installing..."
        curl https://rclone.org/install.sh | bash
    else
        log_progress "rclone is already installed: $(rclone version | head -1)"
    fi
}

function setup_rclone_config() {
    local config_dir="/root/.config/rclone"
    local config_file="$config_dir/rclone.conf"
    
    mkdir -p "$config_dir"
    
    if [ ! -f "$config_file" ]; then
        log_progress "Creating rclone config from template..."
        
        # Check if user has pre-configured their credentials
        if [ -f "/teslausb/rclone_user.conf" ]; then
            cp "/teslausb/rclone_user.conf" "$config_file"
            log_progress "Using user-provided rclone configuration"
        else
            # Copy template for user to configure
            cp "$config_dir/templates.conf" "$config_file.template"
            log_progress "rclone template copied. Please configure your cloud storage."
        fi
    fi
}

function main() {
    log_progress "Starting TeslaUSB first-boot setup..."
    
    check_rclone_installed
    setup_rclone_config
    
    log_progress "First-boot setup completed."
}

main "$@"
FIRSTBOOTSCRIPT

    chmod +x "$dest_dir/first-boot-setup.sh"
}

function build_image() {
    local pi_gen_dir="$1"
    
    print_info "Building production image..."
    
    cd "$pi_gen_dir"
    
    if [ "$USE_CHINA_MIRROR" = true ]; then
        print_info "Using China mirrors for faster download..."
        export APT_PROXY="https://mirrors.aliyun.com/raspbian/raspbian/"
    fi
    
    # Build the image
    if command -v docker &> /dev/null; then
        print_info "Building with Docker..."
        ./build-docker.sh
    else
        print_info "Building natively..."
        ./build.sh
    fi
    
    # Copy the output image
    mkdir -p "$OUTPUT_DIR"
    cp deploy/*.img* "$OUTPUT_DIR/"
    
    print_info "Image built successfully!"
    print_info "Output: ${OUTPUT_DIR}/"
}

function parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --skip-rclone)
                SKIP_RCLONE=true
                shift
                ;;
            --china-mirror)
                USE_CHINA_MIRROR=true
                shift
                ;;
            --help|-h)
                show_help
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

function main() {
    parse_args "$@"
    
    check_root
    check_dependencies
    
    local pi_gen_dir
    pi_gen_dir=$(setup_pi_gen)
    
    build_image "$pi_gen_dir"
    
    print_info "Production image build complete!"
    print_info "The image is ready for mass deployment."
}

main "$@"
