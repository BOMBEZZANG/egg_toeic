# Troubleshooting Guide - Firebase Authentication Issues

## 🔴 Error: "User not authenticated. Call initialize() first."

### What This Means
This error occurs when the app tries to save data to Firestore before Firebase Authentication has finished initializing. It's a **timing issue**, not a configuration issue.

### ✅ Solution (Applied)
The code has been updated with two fixes:

#### Fix 1: Added Null Check in UserDataRepository
**File:** `lib/data/repositories/user_data_repository.dart`

The repository now checks if the user is authenticated before saving to Firestore:
```dart
if (_authService.currentUser != null) {
  // Save to Firestore
} else {
  print('⏳ Skipping Firestore sync - authentication not ready yet');
}
```

**Result:**
- App won't crash if auth isn't ready
- Data still saves to Hive (local storage)
- Firestore sync happens on next save when auth is ready

#### Fix 2: Added Delay in Main.dart
**File:** `lib/main.dart`

Added a 300ms delay after auth initialization to ensure auth state propagates:
```dart
await AuthService().initialize();
await Future.delayed(const Duration(milliseconds: 300));
```

**Result:**
- Auth state is fully ready before app starts
- Repositories can safely access user ID

## 📊 Expected Log Output

### ✅ Successful Flow
```
✅ Authentication initialized
Created new anonymous user: Kx7mN2pQ8rZ3sT5vW9y
✅ Auth state ready
✅ Hive storage initialized successfully
✅ User progress synced to Firestore
```

### ⚠️ First Launch (Auth taking longer)
```
✅ Authentication initialized
Created new anonymous user: Kx7mN2pQ8rZ3sT5vW9y
✅ Auth state ready
✅ Hive storage initialized successfully
⏳ Skipping Firestore sync - authentication not ready yet
[... later ...]
✅ User progress synced to Firestore
```

### ❌ Offline Mode
```
✅ Authentication initialized
Existing user found: Kx7mN2pQ8rZ3sT5vW9y
✅ Auth state ready
✅ Hive storage initialized successfully
❌ Error saving user progress to Firestore: [network error]
```

## 🔍 Where to Check Firebase Data

### 1. Check Authentication Status
**Firebase Console → Authentication → Users**

You should see:
- Anonymous users appearing
- Each with unique UID (e.g., `Kx7mN2pQ8rZ3sT5vW9y`)
- Last sign-in timestamp

**❌ If you don't see users:**
- Anonymous auth is not enabled
- Go to: Authentication → Sign-in method
- Enable "Anonymous"

### 2. Check Firestore Data
**Firebase Console → Firestore Database → Data**

After answering questions, you should see:

```
📁 users
  📁 Kx7mN2pQ8rZ3sT5vW9y (your user ID from Authentication)
    📁 progress
      📄 current
        - totalQuestionsAnswered: 10
        - correctAnswers: 8
        - experiencePoints: 100
        - userLevel: 1
        - currentStreak: 1
        - lastStudyDate: timestamp

📁 userAnswers
  📄 abc123... (auto-generated ID)
    - userId: "Kx7mN2pQ8rZ3sT5vW9y"
    - questionId: "P5_L1_001"
    - selectedAnswerIndex: 2
    - isCorrect: true
    - answeredAt: timestamp

📁 questionAnalytics
  📄 P5_L1_001
    - totalAttempts: 25
    - correctAttempts: 20
    - correctPercentage: 80.0
```

**❌ If you don't see data:**
- Check Firestore rules are deployed
- Check app logs for permission errors
- Verify anonymous auth is enabled

## 🎯 Quick Verification Steps

### Step 1: Enable Anonymous Authentication
```
Firebase Console → Authentication → Sign-in method → Anonymous → Enable
```

### Step 2: Deploy Firestore Rules
```
Firebase Console → Firestore Database → Rules →
Copy rules from firestore.rules → Publish
```

### Step 3: Run the App
```bash
flutter clean
flutter pub get
flutter run
```

### Step 4: Check Logs
Look for these messages:
- ✅ Authentication initialized
- ✅ Auth state ready
- ✅ Hive storage initialized successfully

### Step 5: Answer Questions
Answer 2-3 practice questions

### Step 6: Verify in Firebase Console
- Authentication → Users (should see your anonymous user)
- Firestore Database → Data → users → {your-uid} → progress → current

## 🔄 Data Flow Explanation

### Local Storage (Hive)
- **Always works** - even offline
- **Instant** - no network delay
- **Temporary** - lost if app is uninstalled
- Located on device only

### Cloud Storage (Firestore)
- **Requires internet** - syncs when online
- **Persistent** - survives app reinstall
- **Shared** - can sync across devices (future feature)
- Located in Firebase servers

### How They Work Together
```
1. User answers question
   ↓
2. Save to Hive immediately ✅ (always works)
   ↓
3. Try to save to Firestore
   ├─ If auth ready + online → ✅ Sync successful
   ├─ If auth not ready → ⏳ Skip, retry next time
   └─ If offline → ❌ Skip, retry when online
```

**Result:** App always works, even offline!

## 🐛 Common Issues

### Issue 1: "Permission denied" Error
**Symptoms:**
```
❌ Error saving user progress to Firestore:
PERMISSION_DENIED: Missing or insufficient permissions
```

**Cause:** Firestore rules not deployed or incorrect

**Solution:**
1. Copy ALL content from `firestore.rules`
2. Paste into Firebase Console → Firestore → Rules
3. Click "Publish"
4. Wait for confirmation

**Verify rules include:**
```javascript
match /users/{userId} {
  allow read, write: if request.auth != null &&
                       request.auth.uid == userId;
}
```

### Issue 2: Data Saves Locally but Not to Firebase
**Symptoms:**
- App works fine
- Progress is saved when app restarts
- But no data appears in Firestore console

**Causes & Solutions:**

**A. Anonymous Auth Not Enabled**
```
Firebase Console → Authentication → Sign-in method →
Enable "Anonymous" provider
```

**B. User Not in Authentication Tab**
- App creates anonymous user successfully
- Check: Authentication → Users tab
- Should see at least one user

**C. Network Issue**
- Check device has internet connection
- Check Firebase project is active
- Try answering questions while watching Firestore console

### Issue 3: Multiple Users Created
**Symptoms:**
- New user created each time app launches
- Progress not maintained between launches

**Cause:** App data being cleared or auth not persisting

**Solution:**
- Don't clear app data during testing
- Don't uninstall/reinstall frequently
- Firebase Auth automatically persists

### Issue 4: Wrong User ID Format
**Symptoms:**
- User ID still looks like: `anon_123456_789012`
- Not Firebase Auth format: `Kx7mN2pQ8rZ3sT5vW9y`

**Cause:** Old AnonymousUserService still being used somewhere

**Solution:**
- All code should be updated already
- Run: `flutter clean && flutter pub get`
- Check no files import `anonymous_user_service.dart`

## 📱 Testing Checklist

- [ ] Anonymous auth enabled in Firebase Console
- [ ] Firestore rules deployed
- [ ] App runs without crashes
- [ ] Logs show "✅ Authentication initialized"
- [ ] Logs show "✅ Auth state ready"
- [ ] Answered 2-3 questions
- [ ] Anonymous user appears in Firebase Console → Authentication
- [ ] Data appears in Firebase Console → Firestore Database
- [ ] App restart maintains same user ID
- [ ] Progress is maintained after restart

## 🎓 Understanding Anonymous Authentication

### What is Anonymous Authentication?
- **Temporary** user account created automatically
- **No credentials** required (no email, password, etc.)
- **Persistent** - survives app restarts
- **Upgradeable** - can later link to Google, Apple, etc.

### Where is it Stored?
```
Device: Secure local storage (automatic)
Firebase: Authentication → Users tab
```

### What's the UID?
- **Unique identifier** for each user
- **Format:** Random string like `Kx7mN2pQ8rZ3sT5vW9y`
- **Same** across app restarts (persists)
- **Different** if app is uninstalled and reinstalled

### How Long Does it Last?
- **Indefinitely** - until user uninstalls app
- **Automatic persistence** - no code needed
- **Survives:** App updates, phone restarts
- **Doesn't survive:** App uninstall/reinstall

## 🚀 Next Steps

Once everything works:
1. ✅ Test offline mode (turn off wifi, use app, turn on wifi)
2. ✅ Test app restart (close and reopen app)
3. ✅ Monitor Firebase Console for data
4. ✅ Check Firebase usage in Usage tab

## 📞 Still Having Issues?

If problems persist:
1. **Check logs** - Full error messages
2. **Check Firebase Console** - Authentication enabled?
3. **Check Firestore Rules** - Deployed correctly?
4. **Check network** - Device has internet?
5. **Try clean rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

**Last Updated:** 2025-09-30
**Status:** Code fixes applied - ready for testing