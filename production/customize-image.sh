#!/bin/bash -eu
#
# customize-image.sh
#
# This script customizes an existing TeslaUSB image for production deployment.
# It pre-installs rclone and adds China-optimized configurations.
#
# Usage: sudo ./production/customize-image.sh <image-file>
#
# Example: sudo ./production/customize-image.sh /path/to/teslausb.img
#

set -e

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

function check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (sudo)"
        exit 1
    fi
}

function check_dependencies() {
    local deps=(kpartx qemu-user-static mount)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        print_info "Install with: apt-get install ${missing[*]}"
        exit 1
    fi
}

function mount_image() {
    local image_file="$1"
    local mount_point="/mnt/teslausb_customize"
    local boot_mount="/mnt/teslausb_boot"
    
    print_info "Mounting image: $image_file"
    
    # Create mount points
    mkdir -p "$mount_point" "$boot_mount"
    
    # Setup loop device with partitions
    local loop_dev
    loop_dev=$(losetup --show -fP "$image_file")
    print_info "Loop device: $loop_dev"
    
    # Wait for partitions to appear
    sleep 2
    
    # Mount root partition (usually p2)
    if [ -e "${loop_dev}p2" ]; then
        mount "${loop_dev}p2" "$mount_point"
    else
        print_error "Could not find root partition"
        losetup -d "$loop_dev"
        exit 1
    fi
    
    # Mount boot partition (usually p1)
    if [ -e "${loop_dev}p1" ]; then
        mount "${loop_dev}p1" "$boot_mount"
    fi
    
    # Setup for chroot
    mount --bind /dev "$mount_point/dev"
    mount --bind /proc "$mount_point/proc"
    mount --bind /sys "$mount_point/sys"
    mount --bind /dev/pts "$mount_point/dev/pts"
    
    # Copy qemu binary for ARM emulation
    if [ -f /usr/bin/qemu-arm-static ]; then
        cp /usr/bin/qemu-arm-static "$mount_point/usr/bin/"
    fi
    if [ -f /usr/bin/qemu-aarch64-static ]; then
        cp /usr/bin/qemu-aarch64-static "$mount_point/usr/bin/"
    fi
    
    echo "$loop_dev"
}

function unmount_image() {
    local loop_dev="$1"
    local mount_point="/mnt/teslausb_customize"
    local boot_mount="/mnt/teslausb_boot"
    
    print_info "Unmounting image..."
    
    # Unmount in reverse order
    umount "$mount_point/dev/pts" 2>/dev/null || true
    umount "$mount_point/sys" 2>/dev/null || true
    umount "$mount_point/proc" 2>/dev/null || true
    umount "$mount_point/dev" 2>/dev/null || true
    umount "$boot_mount" 2>/dev/null || true
    umount "$mount_point" 2>/dev/null || true
    
    # Remove loop device
    losetup -d "$loop_dev" 2>/dev/null || true
    
    # Cleanup mount points
    rmdir "$mount_point" "$boot_mount" 2>/dev/null || true
}

function install_rclone() {
    local mount_point="/mnt/teslausb_customize"
    
    print_info "Installing rclone in the image..."
    
    # Install rclone via chroot
    chroot "$mount_point" /bin/bash << 'CHROOT_SCRIPT'
#!/bin/bash
set -e

# Update package list
apt-get update

# Install rclone from repository (preferred method for security)
if apt-get install -y rclone; then
    echo "rclone installed from repository"
else
    echo "Warning: Could not install rclone from repository"
    echo "Please install rclone manually after setup using: curl https://rclone.org/install.sh | sudo bash"
fi

# Install jq for JSON processing
apt-get install -y jq

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
CHROOT_SCRIPT

    print_info "rclone installation complete"
}

function add_china_configs() {
    local mount_point="/mnt/teslausb_customize"
    local boot_mount="/mnt/teslausb_boot"
    
    print_info "Adding China-optimized configurations..."
    
    # Create China config sample
    cat > "$boot_mount/teslausb_setup_china.conf.sample" << 'CHINACONFIG'
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
export CAM_SIZE=40G
#export MUSIC_SIZE=4G

# 时区配置 / Timezone Configuration
export TIME_ZONE="Asia/Shanghai"

# 设备名称 / Device Hostname
export TESLAUSB_HOSTNAME=teslausb
CHINACONFIG

    # Create rclone templates directory
    mkdir -p "$mount_point/root/.config/rclone"
    
    # Create rclone templates
    cat > "$mount_point/root/.config/rclone/templates.conf" << 'RCLONETEMPLATE'
# Rclone Configuration Templates for Chinese Cloud Providers
# 中国云存储配置模板

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
# pass = YOUR_PASSWORD
RCLONETEMPLATE

    # Add production marker
    touch "$boot_mount/PRODUCTION_BUILD"
    
    print_info "China configurations added"
}

function main() {
    if [ $# -lt 1 ]; then
        print_error "Usage: $0 <image-file>"
        exit 1
    fi
    
    local image_file="$1"
    
    if [ ! -f "$image_file" ]; then
        print_error "Image file not found: $image_file"
        exit 1
    fi
    
    check_root
    check_dependencies
    
    local loop_dev
    loop_dev=$(mount_image "$image_file")
    
    # Install and configure
    install_rclone
    add_china_configs
    
    # Cleanup
    unmount_image "$loop_dev"
    
    print_info "Image customization complete!"
    print_info "The image is now ready for production deployment."
}

main "$@"
