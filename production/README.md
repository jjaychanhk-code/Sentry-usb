# TeslaUSB 产品化部署指南

本文档介绍如何将TeslaUSB项目快速部署到Raspberry Pi设备上，用于中国市场的量产。

## 目录

1. [概述](#概述)
2. [系统要求](#系统要求)
3. [量产镜像构建](#量产镜像构建)
4. [首次启动配置](#首次启动配置)
5. [支持的云存储服务](#支持的云存储服务)
6. [故障排除](#故障排除)

## 概述

TeslaUSB是一个将Raspberry Pi模拟成USB存储设备的项目，专为特斯拉车主设计。它可以：

- 自动接收特斯拉行车记录仪和哨兵模式的录像
- 当车辆连接WiFi时，自动上传录像到云存储
- 提供Web界面查看和下载录像
- 自动修复特斯拉造成的文件系统损坏

本产品化方案针对中国市场做了以下优化：

- 预装rclone软件，支持多种国内云存储
- 中文配置界面和文档
- 首次启动向导，简化用户配置
- 预配置的云存储模板

## 系统要求

### 硬件要求
- Raspberry Pi 4B (推荐 4GB 或 8GB 内存版本)
- Raspberry Pi Zero 2 W (便携方案)
- 128GB+ 高速 microSD 卡 (推荐 A2 等级)
- 或 USB 3.0 SSD (Pi 4 推荐方案)

### 软件要求
- Raspberry Pi OS Bookworm (64-bit 推荐)
- 稳定的网络连接用于构建镜像

## 量产镜像构建

### 方法一：使用预构建脚本

```bash
# 克隆仓库
git clone https://github.com/marcone/teslausb.git
cd teslausb

# 运行产品化构建脚本
sudo ./production/build-production-image.sh
```

### 方法二：使用 pi-gen 构建

详见 [pi-gen-sources/Readme.md](../pi-gen-sources/Readme.md)

构建完成后，镜像文件将位于 `deploy` 目录中。

### 方法三：基于现有镜像定制

1. 下载预构建的TeslaUSB镜像
2. 运行产品化定制脚本：

```bash
sudo ./production/customize-image.sh /path/to/teslausb.img
```

## 首次启动配置

产品化镜像包含一个首次启动向导，用户只需：

1. 将SD卡插入Raspberry Pi并通电
2. 使用手机连接 `TeslaUSB-Setup` WiFi热点
3. 打开浏览器访问 `http://192.168.4.1`
4. 按向导完成配置：
   - 选择家庭WiFi网络并输入密码
   - 选择云存储服务商并授权
   - 设置存储空间大小
5. 重启后将设备插入特斯拉USB口

## 支持的云存储服务

### 国内云存储
- 阿里云 OSS (Aliyun OSS)
- 腾讯云 COS (Tencent COS)
- 华为云 OBS (Huawei OBS)
- 百度云 BOS (Baidu BOS)
- 七牛云 (Qiniu Kodo)

### 国际云存储
- Google Drive
- Amazon S3
- Dropbox
- OneDrive
- WebDAV

## 故障排除

### 常见问题

**Q: 设备无法被特斯拉识别？**
A: 确保USB线支持数据传输，部分充电线不支持数据。

**Q: WiFi连接失败？**
A: 检查WiFi名称和密码是否正确，确保使用2.4GHz网络（Pi Zero W不支持5GHz）。

**Q: 云存储上传失败？**
A: 检查云存储授权是否过期，必要时重新授权。

### 获取帮助

- GitHub Issues: https://github.com/marcone/teslausb/issues
- 中文用户群：（待添加）

## 版本历史

- v1.0.0 - 初始产品化版本
