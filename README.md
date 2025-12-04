# teslausb

## Intro

Raspberry Pi and other [SBCs](## "Single Board Computers") can emulate a USB drive, so can act as a drive for your Tesla to write dashcam footage to. Because the SBC has full access to the emulated drive, it can:

- automatically copy the recordings to an archive server when you get home
- hold both dashcam recordings and music files
- automatically repair filesystem corruption produced by the Tesla's current failure to properly dismount the USB drives before cutting power to the USB ports
- serve up a web UI to view or download the recordings
- retain more than one hour of RecentClips (assuming large enough storage)

## Production Deployment (量产部署)

For users in China or those who want to mass-deploy TeslaUSB devices, see the [Production Deployment Guide](production/README.md). Features include:

- Pre-installed rclone with Chinese cloud storage templates (Aliyun OSS, Tencent COS, Huawei OBS, etc.)
- China-optimized configuration templates
- First-boot setup wizard
- Production image build scripts

对于中国用户或需要批量部署TeslaUSB设备的用户，请参阅[产品化部署指南](production/README.md)。

