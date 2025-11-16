# Debug Recording Issues

## Changes Made

I've updated the `AudioService` to:

1. ✅ Install tap on **input node** (not mixer) using native hardware format
2. ✅ Add extensive logging with emoji markers for easy tracking
3. ✅ Call `engine.prepare()` before starting
4. ✅ Better error handling and reporting

## How to Debug

### Step 1: Open Xcode Console
1. Run the app from Xcode (Cmd+R)
2. Open the **Console** pane at the bottom (Cmd+Shift+Y)
3. Look for messages starting with 🎤

### Step 2: Start Recording
1. Select or create a session
2. Click "Start Recording"
3. Watch the console for these messages:

**Expected Output:**
```
🎤 Starting recording with source: micOnly
🎤 Input format: 48000.0Hz, 2 channels
🎤 Audio engine setup complete
✅ Audio engine started successfully
🎤 Recording started
🎤 Audio level: 0.15 (RMS: 0.075)  // This appears occasionally when you speak
```

**If Permission Denied:**
```
❌ Failed to start audio engine: [error details]
```

### Step 3: Check for Permission Dialog

When you click "Start Recording", you should see a system dialog:

> **"MeetRec" Would Like to Access the Microphone**
> 
> MeetRec needs access to your microphone to record audio during meetings and sessions.
>
> [Don't Allow] [OK]

**If you don't see this dialog:**
- The permission might already be granted
- Or it might be denied
- Check System Settings > Privacy & Security > Microphone

### Step 4: Test Audio Levels

1. After granting permission, speak into your microphone
2. Watch the console for audio level messages (appears randomly ~1% of the time)
3. Watch the red progress bar in the UI - it should move with your voice

## Common Issues

### Issue 1: No Console Output
**Problem**: You don't see any 🎤 messages

**Solution**: 
- Make sure you're looking at the correct target's console output
- Filter console by "MeetRec" or "🎤"

### Issue 2: "Failed to start audio engine"
**Problem**: Engine fails to start

**Possible Causes**:
1. Another app is using the microphone exclusively
2. No microphone is connected
3. Permission was denied

**Solution**:
```bash
# Check if any app is using the microphone
lsof | grep -i audio

# Reset microphone permissions
tccutil reset Microphone
```

### Issue 3: Engine Starts But No Audio Levels
**Problem**: Console shows "Recording started" but no audio level messages

**Possible Causes**:
1. Microphone is muted in System Settings
2. Wrong input device selected
3. Audio tap not receiving data

**Solution**:
1. Check System Settings > Sound > Input
2. Make sure the correct microphone is selected
3. Test the microphone in another app (like Voice Memos)
4. Check input level in System Settings - speak and watch the meter

### Issue 4: Permission Dialog Never Appears
**Problem**: No system dialog when clicking "Start Recording"

**This is the key issue!** The permission dialog should appear the first time you try to access the microphone.

**Debug Steps**:
1. Check if permission already exists:
   ```bash
   # Check TCC database
   sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db "SELECT * FROM access WHERE service='kTCCServiceMicrophone';"
   ```

2. Reset and try again:
   ```bash
   tccutil reset Microphone
   ```

3. Check Console.app for TCC (Transparency, Consent, and Control) messages:
   - Open Console.app
   - Filter by "TCC"
   - Run the app and click "Start Recording"
   - Look for messages about microphone access

## Verification Commands

```bash
# 1. Verify entitlements are embedded
codesign -d --entitlements :- ~/Library/Developer/Xcode/DerivedData/MeetRec-*/Build/Products/Debug/MeetRec.app 2>&1 | grep microphone

# 2. Verify Info.plist has usage description
plutil -p ~/Library/Developer/Xcode/DerivedData/MeetRec-*/Build/Products/Debug/MeetRec.app/Contents/Info.plist | grep -i microphone

# 3. Check current microphone permissions
tccutil reset Microphone  # This will reset ALL apps

# 4. List audio devices
system_profiler SPAudioDataType
```

## What Should Happen

1. **First Run**: Click "Start Recording" → Permission dialog appears → Grant permission → Recording starts → Audio levels appear
2. **Subsequent Runs**: Click "Start Recording" → Recording starts immediately → Audio levels appear

## Next Steps

1. Run the app from Xcode
2. Open the Console pane
3. Click "Start Recording"
4. **Copy and paste the console output** so we can see what's happening
5. Let me know:
   - Did the permission dialog appear?
   - What messages do you see in the console?
   - Does the mic level indicator move when you speak?
