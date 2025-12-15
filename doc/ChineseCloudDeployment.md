# 中国云平台部署指南 / Chinese Cloud Platform Deployment Guide

本指南介绍如何使用阿里云（Alibaba Cloud/Aliyun）、腾讯云（Tencent Cloud）等中国云平台部署 TeslaUSB，使客户能够从任何地方查看他们的特斯拉 Sentry 和行车记录仪视频。

This guide explains how to deploy TeslaUSB using Chinese cloud platforms like Alibaba Cloud (Aliyun) and Tencent Cloud, allowing customers to view their Tesla Sentry and dashcam videos from anywhere.

## 概览 / Overview

中国云平台提供了比国际云服务更快的网络访问速度和更好的稳定性（针对中国大陆用户）。本指南涵盖：

Chinese cloud platforms offer faster network access and better stability for users in mainland China. This guide covers:

1. 阿里云对象存储（OSS）用于视频存档 / Alibaba Cloud OSS for video archiving
2. 腾讯云对象存储（COS）用于视频存档 / Tencent Cloud COS for video archiving
3. 云服务器（ECS/CVM）用于 Web 界面托管 / Cloud servers for web UI hosting
4. CDN 加速访问 / CDN for accelerated access

## 方案选择 / Deployment Options

### 方案 1: 云存储 + 本地 Web 界面 / Cloud Storage + Local Web UI

**适用场景 / Use Case:** 视频存储在云端，使用现有的 TeslaUSB Web UI 进行访问

**优点 / Pros:**
- 无限存储空间 / Unlimited storage
- 数据安全备份 / Data backup
- 使用现有 Web UI / Uses existing web UI
- 成本较低 / Lower cost

**缺点 / Cons:**
- 需要配置 rclone / Requires rclone configuration
- 访问速度取决于网络 / Access speed depends on network

### 方案 2: 完全云端部署 / Full Cloud Deployment

**适用场景 / Use Case:** 在云服务器上托管完整的 TeslaUSB Web 界面

**优点 / Pros:**
- 最快的访问速度 / Fastest access speed
- 可使用 CDN 加速 / Can use CDN
- 专业的运维支持 / Professional operations support

**缺点 / Cons:**
- 成本较高 / Higher cost
- 需要更多配置 / More configuration needed

---

## 阿里云部署 / Alibaba Cloud Deployment

### 使用阿里云 OSS 存储视频 / Using Alibaba Cloud OSS for Video Storage

#### 步骤 1: 创建 OSS Bucket

1. 登录阿里云控制台 / Log in to Alibaba Cloud Console
2. 进入对象存储 OSS / Go to Object Storage Service
3. 创建 Bucket:
   - 区域 / Region: 选择离你最近的区域（如华东2-上海）
   - 存储类型 / Storage Type: 标准存储
   - 读写权限 / Access: 私有
   - 服务器端加密 / Encryption: 启用

#### 步骤 2: 配置访问密钥 / Configure Access Keys

1. 在阿里云控制台创建 AccessKey / Create AccessKey in console
2. 记录 AccessKey ID 和 AccessKey Secret / Note down AccessKey ID and Secret

#### 步骤 3: 在 Raspberry Pi 上配置 rclone

```bash
# 安装 rclone / Install rclone
curl https://rclone.org/install.sh | sudo bash

# 配置 rclone / Configure rclone
rclone config

# 选择以下选项 / Choose the following options:
# n) New remote
# name> aliyun-oss
# Storage> (查找 "Alibaba Cloud Object Storage System" 的编号)
#         (Find the number for "Alibaba Cloud Object Storage System")
#         注意：编号可能因 rclone 版本而异，请在列表中查找
#         Note: Number may vary by rclone version, find it in the list
# provider> Alibaba
# access_key_id> 你的 AccessKey ID / Your AccessKey ID
# access_key_secret> 你的 AccessKey Secret / Your AccessKey Secret
# endpoint> oss-cn-shanghai.aliyuncs.com (根据你的区域选择)
# acl> private
# storage_class> STANDARD
```

#### 步骤 4: 配置 TeslaUSB 使用 rclone

编辑 `/root/.teslaCamArchiveScripts` 文件：

```bash
export ARCHIVE_METHOD=rclone
export RCLONE_DRIVE="aliyun-oss"
export RCLONE_PATH="teslacam-videos"
```

#### 步骤 5: 配置 Web UI 访问云存储

创建 `/root/bin/mount-oss.sh` 脚本：

```bash
#!/bin/bash
# 挂载阿里云 OSS 到本地 / Mount Aliyun OSS locally

# 使用 ossfs 工具
sudo apt-get install -y libfuse-dev automake libtool
git clone https://github.com/aliyun/ossfs.git
cd ossfs
./autogen.sh
./configure
make
sudo make install

# 配置认证 / Configure authentication
echo "your-bucket-name:your-access-key-id:your-access-key-secret" > /etc/passwd-ossfs
chmod 640 /etc/passwd-ossfs

# 挂载 / Mount
mkdir -p /var/www/html/TeslaCam
ossfs your-bucket-name /var/www/html/TeslaCam -ourl=http://oss-cn-shanghai-internal.aliyuncs.com
```

使用现有的 TeslaUSB Web UI 即可访问视频！

---

## 腾讯云部署 / Tencent Cloud Deployment

### 使用腾讯云 COS 存储视频 / Using Tencent Cloud COS for Video Storage

#### 步骤 1: 创建 COS Bucket

1. 登录腾讯云控制台 / Log in to Tencent Cloud Console
2. 进入对象存储 COS / Go to Cloud Object Storage
3. 创建存储桶:
   - 所属地域 / Region: 广州、上海或北京
   - 访问权限 / Access: 私有读写
   - 服务端加密 / Encryption: 启用

#### 步骤 2: 配置访问密钥 / Configure Access Keys

1. 在访问管理中创建 API 密钥 / Create API key in CAM
2. 记录 SecretId 和 SecretKey / Note down SecretId and SecretKey

#### 步骤 3: 在 Raspberry Pi 上配置 rclone

```bash
# 配置 rclone / Configure rclone
rclone config

# 选择以下选项 / Choose the following options:
# n) New remote
# name> tencent-cos
# Storage> (查找 "Tencent Cloud Object Storage" 的编号)
#         (Find the number for "Tencent Cloud Object Storage")
#         注意：编号可能因 rclone 版本而异，请在列表中查找
#         Note: Number may vary by rclone version, find it in the list
# provider> TencentCOS
# env_auth> false
# access_key_id> 你的 SecretId / Your SecretId
# secret_access_key> 你的 SecretKey / Your SecretKey
# endpoint> cos.ap-guangzhou.myqcloud.com (根据你的区域选择)
# acl> private
# storage_class> STANDARD
```

#### 步骤 4: 配置 TeslaUSB 使用 rclone

编辑 `/root/.teslaCamArchiveScripts` 文件：

```bash
export ARCHIVE_METHOD=rclone
export RCLONE_DRIVE="tencent-cos"
export RCLONE_PATH="teslacam-videos"
```

#### 步骤 5: 配置 Web UI 访问云存储

创建 `/root/bin/mount-cos.sh` 脚本：

```bash
#!/bin/bash
# 挂载腾讯云 COS 到本地 / Mount Tencent COS locally

# 使用 cosfs 工具
# 请访问 https://github.com/tencentyun/cosfs/releases 查看最新版本
# Visit https://github.com/tencentyun/cosfs/releases for latest version
# 示例使用 v1.0.19，请根据您的系统和最新版本调整
# Example uses v1.0.19, adjust for your system and latest version
wget https://github.com/tencentyun/cosfs/releases/download/v1.0.19/cosfs_1.0.19-ubuntu20.04_amd64.deb
sudo dpkg -i cosfs_1.0.19-ubuntu20.04_amd64.deb

# 配置认证 / Configure authentication
echo "your-bucket-name:your-secret-id:your-secret-key" > /etc/passwd-cosfs
chmod 640 /etc/passwd-cosfs

# 挂载 / Mount
mkdir -p /var/www/html/TeslaCam
cosfs your-bucket-name /var/www/html/TeslaCam -ourl=http://cos.ap-guangzhou.myqcloud.com -oallow_other
```

使用现有的 TeslaUSB Web UI 即可访问视频！

---

## 云服务器部署 Web UI / Deploy Web UI on Cloud Server

### 阿里云 ECS / Alibaba Cloud ECS

#### 步骤 1: 创建 ECS 实例

1. 登录阿里云控制台
2. 创建 ECS 实例:
   - 镜像 / Image: Ubuntu 20.04 LTS
   - 实例规格 / Type: ecs.t5-lc1m2.small (1核2GB)
   - 网络 / Network: VPC，分配公网 IP
   - 安全组 / Security Group: 允许 80/443 端口

#### 步骤 2: 安装 Nginx 和依赖

```bash
# SSH 连接到 ECS
ssh root@your-ecs-ip

# 更新系统
apt-get update && apt-get upgrade -y

# 安装必要软件
apt-get install -y nginx git fcgiwrap

# 克隆 TeslaUSB Web UI
cd /var/www
git clone https://github.com/marcone/teslausb.git
cp -r teslausb/teslausb-www/html/* /var/www/html/

# 配置 nginx
cp teslausb/teslausb-www/teslausb.nginx /etc/nginx/sites-available/teslausb
ln -s /etc/nginx/sites-available/teslausb /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default

# 重启 nginx
systemctl restart nginx
```

#### 步骤 3: 配置 SSL 证书（使用阿里云 SSL）

```bash
# 方法 1: 使用阿里云免费 SSL 证书
# 在阿里云控制台申请免费 SSL 证书
# 下载证书文件上传到服务器

mkdir -p /etc/nginx/ssl
# 上传证书文件到 /etc/nginx/ssl/

# 更新 nginx 配置
# 添加 SSL 配置到 /etc/nginx/sites-available/teslausb
```

#### 步骤 4: 挂载 OSS 存储

```bash
# 安装 ossfs
apt-get install -y libfuse-dev automake libtool
git clone https://github.com/aliyun/ossfs.git
cd ossfs
./autogen.sh && ./configure && make && make install

# 配置挂载
echo "your-bucket:your-access-key-id:your-access-key-secret" > /etc/passwd-ossfs
chmod 640 /etc/passwd-ossfs

# 自动挂载
echo "ossfs#your-bucket /var/www/html/TeslaCam fuse _netdev,url=http://oss-cn-shanghai-internal.aliyuncs.com,allow_other 0 0" >> /etc/fstab
mount -a
```

### 腾讯云 CVM / Tencent Cloud CVM

配置步骤类似阿里云 ECS，主要差异：

1. 使用 cosfs 替代 ossfs
2. 在腾讯云控制台申请 SSL 证书
3. 使用腾讯云 CDN 加速（可选）

---

## CDN 加速配置 / CDN Configuration

### 阿里云 CDN

1. 在阿里云控制台创建 CDN 域名
2. 配置源站为你的 ECS 公网 IP
3. 启用 HTTPS 加速
4. 配置缓存规则:
   - `.mp4` 文件缓存 1 天
   - `.html` 文件缓存 1 小时

### 腾讯云 CDN

1. 在腾讯云控制台创建 CDN 加速域名
2. 配置源站为你的 CVM 公网 IP
3. 启用 HTTPS
4. 配置缓存策略:
   - 视频文件缓存 24 小时
   - 页面文件缓存 1 小时

---

## 成本估算 / Cost Estimation

### 方案 1: 云存储 + 本地访问

**阿里云 OSS:**
- 存储费用: ¥0.12/GB/月
- 流量费用: ¥0.50/GB
- 100GB 存储 + 50GB/月流量 ≈ ¥37/月

**腾讯云 COS:**
- 存储费用: ¥0.118/GB/月
- 流量费用: ¥0.50/GB
- 100GB 存储 + 50GB/月流量 ≈ ¥36/月

### 方案 2: 完全云端部署

**阿里云 ECS + OSS:**
- ECS (1核2GB): ¥60/月
- OSS 存储: ¥12/月（100GB）
- 流量: ¥25/月（50GB）
- **总计: ¥97/月**

**腾讯云 CVM + COS:**
- CVM (1核2GB): ¥55/月
- COS 存储: ¥12/月（100GB）
- 流量: ¥25/月（50GB）
- **总计: ¥92/月**

---

## 配置示例 / Configuration Examples

### 完整的 TeslaUSB 配置文件

```bash
# /boot/teslausb_setup_variables.conf

# 基础配置 / Basic Configuration
export ARCHIVE_METHOD=rclone
export RCLONE_DRIVE="aliyun-oss"  # 或 tencent-cos
export RCLONE_PATH="teslacam-videos"

# WiFi 配置 / WiFi Configuration
export SSID='Your_WiFi_Name'
export WIFIPASS='Your_WiFi_Password'

# 摄像头存储配置 / Camera Storage
export CAM_SIZE=90%

# 推送通知（可选）/ Push Notifications (Optional)
export PUSHOVER_ENABLED=true
export PUSHOVER_USER_KEY=your_key
export PUSHOVER_APP_KEY=your_app_key
```

### rclone 自动同步脚本

```bash
#!/bin/bash
# /root/bin/sync-to-cloud.sh

# 同步到阿里云 OSS / Sync to Aliyun OSS
rclone sync /mnt/cam/TeslaCam aliyun-oss:teslacam-videos \
  --progress \
  --transfers 4 \
  --checkers 8 \
  --log-file /var/log/rclone-sync.log

# 或同步到腾讯云 COS / Or sync to Tencent COS
# rclone sync /mnt/cam/TeslaCam tencent-cos:teslacam-videos \
#   --progress \
#   --transfers 4 \
#   --checkers 8 \
#   --log-file /var/log/rclone-sync.log
```

---

## 网络访问优化 / Network Access Optimization

### 针对中国大陆用户 / For Mainland China Users

1. **使用国内云服务** / Use domestic cloud services
   - 阿里云和腾讯云在中国有更好的网络连接
   - Aliyun and Tencent Cloud have better connectivity in China

2. **启用 CDN 加速** / Enable CDN acceleration
   - 显著提升视频加载速度
   - Significantly improves video loading speed

3. **选择就近的区域** / Choose nearby regions
   - 华东（上海）、华南（广州）、华北（北京）
   - East China (Shanghai), South China (Guangzhou), North China (Beijing)

### 安全建议 / Security Recommendations

1. **启用 HTTPS** / Enable HTTPS
2. **配置防火墙规则** / Configure firewall rules
3. **定期更新系统** / Regular system updates
4. **使用强密码** / Use strong passwords
5. **启用访问日志** / Enable access logging

---

## 故障排除 / Troubleshooting

### OSS/COS 挂载失败

```bash
# 检查网络连接 / Check network
ping oss-cn-shanghai.aliyuncs.com

# 检查认证文件 / Check credentials
cat /etc/passwd-ossfs

# 查看挂载日志 / View mount logs
tail -f /var/log/syslog
```

### Web UI 无法访问

```bash
# 检查 nginx 状态 / Check nginx status
systemctl status nginx

# 检查防火墙 / Check firewall
ufw status

# 查看 nginx 日志 / View nginx logs
tail -f /var/log/nginx/error.log
```

### 视频上传慢

```bash
# 检查网络速度 / Check network speed
speedtest-cli

# 增加 rclone 并发 / Increase rclone concurrency
rclone config set aliyun-oss transfers 8
```

---

## 技术支持 / Technical Support

- **阿里云文档** / Aliyun Docs: https://help.aliyun.com/product/31815.html
- **腾讯云文档** / Tencent Cloud Docs: https://cloud.tencent.com/document/product/436
- **TeslaUSB GitHub**: https://github.com/marcone/teslausb
- **rclone 文档** / rclone Docs: https://rclone.org/docs/

---

## 总结 / Summary

通过使用阿里云或腾讯云等中国云平台，您可以：

By using Chinese cloud platforms like Alibaba Cloud or Tencent Cloud, you can:

✅ 获得更快的访问速度（针对中国用户）/ Get faster access (for users in China)
✅ 使用现有的 TeslaUSB Web UI / Use the existing TeslaUSB web UI
✅ 无限的云存储空间 / Unlimited cloud storage
✅ 专业的云服务支持 / Professional cloud service support
✅ 成本可控的解决方案 / Cost-effective solution

推荐配置：Raspberry Pi + 阿里云 OSS/腾讯云 COS + 现有 Web UI

Recommended: Raspberry Pi + Aliyun OSS/Tencent COS + Existing Web UI
