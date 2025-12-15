# teslausb

## Intro

Raspberry Pi and other [SBCs](## "Single Board Computers") can emulate a USB drive, so can act as a drive for your Tesla to write dashcam footage to. Because the SBC has full access to the emulated drive, it can:

- automatically copy the recordings to an archive server when you get home
- hold both dashcam recordings and music files
- automatically repair filesystem corruption produced by the Tesla's current failure to properly dismount the USB drives before cutting power to the USB ports
- serve up a web UI to view or download the recordings
- retain more than one hour of RecentClips (assuming large enough storage)

## Documentation

For detailed information about archiving options:

- **[NFS Archiving Support](doc/NFSArchivingSupport.md)** - Comprehensive guide to NFS-based archiving ([中文版](doc/NFSArchivingSupport_CN.md))
  - **[Setup NFS](doc/SetupNFS.md)** - Step-by-step NFS setup guide
- **[Setup Archive Share](doc/SetupShare.md)** - Guide for CIFS/SMB archiving
- **[Setup RSync](doc/SetupRSync.md)** - Guide for rsync-based archiving
- **[Setup RClone](doc/SetupRClone.md)** - Guide for cloud storage archiving

