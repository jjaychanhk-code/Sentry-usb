# NFS Archiving Setup Guide

This guide provides step-by-step instructions for setting up NFS archiving with TeslaUSB.

## Prerequisites

1. A Raspberry Pi (or compatible SBC) with TeslaUSB installed
2. A NAS or file server with NFS support
3. Both devices on the same local network
4. Basic familiarity with text editing and command line

## Step 1: Configure NFS Export on Your NAS

The exact steps vary by NAS model. Here are examples for common systems:

### Synology NAS

1. Open **Control Panel** → **Shared Folder**
2. Create a new shared folder named `TeslaCam` (or use existing)
3. Go to **Control Panel** → **File Services** → **NFS**
4. Enable **NFS service**
5. Click **Apply**
6. Go back to **Shared Folder**, select `TeslaCam`
7. Click **Edit** → **NFS Permissions** → **Create**
8. Configure the rule:
   - **Server or IP address**: Enter your Raspberry Pi's IP address (e.g., `192.168.1.100`)
   - **Privilege**: Read/Write
   - **Squash**: Map all users to admin (or "No mapping" if you prefer)
   - **Security**: sys
   - **Enable asynchronous**: Checked (for better performance)
   - **Allow connections from non-privileged ports**: Checked
9. Click **OK** → **OK**
10. Note the export path (usually `/volume1/TeslaCam`)

### QNAP NAS

1. Open **Control Panel** → **Privilege** → **Shared Folders**
2. Create a new shared folder or select existing
3. Go to **Control Panel** → **Network & File Services** → **NFS Service**
4. Enable **NFS Service**
5. Click **Shared Folders**, select your folder
6. Click **Edit Shared Folder Permissions** → **NFS host access**
7. Click **Add**
8. Configure:
   - **Access right**: Read/Write
   - **Host/Network**: Enter your Pi's IP
   - **Squash**: No squash (or All squash, depending on preference)
9. Click **Finish**
10. Note the export path

### TrueNAS/FreeNAS

1. Go to **Storage** → **Pools**
2. Create a dataset (or use existing)
3. Go to **Sharing** → **Unix (NFS) Shares**
4. Click **Add**
5. Configure:
   - **Path**: Select your dataset
   - **Authorized Networks**: Enter your Pi's IP with /32 (e.g., `192.168.1.100/32`)
6. Click **Submit**
7. Enable the NFS service if prompted
8. Note the export path

### Generic Linux Server

1. Install NFS server:
   ```bash
   sudo apt-get update
   sudo apt-get install nfs-kernel-server
   ```

2. Create export directory:
   ```bash
   sudo mkdir -p /export/teslacam
   sudo chown nobody:nogroup /export/teslacam
   sudo chmod 777 /export/teslacam
   ```

3. Edit `/etc/exports`:
   ```bash
   sudo nano /etc/exports
   ```

4. Add this line (replace `192.168.1.100` with your Pi's IP):
   ```
   /export/teslacam 192.168.1.100(rw,sync,no_subtree_check,no_root_squash)
   ```

5. Export the shares:
   ```bash
   sudo exportfs -ra
   sudo systemctl restart nfs-kernel-server
   ```

## Step 2: Get Your Pi's IP Address and NAS Information

### Find Your Pi's IP Address

If your Pi is already set up and accessible via SSH:

```bash
hostname -I
```

Or from your router's DHCP client list.

### Collect NFS Server Information

You need:
- **NFS Server IP or hostname**: e.g., `192.168.1.10` or `nas.local`
- **Export path**: e.g., `/volume1/TeslaCam` (Synology), `/share/TeslaCam` (QNAP), or `/export/teslacam` (Linux)

## Step 3: Configure TeslaUSB

### Option A: During Initial Setup

If you haven't set up TeslaUSB yet:

1. Download the TeslaUSB image
2. Flash it to your SD card
3. Mount the `boot` partition
4. Create or edit `teslausb_setup_variables.conf` in the boot folder
5. Add the following lines:

```bash
# WiFi Configuration
export SSID='YourWiFiName'
export WIFIPASS='YourWiFiPassword'

# NFS Archive Configuration
export ARCHIVE_SYSTEM=nfs
export ARCHIVE_SERVER=192.168.1.10        # Your NAS IP or hostname
export SHARE_NAME='/volume1/TeslaCam'    # Exact NFS export path

# Drive Size
export CAM_SIZE=40G

# Optional: Music sync from NFS
# export MUSIC_SHARE_NAME='/volume1/Music'
# export MUSIC_SIZE=4G
```

6. Save the file
7. Eject the SD card and insert into your Pi
8. Boot the Pi and wait for setup to complete (can take 20-30 minutes)

### Option B: On Existing TeslaUSB Installation

If TeslaUSB is already set up with a different archive method:

1. SSH into your Pi:
   ```bash
   ssh pi@teslausb.local
   # or
   ssh pi@<pi-ip-address>
   ```

2. Become root:
   ```bash
   sudo -i
   ```

3. Make the filesystem writable:
   ```bash
   /root/bin/remountfs_rw
   ```

4. Edit the configuration file:
   ```bash
   nano /boot/teslausb_setup_variables.conf
   ```

5. Change the archive configuration:
   ```bash
   # Comment out old archive method (add # at the beginning)
   #export ARCHIVE_SYSTEM=cifs
   #export SHARE_USER=username
   #export SHARE_PASSWORD='password'
   
   # Add NFS configuration
   export ARCHIVE_SYSTEM=nfs
   export ARCHIVE_SERVER=192.168.1.10
   export SHARE_NAME='/volume1/TeslaCam'
   ```

6. Save and exit (Ctrl+O, Enter, Ctrl+X)

7. Reconfigure the archive system:
   ```bash
   /root/bin/setup-teslausb configure
   ```

8. Reboot:
   ```bash
   reboot
   ```

## Step 4: Verify the Setup

### Check Archive Configuration

1. SSH into your Pi
2. Become root: `sudo -i`
3. Check if NFS is configured:
   ```bash
   cat /etc/fstab | grep nfs
   ```
   
   You should see something like:
   ```
   192.168.1.10:/volume1/TeslaCam /mnt/archive nfs rw,noauto,nolock,proto=tcp,vers=3 0 0
   ```

### Test NFS Mount

1. Try to mount manually:
   ```bash
   mount /mnt/archive
   ```

2. Check if mounted:
   ```bash
   df -h | grep archive
   ```

3. Test write permission:
   ```bash
   touch /mnt/archive/test.txt
   ls -l /mnt/archive/test.txt
   rm /mnt/archive/test.txt
   ```

4. Unmount:
   ```bash
   umount /mnt/archive
   ```

If all these steps succeed, your NFS setup is working!

### Test Archiving

1. Connect your Pi to your car
2. Drive around or trigger Sentry Mode
3. Disconnect Pi from car
4. Wait for Pi to connect to your WiFi
5. Check the archive logs:
   ```bash
   tail -f /mutable/archiveloop.log
   ```

6. Check your NAS to see if files are being transferred

## Step 5: Optional - Configure Music Sync

If you want to sync music from an NFS share:

1. On your NAS, create a music folder with your MP3 files
2. Set up NFS export for the music folder (same process as Step 1)
3. Edit your TeslaUSB config:
   ```bash
   /root/bin/remountfs_rw
   nano /boot/teslausb_setup_variables.conf
   ```

4. Add these lines:
   ```bash
   export MUSIC_SHARE_NAME='/volume1/Music'  # Your music NFS export path
   export MUSIC_SIZE=4G                       # Size of music drive
   ```

5. Reconfigure:
   ```bash
   /root/bin/setup-teslausb configure
   ```

6. Reboot:
   ```bash
   reboot
   ```

## Troubleshooting

### "Archive server unreachable on port 2049"

**Possible causes:**
- NFS service not running on NAS
- Firewall blocking port 2049
- Wrong IP address

**Solutions:**
1. Verify NFS service is running on your NAS
2. Check firewall settings on NAS
3. Try pinging the NAS from your Pi:
   ```bash
   ping 192.168.1.10
   ```
4. Check if port 2049 is accessible:
   ```bash
   nc -zv 192.168.1.10 2049
   ```

### "Unable to mount archive share via NFS"

**Possible causes:**
- Wrong export path
- Pi's IP not allowed in NFS permissions
- NFS export not configured correctly

**Solutions:**
1. Verify the exact export path on your NAS
2. Check NFS export permissions - ensure your Pi's IP is allowed
3. Check NAS logs for NFS errors
4. Try mounting manually with verbose output:
   ```bash
   mount -v -t nfs 192.168.1.10:/volume1/TeslaCam /mnt/archive -o rw,proto=tcp,vers=3
   ```

### "Archive share is not writeable"

**Possible causes:**
- NFS export configured as read-only
- Permission/ownership issues
- Squash settings preventing write

**Solutions:**
1. Verify NFS export has read/write permissions
2. Check if you can create files manually when mounted
3. Adjust squash settings on NAS (try "No squash" or "Map all users to admin")
4. Check NAS disk space

### Files not transferring

**Check logs:**
```bash
tail -100 /mutable/archiveloop.log
```

**Common issues:**
- Not enough space on NAS
- Network connectivity issues
- Pi not connecting to WiFi

**Solutions:**
1. Verify NAS has free space
2. Check WiFi connection:
   ```bash
   iwconfig
   ```
3. Manually trigger archiving:
   ```bash
   touch /tmp/archive_is_reachable
   ```

### Slow transfers

**Possible causes:**
- Using NFSv4 instead of NFSv3
- Not using TCP
- Weak WiFi signal

**Solutions:**
1. Verify mount options force NFSv3 and TCP (check `/etc/fstab`)
2. Improve WiFi signal strength
3. Consider using wired Ethernet (Pi 3/4 with Ethernet adapter)

## Advanced Configuration

### Using Static IP for Pi

To ensure consistent connection, assign a static IP to your Pi:

1. Edit dhcpcd.conf:
   ```bash
   /root/bin/remountfs_rw
   nano /etc/dhcpcd.conf
   ```

2. Add at the end:
   ```
   interface wlan0
   static ip_address=192.168.1.100/24
   static routers=192.168.1.1
   static domain_name_servers=192.168.1.1
   ```

3. Save and reboot

### Monitoring Archive Status

Check archive status via web interface:
1. Navigate to `http://teslausb.local` or `http://<pi-ip>`
2. View recent archives and status

Or via SSH:
```bash
tail -f /mutable/archiveloop.log
```

## Security Considerations

1. **Network Security**: Ensure your WiFi network is secure (WPA2/WPA3)
2. **NFS Permissions**: Only allow your Pi's IP in NFS export rules
3. **Firewall**: Configure NAS firewall to only accept NFS connections from trusted IPs
4. **Encryption**: NFS doesn't encrypt data in transit - ensure network is trusted
5. **Physical Security**: Secure your Pi to prevent unauthorized access

## Performance Tips

1. **Use Wired Ethernet**: If possible, connect Pi via Ethernet for faster, more reliable transfers
2. **WiFi 5GHz**: If your Pi supports it, use 5GHz WiFi for better performance
3. **Reduce CAM_SIZE**: Smaller cam size means faster archiving
4. **Regular Archiving**: Set shorter `ARCHIVE_DELAY` to archive more frequently with less data
5. **NAS Performance**: Ensure your NAS isn't under heavy load during archiving

## Next Steps

- Set up push notifications to know when archiving completes: [Configure Notifications](ConfigureNotificationsForArchive.md)
- Customize which clips to archive (SavedClips, SentryClips, etc.)
- Set up automatic clip processing with tesla_dashcam
- Configure the web interface for remote viewing

## Additional Resources

- [Main NFS Documentation](NFSArchivingSupport.md) - Detailed explanation of NFS features and benefits
- [中文文档](NFSArchivingSupport_CN.md) - Chinese language documentation
- [TeslaUSB Wiki](https://github.com/marcone/teslausb/wiki) - Community guides and tips
- [NFS Protocol Documentation](https://tools.ietf.org/html/rfc1813) - Technical RFC for NFSv3

## Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review logs: `/mutable/archiveloop.log`
3. Check TeslaUSB GitHub issues
4. Ask on the TeslaUSB Discord/forums

Remember to provide:
- Your hardware (Pi model)
- NAS model and firmware version
- Relevant log excerpts
- Steps you've already tried
