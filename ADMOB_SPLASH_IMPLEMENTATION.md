# AdMob Splash Screen Implementation Guide

## ✅ What Was Implemented

### 1. **Dependencies Added**
- Added `google_mobile_ads: ^5.1.0` to `pubspec.yaml`

### 2. **Files Created/Updated**

#### Created Files:
1. **`lib/core/services/app_open_ad_manager.dart`**
   - Manages app open ad loading and display
   - Handles ad lifecycle (load, show, dispose)
   - Includes timeout mechanism (4 seconds)

2. **`lib/features/splash/splash_screen.dart`**
   - Beautiful animated splash screen with Duolingo-style gradient
   - Loads app open ad in background
   - Navigates to home after showing ad

#### Updated Files:
1. **`lib/ad_helper.dart`**
   - Added `appOpenAdUnitId` method with test IDs

2. **`lib/main.dart`**
   - Added Google Mobile Ads initialization
   - Updated app flow to use new splash screen

3. **`android/app/src/main/AndroidManifest.xml`**
   - Added AdMob App ID meta-data

4. **`ios/Runner/Info.plist`**
   - Added GADApplicationIdentifier
   - Added SKAdNetworkItems for iOS 14+ support

## 🎯 App Loading Flow

```
App Start
    ↓
Initialize MobileAds SDK
    ↓
Splash Screen (2 seconds + animation)
    ↓
Load App Open Ad (max 4 seconds)
    ↓
Show App Open Ad
    ↓
Home Screen
```

## 🧪 Test Ad Unit IDs (Currently Used)

These are Google's official test IDs that will always show test ads:

- **Android App ID**: `ca-app-pub-3940256099942544~3347511713`
- **iOS App ID**: `ca-app-pub-3940256099942544~1458002511`
- **App Open Ad (Android)**: `ca-app-pub-3940256099942544/9257395921`
- **App Open Ad (iOS)**: `ca-app-pub-3940256099942544/5575463023`

## 📱 Next Steps

### 1. Install Dependencies
Run this command in your project directory:
```bash
flutter pub get
```

### 2. Test the Implementation
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

### 3. Before Production Release

#### Replace Test IDs with Real AdMob IDs:

**Step 1: Create AdMob Account**
- Go to https://admob.google.com
- Create an account if you don't have one

**Step 2: Create App in AdMob**
- Add your Android app (package name: com.eggtoeic.egg_toeic)
- Add your iOS app (bundle ID: from your Xcode project)

**Step 3: Create App Open Ad Units**
- Create App Open Ad unit for Android
- Create App Open Ad unit for iOS

**Step 4: Update Configuration Files**

Update `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR-REAL-ANDROID-APP-ID"/>
```

Update `ios/Runner/Info.plist`:
```xml
<key>GADApplicationIdentifier</key>
<string>YOUR-REAL-IOS-APP-ID</string>
```

Update `lib/ad_helper.dart`:
```dart
static String get appOpenAdUnitId {
  if (Platform.isAndroid) {
    return "YOUR-REAL-ANDROID-APP-OPEN-AD-ID";
  } else if (Platform.isIOS) {
    return "YOUR-REAL-IOS-APP-OPEN-AD-ID";
  } else {
    throw new UnsupportedError("Unsupported platform");
  }
}
```

## 🎨 Customization Options

### Adjust Ad Load Timeout
In `lib/core/services/app_open_ad_manager.dart`:
```dart
static const int maxLoadDuration = 4; // Change to desired seconds
```

### Change Splash Screen Duration
In `lib/features/splash/splash_screen.dart`:
```dart
await Future.delayed(const Duration(seconds: 2)); // Change duration
```

### Modify Splash Screen Design
Edit `lib/features/splash/splash_screen.dart` to customize:
- Colors/gradient
- Logo/icon
- Animation timing
- Text content

## ⚠️ Important Notes

1. **Test Ads Only**: Current implementation uses test IDs. Real ads won't show until you replace with production IDs.

2. **Ad Loading**: App open ads may not always load (network issues, ad inventory). The app gracefully handles failures and navigates to home.

3. **Ad Frequency**: Consider implementing frequency capping to avoid showing ads too often (e.g., once per day).

4. **iOS 14+**: SKAdNetwork configuration is required for proper attribution tracking on iOS.

5. **Privacy**: Make sure to implement proper consent forms (GDPR, CCPA) before production release.

## 🐛 Troubleshooting

### Ad Not Showing
1. Check console logs for ad loading errors
2. Verify internet connection
3. Confirm test device is properly configured
4. For iOS simulator, ads may not always show

### Build Errors
1. Run `flutter clean`
2. Run `flutter pub get`
3. For Android: Sync gradle files
4. For iOS: Run `pod install` in ios/ directory

## 📊 Testing Checklist

- [ ] App launches and shows splash screen
- [ ] Splash screen animations work smoothly
- [ ] App open ad loads (check console logs)
- [ ] App open ad displays (or gracefully fails)
- [ ] Navigation to home screen works
- [ ] App doesn't crash if ad fails to load
- [ ] Works on both Android and iOS

## 🔗 Resources

- [Google Mobile Ads Flutter Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob App Open Ads Documentation](https://developers.google.com/admob/flutter/app-open)
- [AdMob Test Ads](https://developers.google.com/admob/android/test-ads)