# teslausb

## Intro

Raspberry Pi and other [SBCs](## "Single Board Computers") can emulate a USB drive, so can act as a drive for your Tesla to write dashcam footage to. Because the SBC has full access to the emulated drive, it can:

- automatically copy the recordings to an archive server when you get home
- hold both dashcam recordings and music files
- automatically repair filesystem corruption produced by the Tesla's current failure to properly dismount the USB drives before cutting power to the USB ports
- serve up a web UI to view or download the recordings
- retain more than one hour of RecentClips (assuming large enough storage)
- **enable remote access to view Sentry and dashcam videos from anywhere** (see [Production Deployment Guide](doc/ProductionDeployment.md))

## Quick Links

- **For Customers/End Users:** [Customer Quick Start Guide](doc/CustomerQuickStart.md) - Learn how to access and view your Tesla videos
- **For Production Deployment:** [Production Deployment Guide](doc/ProductionDeployment.md) - Deploy TeslaUSB for customer access with security and remote viewing
- **For Initial Setup:** [One-Step Setup Guide](doc/OneStepSetup.md) - Get started with TeslaUSB installation

