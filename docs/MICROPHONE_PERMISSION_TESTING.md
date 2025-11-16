# Microphone Permission Testing Guide

## What Was Fixed

The app now has proper microphone permissions configured:

1. ✅ **Entitlements**: `com.apple.security.device.microphone` is set in `MeetRec.entitlements`
2. ✅ **Info.plist**: `NSMicrophoneUsageDescription` is configured with usage description
3. ✅ **Permission Request**: The app triggers the permission prompt when you start recording

## Why You Don't See It in System Settings Yet

When running from Xcode, the app won't appear in System Settings > Privacy & Security > Microphone **until you actually trigger the permission request** by clicking the "Start Recording" button.

## How to Test

### Step 1: Reset Microphone Permissions (Optional)
If you want to test the permission prompt from scratch:

```bash
tccutil reset Microphone
```

This will reset ALL microphone permissions for all apps.

### Step 2: Run the App from Xcode
1. Open `MeetRec.xcodeproj` in Xcode
2. Click the Run button (or press Cmd+R)
3. Wait for the app to launch

### Step 3: Trigger the Permission Request
1. In the app, select a session from the sidebar (or create a new one)
2. Click the **"Start Recording"** button in the session view
3. You should see a system dialog asking for microphone permission:
   > "MeetRec" Would Like to Access the Microphone
   > 
   > MeetRec needs access to your microphone to record audio during meetings and sessions.
   >
   > [Don't Allow] [OK]

### Step 4: Grant Permission
1. Click **"OK"** to grant permission
2. The app should now appear in System Settings > Privacy & Security > Microphone
3. The mic level indicator should start showing audio levels

### Step 5: Verify It Works
1. Speak into your microphone
2. Watch the red progress bar next to the mic icon - it should move based on your voice level
3. Click "Stop Recording" to stop

## Troubleshooting

### Issue: No Permission Dialog Appears
**Cause**: The app might already have permission, or the permission was previously denied.

**Solution**:
1. Open System Settings > Privacy & Security > Microphone
2. Look for "MeetRec" in the list
3. If it's there and disabled, enable it
4. If it's not there, run `tccutil reset Microphone` and try again

### Issue: Permission Denied Error
**Cause**: You clicked "Don't Allow" on the permission dialog.

**Solution**:
1. Open System Settings > Privacy & Security > Microphone
2. Find "MeetRec" and toggle it ON
3. Restart the app

### Issue: App Crashes When Starting Recording
**Cause**: Audio engine configuration issue.

**Solution**:
1. Check Console.app for error messages
2. Make sure no other app is using the microphone exclusively
3. Try restarting your Mac

## Running from Xcode vs. Standalone App

**From Xcode (Development)**:
- Bundle ID: `eruditedigital.MeetRec` (with Xcode prefix)
- Permissions are requested on first use
- App appears in System Settings after first permission request

**Standalone App (Release)**:
- Bundle ID: `eruditedigital.MeetRec`
- Permissions work the same way
- Better for testing the actual user experience

## Verifying Configuration

You can verify the app is properly configured:

```bash
# Check entitlements
codesign -d --entitlements :- ~/Library/Developer/Xcode/DerivedData/MeetRec-*/Build/Products/Debug/MeetRec.app 2>&1 | grep microphone

# Check Info.plist
plutil -p ~/Library/Developer/Xcode/DerivedData/MeetRec-*/Build/Products/Debug/MeetRec.app/Contents/Info.plist | grep -i microphone
```

Both commands should show the microphone configuration.

## Expected Behavior

✅ **First Time**: Permission dialog appears when you click "Start Recording"
✅ **After Granting**: Recording starts immediately, mic level indicator shows audio
✅ **After Denying**: Error alert appears with "Open System Settings" button
✅ **In System Settings**: App appears in Microphone list after first permission request

## Technical Details

The permission is triggered by:
1. Starting the `AVAudioEngine`
2. Accessing the `inputNode` (microphone)
3. Installing a tap on the audio mixer

This is the standard macOS approach for audio recording apps.
