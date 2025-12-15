# Customer Quick Start Guide - Viewing Your Tesla Videos

This guide helps you access your Tesla Sentry and dashcam videos remotely.

## What You'll Be Able To Do

✓ View Sentry Mode events from anywhere  
✓ Watch dashcam footage with synchronized multi-angle views  
✓ Download video clips to your device  
✓ Browse recent recordings and saved clips  

## Quick Access Methods

### Method 1: Local WiFi (At Home)

**Easiest option - works immediately when you're on the same WiFi network as your Raspberry Pi:**

1. Connect your phone/computer to your home WiFi
2. Open a web browser
3. Go to: `http://teslausb.local`
4. Click the "Viewer" tab to watch videos

**Note:** This only works when you're connected to your home network.

---

### Method 2: Remote Access via Tailscale (Recommended)

**Access your videos from anywhere with a free VPN:**

**One-time setup (5 minutes):**

1. **On your Raspberry Pi:**
   ```bash
   ssh pi@teslausb.local
   curl -fsSL https://tailscale.com/install.sh | sh
   sudo tailscale up
   ```
   Write down the Tailscale hostname shown (e.g., `teslausb.tail12345.ts.net`)

2. **On your phone/computer:**
   - Install Tailscale app from App Store or Google Play
   - Sign in with Google/Microsoft/GitHub account
   - Connect to Tailscale network

3. **Access your videos:**
   - Open browser and go to your Tailscale hostname
   - Bookmark it for easy access

**That's it!** Now you can view videos from anywhere.

---

### Method 3: Public Internet Access (Advanced)

**For advanced users who want a custom domain:**

This requires:
- A domain name (e.g., `myteslavideos.com`)
- Router configuration
- SSL certificate setup

See [ProductionDeployment.md](ProductionDeployment.md) for detailed instructions.

---

## Using the Web Interface

### Main Features

1. **Viewer Tab** (Most Used)
   - Watch Sentry events with synchronized multi-angle views
   - Browse by date: Recent Clips, Saved Clips, or Sentry Clips
   - Play/pause, skip forward/back controls
   - Choose different camera layouts

2. **Recordings Tab**
   - Browse all videos as files
   - Download individual clips
   - View folder structure

3. **Tools Tab**
   - Check storage space
   - View system status
   - Trigger manual sync

### Watching Videos

1. Click the **"Viewer"** tab
2. Select a category (RecentClips, SavedClips, or SentryClips)
3. Choose a date/event from the dropdown menu
4. Videos will automatically sync and play
5. Use the timeline slider to jump to specific times

**Controls:**
- **Play/Pause**: Click the play button or spacebar
- **Skip Back**: ⏪ button (goes back 10 seconds)
- **Skip Forward**: ⏩ button (goes forward 30 seconds)
- **Layout**: Click layout icon to change camera arrangement
- **Fullscreen**: Double-click any camera view

### Multi-Angle Views

Your Tesla records from multiple cameras simultaneously:
- Front camera
- Left repeater (side mirror)
- Right repeater (side mirror)
- Rear camera

All cameras sync automatically as you watch.

---

## Understanding Your Videos

### Video Categories

**RecentClips**
- Last hour of continuous dashcam recording (while driving)
- Organized by date
- Automatically deleted when storage fills up

**SavedClips**
- Videos you manually saved by tapping the camera icon in car
- Preserved permanently until you delete them
- Good for capturing interesting events

**SentryClips**
- Triggered by Sentry Mode when motion/impact detected
- Shows what happened around your parked car
- Includes location on map (if GPS available)

### When Videos Are Available

Videos become available on the web interface:
- **Immediately** if connected to WiFi (home network)
- **Within 5-30 minutes** after parking at home (archive sync)
- **Real-time viewing is not possible** (Tesla limitation)

**Why can't I see live video?**

Tesla's dashcam system only saves video to USB storage, it doesn't stream in real-time. The camera footage must first:
1. Be saved by the car to the USB drive
2. Be archived/copied to the Pi's permanent storage
3. Then become available for viewing

This means there's always a delay between when an event occurs and when you can view it.

---

## Mobile Viewing Tips

**On Phone:**
- Use portrait mode for best layout
- Tap the hamburger menu (☰) to switch tabs
- Pinch to zoom on timeline
- Videos may need WiFi for smooth playback (4G can be slow)

**On Tablet:**
- Landscape mode shows all cameras at once
- Swipe on timeline for precise control
- Full desktop-like experience

---

## Troubleshooting

### Can't Access the Web Interface

**Problem:** Browser says "Site can't be reached"

**Solutions:**
1. Check you're connected to WiFi (for local access)
2. Verify Tailscale is connected (for remote access)
3. Try `http://` instead of `https://`
4. Ping the address: `ping teslausb.local`
5. Find Pi's IP address and try that instead

### Videos Won't Play

**Problem:** Videos load but won't play or are choppy

**Solutions:**
1. Check your internet connection speed
2. Try a different browser (Chrome/Safari recommended)
3. Clear browser cache
4. Reduce video quality settings
5. Try downloading the video instead of streaming

### No Videos Available

**Problem:** Interface loads but shows "No recordings"

**Solutions:**
1. Verify dashcam is enabled in car
2. Check if Sentry Mode was active
3. Confirm car was parked at home long enough to sync
4. Check Pi storage: Tools tab → Disk usage
5. Check archiveloop log in Archiveloop log tab

### Slow Loading

**Problem:** Interface is very slow or times out

**Solutions:**
1. Check WiFi signal strength
2. Reduce number of browser tabs
3. Close other apps using bandwidth
4. Try accessing during off-peak hours
5. Restart your router

---

## Data Usage Considerations

### Storage on Raspberry Pi

- Standard setup: 64-256 GB storage
- ~1 minute of 4-camera video = ~400 MB
- Typical storage holds several hours to days of video
- Old videos auto-delete when storage is full

### Network Data Usage

**Streaming one hour of video uses approximately:**
- 4 cameras simultaneously: ~24 GB
- Single camera: ~6 GB

**Tips to reduce data usage:**
- Download videos on WiFi for later viewing
- Watch single camera angles instead of all 4
- Use lower quality when on cellular data

---

## Privacy and Security

### Your Data

- All videos stored locally on your Raspberry Pi
- No cloud storage (unless you configure it)
- You control who has access
- Videos can be deleted anytime

### Access Control

**Recommended security practices:**
1. Use strong passwords
2. Don't share access credentials
3. Use VPN for remote access (Tailscale)
4. Enable authentication if exposing to internet
5. Regularly update the system

---

## Frequently Asked Questions

**Q: Can I view live video from my cameras?**  
A: No, Tesla doesn't support real-time streaming. Videos are saved to USB and then archived for viewing.

**Q: How long until I can see a Sentry event?**  
A: Usually 5-30 minutes after parking at home, depending on your archive settings.

**Q: Can I share videos with others?**  
A: Yes, download the video and share the file, or share your Tailscale access (not recommended for strangers).

**Q: Will this drain my car's battery?**  
A: No, the Pi runs independently. However, Sentry Mode itself does drain battery (this is a Tesla feature, not related to TeslaUSB).

**Q: Can I use this while driving?**  
A: Yes, but the web interface is meant for viewing saved videos, not real-time monitoring.

**Q: What happens if storage fills up?**  
A: Old videos are automatically deleted to make room (oldest first, except SavedClips).

**Q: Can I download videos to my phone?**  
A: Yes, use the Recordings tab, find the video, and tap the download button.

**Q: Is this official Tesla software?**  
A: No, this is a community-developed open-source project. It's not affiliated with Tesla.

---

## Getting Help

If you need assistance:

1. **Check the documentation:**
   - [Main README](../README.md)
   - [Production Deployment Guide](ProductionDeployment.md)
   - [Setup Guide](OneStepSetup.md)

2. **Check system diagnostics:**
   - Open the web interface
   - Go to "Diagnostics" tab
   - Click "Refresh diagnostics"
   - Review any error messages

3. **Community support:**
   - GitHub Issues: https://github.com/marcone/teslausb/issues
   - Reddit: r/TeslaLounge
   - Tesla Motors Club forums

4. **Contact your installer** (if someone set this up for you)

---

## Next Steps

Now that you know how to access your videos:

1. ✓ Bookmark your access URL
2. ✓ Install Tailscale for remote access
3. ✓ Test viewing a video
4. ✓ Try downloading a clip
5. ✓ Explore different camera layouts
6. ✓ Set up push notifications (optional, see docs)

**Enjoy watching your Tesla adventures!** 🚗📹
