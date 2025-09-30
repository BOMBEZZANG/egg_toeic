# Firebase Setup Guide - Complete Instructions

## Overview
This guide walks you through the complete Firebase setup required for the Egg TOEIC app with Firebase Authentication.

## 🔥 Firebase Console Setup Steps

### Step 1: Enable Firebase Authentication

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your project: `egg-toeic` (or your project name)

2. **Navigate to Authentication**
   - Click on **"Authentication"** in the left sidebar
   - If this is first time, click **"Get Started"**

3. **Enable Anonymous Sign-in**
   - Click on the **"Sign-in method"** tab
   - Find **"Anonymous"** in the providers list
   - Click on **"Anonymous"**
   - Toggle **"Enable"** to ON
   - Click **"Save"**

   **✅ Success Indicator:**
   - Anonymous should show "Enabled" status

4. **Verify Authentication Settings**
   - Go to **"Settings"** tab (gear icon)
   - Scroll to **"Authorized domains"**
   - Ensure your domains are listed:
     - `localhost` (for development)
     - Your app's domain (if applicable)

### Step 2: Configure Firestore Database

1. **Navigate to Firestore Database**
   - Click on **"Firestore Database"** in the left sidebar
   - If not created yet, click **"Create database"**

2. **Choose Database Mode**
   - Select **"Start in production mode"** (we'll add rules next)
   - Click **"Next"**

3. **Choose Database Location**
   - Select a region close to your users (e.g., `asia-northeast3` for Korea)
   - Click **"Enable"**
   - Wait for database creation (takes ~30 seconds)

### Step 3: Deploy Firestore Security Rules

1. **Open Rules Tab**
   - In Firestore Database, click on the **"Rules"** tab

2. **Copy and Paste Rules**
   - Open your project file: `/mnt/c/Projects/egg_toeic/firestore.rules`
   - Copy the ENTIRE content
   - Paste into the Firebase Console rules editor
   - Replace all existing rules

3. **Publish Rules**
   - Click **"Publish"** button
   - Wait for confirmation message

4. **Verify Rules**
   - Click on **"Rules"** tab again
   - Verify you see the updated rules
   - Check that `users/{userId}` rules are present

### Step 4: Set Up Indexes (If Needed)

1. **Navigate to Indexes**
   - In Firestore Database, click on **"Indexes"** tab

2. **Check for Index Requirements**
   - Firebase will automatically prompt you to create indexes when needed
   - Watch your app logs for "Index required" messages
   - Click the provided link to auto-create the index

### Step 5: Verify Firebase Configuration Files

**For Android:**

1. Check `android/app/google-services.json` exists
   - This file should already be in your project
   - If missing, download from Firebase Console:
     - Project Settings → Your apps → Android app
     - Download `google-services.json`
     - Place in `android/app/` folder

2. Verify `android/app/build.gradle` has:
   ```gradle
   dependencies {
       // ... other dependencies
       implementation platform('com.google.firebase:firebase-bom:32.7.0')
   }
   ```

**For iOS:**

1. Check `ios/Runner/GoogleService-Info.plist` exists
2. If missing, download from Firebase Console:
   - Project Settings → Your apps → iOS app
   - Download `GoogleService-Info.plist`
   - Add to Xcode project

## 🔧 Fix the "User not authenticated" Error

The error occurs because data is being saved before authentication completes. Here's the fix:

### Option 1: Add Delay to Repository Initialization (Recommended)

Update `lib/data/repositories/user_data_repository.dart`:

```dart
Future<void> _saveUserProgressToHive() async {
  if (_hiveInitialized && _progressBox != null) {
    try {
      await _progressBox!.put('progress', _userProgress.toJson());
    } catch (e) {
      print('❌ Error saving user progress to Hive: $e');
    }
  }

  // Also save to Firestore - with auth check
  try {
    // Check if user is authenticated before saving
    if (_authService.currentUser != null) {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('progress')
          .doc('current')
          .set(_userProgress.toJson(), SetOptions(merge: true));
    } else {
      print('⏳ Skipping Firestore sync - authentication not ready yet');
    }
  } catch (e) {
    print('❌ Error saving user progress to Firestore: $e');
  }
}
```

### Option 2: Ensure Proper Initialization Order (Also Recommended)

Update `lib/main.dart` to ensure repositories initialize AFTER auth:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize Authentication - MUST complete before repositories
  try {
    await AuthService().initialize();
    print('✅ Authentication initialized');

    // Small delay to ensure auth state is fully propagated
    await Future.delayed(Duration(milliseconds: 500));
  } catch (e) {
    print('⚠️ Auth initialization failed, continuing with offline mode');
  }

  runApp(
    const ProviderScope(
      child: EggToeicApp(),
    ),
  );
}
```

## 🎯 What Gets Stored Where

### Firebase Authentication
**Location:** Firebase Console → Authentication → Users tab

**Stored Data:**
- User ID (UID): `abc123xyz...`
- Provider: Anonymous
- Created date
- Last sign-in date

**Example:**
```
User UID: Kx7mN2pQ8rZ3sT5vW9y
Provider: Anonymous
Created: Jan 20, 2025
Last sign-in: Jan 20, 2025
```

### Firestore Database
**Location:** Firebase Console → Firestore Database → Data tab

**Data Structure:**
```
users/
  {userId}/                          ← Firebase Auth UID
    progress/
      current                        ← User progress document
        - totalQuestionsAnswered: 45
        - correctAnswers: 38
        - experiencePoints: 450
        - userLevel: 3
        - currentStreak: 5
        - ...
    sessions/                        ← Future: Session data
    achievements/                    ← Future: Achievement data
    favorites/                       ← Future: Favorite questions

userAnswers/
  {answerId}                         ← Auto-generated ID
    - userId: "Kx7mN2pQ8rZ3sT5vW9y" ← Links to Auth user
    - questionId: "P5_L1_001"
    - selectedAnswerIndex: 2
    - correctAnswerIndex: 1
    - isCorrect: false
    - timestamp: ...

questionAnalytics/
  {questionId}                       ← Question ID
    - totalAttempts: 150
    - correctAttempts: 120
    - correctPercentage: 80.0
    - averageTimeSeconds: 45
    - ...
```

## 🔍 Verification Steps

### 1. Verify Authentication is Working

**In Android Studio / VS Code Logs:**
```
✅ Authentication initialized
Created new anonymous user: Kx7mN2pQ8rZ3sT5vW9y
```
OR
```
✅ Authentication initialized
Existing user found: Kx7mN2pQ8rZ3sT5vW9y
```

**In Firebase Console:**
1. Go to: Authentication → Users tab
2. You should see anonymous users appearing
3. Each user has a unique UID

### 2. Verify Firestore is Working

**In Firebase Console:**
1. Go to: Firestore Database → Data tab
2. After answering questions, you should see:
   - `users` collection with user documents
   - `userAnswers` collection with answer documents
   - `questionAnalytics` collection with updated stats

**Expected to see:**
- `users/Kx7mN2pQ8rZ3sT5vW9y/progress/current` document
- Multiple documents in `userAnswers` collection
- Updated documents in `questionAnalytics` collection

### 3. Test the Complete Flow

1. **Fresh Install:**
   ```bash
   flutter run
   ```
   - Check logs for "✅ Authentication initialized"
   - Go to Firebase Console → Authentication
   - Verify new anonymous user appears

2. **Answer Questions:**
   - Answer 5-10 practice questions
   - Go to Firebase Console → Firestore Database
   - Navigate to `users/{yourUserId}/progress/current`
   - Verify data is being saved

3. **Restart App:**
   - Close and reopen app
   - Check logs - should say "Existing user found: {same UID}"
   - Verify progress is maintained

## ❌ Common Issues & Solutions

### Issue 1: "User not authenticated" Error
**Cause:** Repository trying to save before auth initializes

**Solution:**
- Add null check before accessing `currentUser`
- Add small delay after auth initialization
- Use the code fixes shown in Option 1 and 2 above

### Issue 2: No Data in Firestore
**Cause:** Firestore rules blocking writes

**Solution:**
1. Check Firestore rules are deployed
2. Verify anonymous auth is enabled
3. Check app logs for permission errors

### Issue 3: "Permission Denied" in Logs
**Cause:** Firestore rules not allowing anonymous users

**Solution:**
1. Verify your rules include:
   ```javascript
   match /users/{userId} {
     allow read, write: if request.auth != null &&
                          request.auth.uid == userId;
   }
   ```
2. Re-publish rules in Firebase Console

### Issue 4: Multiple Anonymous Users Created
**Cause:** Auth state not persisting

**Solution:**
- Firebase Auth automatically persists
- Check that app is not clearing cache on each start
- Verify `google-services.json` is correct

## 📊 Monitoring Your Firebase Usage

### Check Authentication Usage
1. Firebase Console → Authentication → Usage tab
2. Monitor:
   - Daily active users
   - Sign-ups per day
   - Authentication requests

### Check Firestore Usage
1. Firebase Console → Firestore Database → Usage tab
2. Monitor:
   - Document reads
   - Document writes
   - Storage used

### Free Tier Limits (Spark Plan)
- **Authentication:** Unlimited users
- **Firestore Reads:** 50,000 per day
- **Firestore Writes:** 20,000 per day
- **Firestore Storage:** 1 GB

## 🎓 Understanding the Flow

```
App Launch
    ↓
Firebase.initializeApp()
    ↓
AuthService.initialize()
    ↓
[Creates/Loads Anonymous User]
    ↓
UID Available: "Kx7mN2pQ8rZ3sT5vW9y"
    ↓
Repository Initializes
    ↓
[Can now save to Firestore]
    ↓
User Answers Question
    ↓
Saves to: users/Kx7mN2pQ8rZ3sT5vW9y/progress/current
Saves to: userAnswers/{answerId}
Updates: questionAnalytics/{questionId}
```

## ✅ Checklist for Firebase Setup

- [ ] Firebase Authentication enabled
- [ ] Anonymous sign-in method enabled
- [ ] Firestore Database created
- [ ] Firestore rules deployed
- [ ] google-services.json in android/app/
- [ ] GoogleService-Info.plist in ios/Runner/ (if iOS)
- [ ] Code updated with null checks (Option 1)
- [ ] Main.dart has proper initialization order (Option 2)
- [ ] Tested and verified anonymous user appears in Firebase Console
- [ ] Tested and verified data saves to Firestore

## 🚀 Ready to Test

Once all checkboxes above are complete:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`
4. Answer some questions
5. Check Firebase Console for data

---

**Need Help?**
- Firebase Documentation: https://firebase.google.com/docs
- Flutter Firebase: https://firebase.flutter.dev/

**Last Updated:** 2025-09-30