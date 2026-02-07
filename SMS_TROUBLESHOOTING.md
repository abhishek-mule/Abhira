# SMS Not Sending - Troubleshooting Guide

## ✅ What I Fixed

### 1. **Added Missing SMS Permissions**
**File**: `android/app/src/main/AndroidManifest.xml`

Added these required permissions:
```xml
<uses-permission android:name="android.permission.SEND_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
```

### 2. **Created SMS Test Screen**
**File**: `lib/Dashboard/Settings/SMSTestScreen.dart`

A dedicated debug screen to:
- Check SMS permissions
- Send test SMS to any number
- View real-time status
- See detailed logs

**Access**: Settings → Test SMS

### 3. **Improved SMS Service**
**File**: `lib/services/sms_service.dart`

- Added better error handling
- Added timeout for Fast2SMS API (10 seconds)
- Added delay between messages to avoid rate limiting
- Better logging with emojis for easy debugging
- Returns success/failure status

### 4. **Updated Dashboard Integration**
**File**: `lib/Dashboard/Dashboard.dart`

- Shows SMS status in toast message
- Better logging for debugging
- Captures SMS send success/failure

---

## 🔍 How to Debug SMS Issues

### Step 1: Check Permissions
1. Open the app
2. Go to **Settings → Test SMS**
3. Click **"1. Check SMS Permissions"**
4. If denied, grant permission when prompted

### Step 2: Test SMS Sending
1. Enter your own phone number (e.g., `9876543210` or `+919876543210`)
2. Click **"2. Send Test SMS"**
3. Check your phone for the SMS
4. Check the terminal/logcat for detailed logs

### Step 3: Check Logs
Look for these log messages in the terminal:

**Success Indicators:**
```
📱 Initiating SMS send to X contacts...
📶 Online: Attempting to send via Fast2SMS API...
✅ SMS Sent successfully via Fast2SMS to X recipient(s)
```

OR

```
📵 No Internet or API Key missing. Sending via Native SMS...
📤 Sending SMS to XXXXXXXXXX...
✅ SMS Sent to XXXXXXXXXX
```

**Error Indicators:**
```
❌ SMS Permission Denied
❌ Fast2SMS API Error: [error message]
❌ Error sending SMS to [number]: [error]
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "SMS Permission Denied"
**Solution**: 
- Go to phone Settings → Apps → Abhira → Permissions
- Enable SMS permission manually
- Restart the app

### Issue 2: "Fast2SMS API timeout"
**Solution**:
- Check internet connection
- Verify API key in `.env` file
- The app will automatically fallback to Native SMS

### Issue 3: "No SMS received"
**Possible Causes**:
1. **Wrong number format**: Use 10 digits (9876543210) or with country code (+919876543210)
2. **SIM card issue**: Native SMS requires an active SIM card
3. **Network issue**: Check if you can send SMS manually from the phone
4. **DND (Do Not Disturb)**: Some carriers block promotional SMS

### Issue 4: "Fast2SMS API Error"
**Possible Causes**:
1. **No API key**: Add `FAST2SMS_API_KEY=your_key_here` to `.env`
2. **Invalid API key**: Verify the key from Fast2SMS dashboard
3. **Free plan limits**: Fast2SMS free plan has restrictions (may only send to registered numbers)

---

## 📋 Testing Checklist

Before your hackathon demo:

- [ ] SMS permissions granted
- [ ] Test SMS sent successfully to your own number
- [ ] Test with internet ON (Fast2SMS)
- [ ] Test with internet OFF (Native SMS)
- [ ] Check terminal logs for errors
- [ ] Verify SOS alert triggers SMS
- [ ] Verify location link is included in SMS

---

## 🎯 For Hackathon Demo

### Recommended Setup:
1. **Use Native SMS** (more reliable for demo)
   - Don't add Fast2SMS API key
   - App will automatically use Native SMS
   - Works offline

2. **Test before demo**
   - Send test SMS to yourself
   - Verify it works with SOS button
   - Check that location link is clickable

3. **During Demo**
   - Show the toast message: "SOS Alert Sent via WhatsApp & SMS"
   - Show the received SMS on another phone
   - Show the clickable Google Maps link

---

## 📱 Next Steps

1. **Rebuild the app** to apply the new permissions:
   ```bash
   flutter run
   ```

2. **Test SMS** using the new Test SMS screen

3. **Check logs** in the terminal for any errors

4. **Report back** what you see in the logs

---

## 🆘 Still Not Working?

If SMS still doesn't send after following all steps:

1. **Share the terminal logs** (copy the output after triggering SOS)
2. **Check if you can send SMS manually** from your phone's default SMS app
3. **Try on a different device** (some phones have strict SMS restrictions)
4. **Verify SIM card** is inserted and active

---

**Created**: 2026-02-07
**Last Updated**: 2026-02-07 16:45 IST
