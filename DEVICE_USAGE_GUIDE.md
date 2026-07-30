# ProCon App - Device Usage Guide

## ✅ Local Storage Backup/Restore

Your app uses **local storage** for backups (stored on device). This works without iCloud or paid developer account.

### Export Backup
1. Open app on your device
2. Go to Results screen (list icon)
3. Tap the ⋮ menu (top right)
4. Select "Export Backup"
5. You'll see: "✓ Exported X entries to local storage"

**Where are backups stored?**
- On your iPhone in the app's documents folder
- Files are named: `ProCon_Backup_YYYY-MM-DD.json`
- Accessible when connected to computer via Files app

### Import Backup
1. Open app
2. Go to Results screen
3. Tap ⋮ menu → "Import Backup"
4. Select a backup from the list
5. You'll see: "✓ Imported X entries from local backup"

### Access Backup Files (when connected to computer)
1. Connect iPhone to Mac
2. Open **Finder**
3. Select your iPhone in sidebar
4. Go to **Files** tab
5. Find **ProCon** app
6. Copy backup files to your Mac for safekeeping

---

## 📱 Using App When Disconnected from Cable

**The Issue:** Free Apple Developer provisioning expires after 7 days, causing app to crash when disconnected.

**The Solution:** Rebuild the app every 7 days to renew the provisioning.

### Option 1: Use the Rebuild Script (Easiest)

1. **Connect your iPhone** via cable
2. Open Terminal and navigate to the project:
   ```bash
   cd /Users/vsudha952@cable.comcast.com/Documents/vinTej_Build_Apps/ProConApp_flutter
   ```
3. Run the rebuild script:
   ```bash
   ./rebuild_for_device.sh
   ```
4. Wait for "✅ Done!" message
5. **Disconnect cable** - app will work for 7 days

### Option 2: Manual Rebuild

1. **Connect iPhone** via cable
2. Open Terminal:
   ```bash
   cd /Users/vsudha952@cable.comcast.com/Documents/vinTej_Build_Apps/ProConApp_flutter
   flutter run --release --device-id=00008120-001651180EF8C01E
   ```
3. Wait for app to launch
4. Press `d` to detach (keeps app running)
5. **Disconnect cable**

### Rebuild Schedule

| Action | When |
|--------|------|
| **Initial Install** | Today |
| **First Rebuild** | Day 7 (or when app stops opening) |
| **Subsequent Rebuilds** | Every 7 days |

**💡 Tip:** Set a weekly reminder on your phone to rebuild every Thursday (or any day you choose).

---

## 🎯 Quick Rebuild Steps

```bash
# 1. Connect iPhone
# 2. Run this command:
cd /Users/vsudha952@cable.comcast.com/Documents/vinTej_Build_Apps/ProConApp_flutter && flutter run --release --device-id=00008120-001651180EF8C01E

# 3. Wait for app to launch
# 4. Disconnect cable - good for 7 more days!
```

---

## ❓ FAQ

**Q: Can I use the app for more than 7 days without rebuilding?**
A: Only with a paid Apple Developer account ($99/year). Free accounts require weekly rebuilds.

**Q: What happens if I forget to rebuild?**
A: The app will crash immediately when you try to open it. Just connect, rebuild, and it will work again.

**Q: Will I lose my data if the app expires?**
A: No! Your data is safe in the local database. After rebuilding, all your entries will still be there.

**Q: Can I export backups to my computer?**
A: Yes! Use Finder → Files tab when iPhone is connected, or create an export and manually copy the JSON file.

**Q: Does rebuild delete my data?**
A: No, rebuild only renews the provisioning. All your saved entries remain intact.

---

## 🔧 Troubleshooting

### App won't build
- Make sure iPhone is unlocked
- Trust this computer on iPhone (if prompted)
- Quit and reopen Xcode if needed

### "No devices found"
```bash
flutter devices  # Check if iPhone is detected
```
- Reconnect cable
- Unlock iPhone
- Accept "Trust Computer" prompt

### Build fails with errors
```bash
flutter clean
flutter pub get
flutter run --release --device-id=00008120-001651180EF8C01E
```

---

**Next Rebuild Due:** Check your calendar reminder!

