# NFS Archiving Support (marcone#1004) - Functionality and Benefits

## Overview

NFS (Network File System) Archiving Support is a network-based archiving solution for TeslaUSB that enables automatic backup of Tesla Sentry Mode and Dashcam recordings to NFS network shares. This feature provides an alternative to CIFS/SMB (Windows file sharing) for users who prefer or require NFS-based storage solutions.

## Functionality

### What is NFS Archiving?

NFS is a distributed file system protocol originally developed by Sun Microsystems that allows remote access to files over a network. The NFS archiving implementation in TeslaUSB provides:

1. **Automatic Recording Archiving**: When your Tesla connects to your home WiFi network, TeslaUSB automatically copies dashcam footage to a configured NFS share on your network-attached storage (NAS) or file server.

2. **Network-Based Storage**: Unlike local storage solutions, NFS archiving allows virtually unlimited storage capacity by leveraging your existing NAS infrastructure.

3. **Reliable File Transfer**: Uses rsync with NFS-specific optimizations to ensure reliable, efficient file transfers.

### Key Features

#### 1. **NFS Protocol Compatibility**
- **NFSv3 Support**: Forced to version 3 for wider NAS compatibility including:
  - Synology NAS systems
  - QNAP NAS systems  
  - Unifi Dream Machine/Router storage
  - Generic Linux NFS servers
  - TrueNAS/FreeNAS systems

#### 2. **Network Stability Enhancements**
- **TCP Protocol**: Uses TCP instead of UDP for better reliability over WiFi
- **nolock Option**: Prevents file locking issues that can cause hangs over wireless connections
- **Connection Monitoring**: Automatically detects and handles network disconnections during archiving

#### 3. **Permission Handling**
The implementation includes special handling for NFS permission issues:
```bash
# From archive-clips.sh
rsync -avhRL --no-o --no-g --remove-source-files --no-perms --omit-dir-times
```
- `--no-o`: Skips ownership preservation (prevents errors on root-squashed shares)
- `--no-g`: Skips group preservation (prevents permission errors)
- `--no-perms`: Doesn't attempt to preserve permissions
- `--omit-dir-times`: Skips directory timestamp updates

These options are critical for NFS shares configured with "root squash" (a common security feature where root access is mapped to an anonymous user).

#### 4. **Reachability Verification**
Before attempting to archive, the system:
- Checks if the NFS server is reachable on port 2049 (NFS standard port)
- Verifies the share is mountable
- Tests write permissions with a test file

#### 5. **Automatic Recovery**
- Connection monitoring kills stuck rsync processes if the network connection is lost
- Retry mechanisms for transient network issues
- Graceful handling of WiFi disconnections

## Configuration

### Basic Setup

Add the following to your `teslausb_setup_variables.conf`:

```bash
# Variables for NFS archiving
export ARCHIVE_SYSTEM=nfs
export ARCHIVE_SERVER=your_nas_ip_or_hostname
export SHARE_NAME='/volume1/TeslaCam'  # Exact export path on NAS
```

### Optional Music Sync

```bash
# Optional: Sync music from NFS share
export MUSIC_SHARE_NAME='/volume1/Music'
export MUSIC_SIZE=4G
```

### Important Notes

1. **SHARE_NAME Must Be Exact**: The NFS share name must match the exact export path configured on your NAS (e.g., `/volume1/TeslaCam` on Synology)

2. **Server Specification**: Can be either IP address or hostname
   - IP recommended for faster resolution and reliability
   - Hostname requires working DNS resolution

3. **Firewall Requirements**: Ensure NFS port 2049 is accessible from the Raspberry Pi to the NAS

## Benefits for Productionalization of Tesla Sentry Cloud in China

### 1. **Infrastructure Flexibility**

**Advantage**: NFS is widely supported across enterprise and consumer-grade storage solutions common in China.

- Compatible with domestic NAS brands (Synology, QNAP widely used in China)
- Works with Chinese cloud storage providers offering NFS support
- Integrates with existing enterprise storage infrastructure

### 2. **Performance Benefits**

**TCP-Based Transfer**: More reliable than SMB/CIFS over high-latency or congested networks
- Better suited for Chinese network conditions with variable connectivity
- Reduced overhead compared to SMB protocol
- More efficient for large file transfers (video footage can be several GB)

### 3. **Linux-Native Protocol**

**Simplified Stack**: NFS is native to Linux (Raspberry Pi OS)
- Less overhead than CIFS/SMB (which requires Samba)
- Better resource utilization on Pi Zero/Pi 3
- More stable under load conditions

### 4. **Security and Compliance**

**Enterprise Security Features**:
- Root squash support (prevents unauthorized root access)
- Kerberos authentication support (available if needed)
- Better suited for enterprise deployment scenarios
- Compliance with local data residency requirements (data stays on local NAS)

### 5. **Cost Efficiency**

**Reduced Cloud Dependency**:
- No reliance on expensive cloud storage services
- Data stored locally on-premises (important for privacy-conscious users in China)
- Lower bandwidth costs (no cloud upload fees)
- One-time NAS investment vs. ongoing cloud subscriptions

### 6. **Scalability**

**Production Deployment Advantages**:
- Single NFS server can handle multiple TeslaUSB clients simultaneously
- Easier to manage at scale (centralized storage management)
- Better suited for fleet management scenarios
- Simplified backup and disaster recovery

### 7. **Network Compatibility**

**Chinese Network Infrastructure**:
- Works well with typical home broadband setups in China
- No dependency on international cloud services (which may have access restrictions)
- Compatible with local network equipment and routers
- Reduces latency (local network vs. internet upload)

### 8. **Regulatory Compliance**

**Data Sovereignty**:
- Keeps all video data within China (important for data localization laws)
- No cross-border data transfer
- Full control over data storage and retention
- Easier to comply with privacy regulations

## Technical Implementation Details

### Mount Options
```bash
mount -t nfs 'ARCHIVE_SERVER:SHARE_NAME' '/mnt/archive' \
  -o 'rw,noauto,nolock,proto=tcp,vers=3'
```

- `rw`: Read-write access
- `noauto`: Not mounted automatically at boot (mounted on-demand)
- `nolock`: No NFS locking (prevents hangs over WiFi)
- `proto=tcp`: Use TCP for better reliability
- `vers=3`: Force NFSv3 for compatibility

### Archive Process Flow

1. **WiFi Connection Detected**: Pi connects to configured home network
2. **Server Reachability Check**: Verifies NFS server accessible on port 2049
3. **Mount Verification**: Tests that share can be mounted and is writable
4. **Connection Monitoring Started**: Background process monitors connection health
5. **File Transfer**: rsync archives new recordings with NFS-optimized options
6. **Cleanup**: Removes transferred files, unmounts share
7. **Return to Standby**: Waits for next archive cycle

### Error Handling

- **Connection Loss**: Automatically kills stuck rsync processes
- **Permission Errors**: Bypassed with `--no-o --no-g --no-perms` options
- **Mount Failures**: Retries with exponential backoff
- **Write Failures**: Logged for troubleshooting, preserves source files

## Comparison with CIFS/SMB

| Feature | NFS | CIFS/SMB |
|---------|-----|----------|
| Protocol Overhead | Lower | Higher |
| Linux Integration | Native | Requires Samba |
| Performance | Better for large files | Variable |
| Configuration | Simpler | More complex |
| Windows Compatibility | Requires extra setup | Native |
| Enterprise Use | Common | Very Common |
| Chinese NAS Support | Excellent | Excellent |

## Use Case Scenarios for China Market

### Scenario 1: Individual Tesla Owner
- **Setup**: Home Synology NAS with NFS enabled
- **Benefit**: Automatic backup without cloud subscription fees
- **Data Privacy**: All footage stays on home network

### Scenario 2: Small Fleet Operator
- **Setup**: Central NFS server for 5-10 vehicles
- **Benefit**: Centralized footage management and monitoring
- **Cost Savings**: No per-vehicle cloud storage costs

### Scenario 3: Enterprise Fleet
- **Setup**: Enterprise storage array with NFS exports
- **Benefit**: Integration with existing IT infrastructure
- **Compliance**: Meets data localization requirements

### Scenario 4: Service Centers
- **Setup**: Local NFS server for customer vehicle diagnostics
- **Benefit**: Quick access to dashcam footage for incident investigation
- **Privacy**: Customer data stays within service center network

## Troubleshooting

### Common Issues and Solutions

1. **"Archive server unreachable on port 2049"**
   - Check firewall settings on NAS
   - Verify NFS service is running
   - Try using IP address instead of hostname

2. **"Unable to mount archive share via NFS"**
   - Verify export path is correct
   - Check NFS export permissions on NAS
   - Ensure Pi's IP is allowed in NFS export rules

3. **"Archive share is not writeable"**
   - Check NFS export has rw (read-write) permission
   - Verify user mapping (avoid root squash issues)
   - Test manual write: `touch /mnt/archive/testfile`

4. **Files not transferring**
   - Check available space on NAS
   - Review logs: `/mutable/archiveloop.log`
   - Verify rsync is not being killed by connection monitor

## Conclusion

NFS Archiving Support provides a robust, efficient, and cost-effective solution for Tesla dashcam footage archiving. For productionalization in China, it offers significant advantages:

- **Better alignment with local infrastructure** (NAS popularity)
- **Improved performance** over variable network conditions
- **Enhanced privacy** (local storage, no cloud dependency)
- **Regulatory compliance** (data sovereignty)
- **Cost efficiency** (no recurring cloud fees)
- **Enterprise-ready** (scalable, manageable)

The implementation is production-ready with comprehensive error handling, optimized for real-world network conditions, and compatible with popular NAS systems deployed in China.

## References

- Original Implementation: marcone#1004
- Source Code: `/run/nfs_archive/`
- Configuration: `/pi-gen-sources/00-teslausb-tweaks/files/teslausb_setup_variables.conf.sample`
- NFS Protocol: RFC 1813 (NFSv3)
