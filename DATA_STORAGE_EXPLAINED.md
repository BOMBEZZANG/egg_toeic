# 📊 Anonymous User Data Storage - Complete Guide

## 🎯 Overview

Your Egg TOEIC app stores data in **two places** for anonymous users:
1. **Local Storage (Hive)** - On device, works offline
2. **Cloud Storage (Firestore)** - In Firebase, syncs when online

## 🔥 What Gets Saved in Firestore?

### 1. User Progress Data
**Location:** `users/{userId}/progress/current`

**What gets saved:**
- Total questions answered
- Correct answers count
- User level
- Experience points (XP)
- Current streak
- Longest streak
- Last study date

**Example Document:**
```json
{
  "totalQuestionsAnswered": 45,
  "correctAnswers": 38,
  "userLevel": 3,
  "experiencePoints": 450,
  "currentStreak": 5,
  "longestStreak": 12,
  "lastStudyDate": "2025-01-20T10:30:00.000Z"
}
```

**When it gets saved:**
- Every time user answers a question ✅
- When user gains XP ✅
- When streak is updated ✅
- When level increases ✅

---

### 2. User Answers (Analytics)
**Location:** `userAnswers/{answerId}` (Collection)

**What gets saved for EACH question answered:**
- User ID (links to anonymous user)
- Question ID
- Selected answer index (0-3)
- Correct answer index
- Whether answer was correct
- Question mode (practice/exam)
- Question type (grammar/vocabulary)
- Difficulty level
- Grammar point
- Time spent (if tracked)
- Session ID
- Timestamp
- Metadata (like exam round, question number)

**Example Document:**
```json
{
  "userId": "Kx7mN2pQ8rZ3sT5vW9y",           // Anonymous user UID
  "questionId": "P5_L1_001",
  "selectedAnswerIndex": 2,
  "correctAnswerIndex": 1,
  "isCorrect": false,
  "questionMode": "practice",
  "questionType": "grammar",
  "difficultyLevel": 1,
  "grammarPoint": "Present Perfect",
  "timeSpentSeconds": 45,
  "sessionId": "session_123456",
  "answeredAt": "2025-01-20T10:32:15.000Z",
  "metadata": {
    "attemptNumber": 1,
    "deviceType": "android"
  }
}
```

**When it gets saved:**
- ✅ Every time user answers a question in **practice mode**
- ✅ Every time user answers a question in **exam mode**
- ✅ Even if they get it wrong
- ✅ Multiple attempts on same question = multiple documents

**Purpose:**
- Track user's answer history
- Generate personalized statistics
- Identify weak areas
- Show performance over time

---

### 3. Question Analytics (Aggregated Data)
**Location:** `questionAnalytics/{questionId}` (Collection)

**What gets saved for EACH question:**
- Total attempts across ALL users
- Correct attempts count
- Correct percentage
- Average time spent
- Difficulty level
- Question mode
- Last updated timestamp

**Example Document:**
```json
{
  "questionId": "P5_L1_001",
  "totalAttempts": 150,              // From all users
  "correctAttempts": 120,            // From all users
  "correctPercentage": 80.0,
  "averageTimeSeconds": 42,
  "difficultyLevel": 1,
  "questionMode": "practice",
  "lastUpdated": "2025-01-20T10:32:15.000Z"
}
```

**When it gets updated:**
- ✅ Every time ANY user (including anonymous) answers that question
- ✅ Automatically calculates success rate
- ✅ Updates are cumulative (adds to existing data)

**Purpose:**
- Show "X% of users got this right"
- Display question difficulty
- Help you identify hard/easy questions
- Community statistics

---

## 🗂️ Complete Firestore Structure

```
📁 Firestore Database
│
├── 📁 users/                                    ← Per-user data
│   │
│   ├── 📁 Kx7mN2pQ8rZ3sT5vW9y/               ← Anonymous User 1
│   │   │
│   │   └── 📁 progress/
│   │       └── 📄 current                      ← User's progress
│   │           ├─ totalQuestionsAnswered: 45
│   │           ├─ correctAnswers: 38
│   │           ├─ userLevel: 3
│   │           └─ experiencePoints: 450
│   │
│   └── 📁 ABC123xyz456/                       ← Anonymous User 2
│       └── 📁 progress/
│           └── 📄 current
│               ├─ totalQuestionsAnswered: 12
│               └─ ...
│
├── 📁 userAnswers/                             ← All user answers
│   │
│   ├── 📄 answer_001                          ← Answer record 1
│   │   ├─ userId: "Kx7mN2pQ8rZ3sT5vW9y"
│   │   ├─ questionId: "P5_L1_001"
│   │   ├─ selectedAnswerIndex: 2
│   │   ├─ correctAnswerIndex: 1
│   │   ├─ isCorrect: false
│   │   └─ answeredAt: timestamp
│   │
│   ├── 📄 answer_002                          ← Answer record 2
│   │   ├─ userId: "Kx7mN2pQ8rZ3sT5vW9y"
│   │   ├─ questionId: "P5_L1_002"
│   │   ├─ isCorrect: true
│   │   └─ ...
│   │
│   └── 📄 answer_003                          ← Answer record 3
│       ├─ userId: "ABC123xyz456"              ← Different user
│       └─ ...
│
└── 📁 questionAnalytics/                       ← Question statistics
    │
    ├── 📄 P5_L1_001                           ← Question 1 stats
    │   ├─ totalAttempts: 150                  ← From ALL users
    │   ├─ correctAttempts: 120
    │   └─ correctPercentage: 80.0
    │
    └── 📄 P5_L1_002                           ← Question 2 stats
        ├─ totalAttempts: 200
        └─ correctPercentage: 65.0
```

---

## 📱 What Data is Linked to Each Anonymous User?

### User's Own Data (Private)
**Location:** `users/{userId}/`

✅ **Can see:** Only their own data
❌ **Cannot see:** Other users' data

**Includes:**
- Personal progress
- Personal stats
- Personal achievements (future)
- Personal favorites (future)

### User's Answers (Queryable)
**Location:** `userAnswers/` (filtered by userId)

✅ **Can query:** All their own answers
❌ **Cannot see:** Other users' individual answers

**Used for:**
- Answer history
- Performance tracking
- Wrong answer review
- Personal statistics

### Shared Analytics (Public)
**Location:** `questionAnalytics/`

✅ **Can see:** Everyone's aggregated stats
✅ **Anonymous:** Individual contributions not visible

**Shows:**
- "80% of users got this right"
- "Average time: 45 seconds"
- Question difficulty ratings

---

## 🔍 Example: User Takes a Question

Let's trace what happens when user answers question "P5_L1_001":

### Step 1: User Answers Question
```dart
// User selects answer index 2
// Correct answer is index 1
// Question is "P5_L1_001"
```

### Step 2: Data Saved Locally (Hive)
✅ Saved to device immediately
- Works even if offline
- Fast, no network delay

### Step 3: Data Saved to Firestore (if online)

**3a. Update User Progress**
```javascript
users/Kx7mN2pQ8rZ3sT5vW9y/progress/current
{
  totalQuestionsAnswered: 45 → 46,     // +1
  correctAnswers: 38 (stays same),      // Wrong answer
  experiencePoints: 450 (stays same),   // No XP for wrong
  lastStudyDate: [updated to now]
}
```

**3b. Create User Answer Record**
```javascript
userAnswers/[auto-generated-id]
{
  userId: "Kx7mN2pQ8rZ3sT5vW9y",
  questionId: "P5_L1_001",
  selectedAnswerIndex: 2,
  correctAnswerIndex: 1,
  isCorrect: false,
  questionMode: "practice",
  questionType: "grammar",
  difficultyLevel: 1,
  grammarPoint: "Present Perfect",
  answeredAt: "2025-01-20T10:32:15.000Z",
  sessionId: "session_12345",
  timeSpentSeconds: 45
}
```

**3c. Update Question Analytics**
```javascript
questionAnalytics/P5_L1_001
{
  totalAttempts: 150 → 151,            // +1 from all users
  correctAttempts: 120 (stays same),    // This was wrong
  correctPercentage: 79.47% (recalculated),
  lastUpdated: [updated to now]
}
```

### Step 4: If Answer Was Wrong
**Additional action:** Wrong answer saved for review
```javascript
// Saved locally in Hive (not shown in Firestore by default)
// Can be synced to Firestore in future feature
wrongAnswers/[local-id]
{
  questionId: "P5_L1_001",
  selectedAnswerIndex: 2,
  correctAnswerIndex: 1,
  questionText: "She ___ to Paris twice.",
  options: [...],
  explanation: "..."
}
```

---

## 🎯 Summary: What Questions Get Saved?

### ✅ SAVED in Firestore:

1. **User Progress Updates**
   - Question count increases
   - Correct answer count (if right)
   - XP gained (if right)
   - Streak updated

2. **Individual Answer Records**
   - Question ID ✅
   - Selected answer ✅
   - Whether correct ✅
   - Timestamp ✅
   - User ID (anonymous) ✅

3. **Question Performance Stats**
   - How many users tried it
   - Success rate
   - Average time

### ❌ NOT SAVED in Firestore (saved locally only):

1. **Question Content**
   - Question text (already in database)
   - Options (already in database)
   - Explanations (already in database)

2. **Temporary Session Data**
   - Current question index
   - Timer state
   - UI state

---

## 🔒 Privacy & Security

### Anonymous User Data
- **No personal info:** No email, name, or phone
- **Just a UID:** Random string like "Kx7mN2pQ8rZ3sT5vW9y"
- **Can't identify:** No way to know who the person is
- **Separate users:** Each device = different UID

### What Users CAN'T See
- ❌ Other users' individual answers
- ❌ Other users' progress
- ❌ Other users' personal data

### What Users CAN See
- ✅ Their own progress
- ✅ Their own answer history
- ✅ Aggregated statistics (e.g., "80% of users got this right")

---

## 📊 How to View This Data

### In Firebase Console

**1. View User Progress:**
```
Firestore Database → Data → users → [click user ID] → progress → current
```

**2. View User Answers:**
```
Firestore Database → Data → userAnswers → [browse documents]
Filter by userId to see one user's answers
```

**3. View Question Analytics:**
```
Firestore Database → Data → questionAnalytics → [click question ID]
```

### In Your App (Future Features)

You can add screens to show users:
- 📈 Their answer history
- 📊 Their performance trends
- 🎯 Their weak areas
- 📅 Their study calendar
- 🏆 Their achievements

---

## 🚀 Future Enhancements

### When User Upgrades to Social Login

**What happens to data:**
- ✅ Same UID maintained
- ✅ All progress kept
- ✅ All answers preserved
- ✅ Just adds email/name to account

**Example:**
```
BEFORE (Anonymous):
users/Kx7mN2pQ8rZ3sT5vW9y/
  - Anonymous user
  - No email
  - 45 questions answered

AFTER (Google Login):
users/Kx7mN2pQ8rZ3sT5vW9y/    ← SAME UID!
  - Google user
  - Email: user@gmail.com
  - 45 questions answered       ← KEPT!
```

### Potential Future Data

You could also save:
- Learning sessions
- Study streaks
- Achievements unlocked
- Favorite questions
- Notes on questions
- Study goals
- Performance graphs

---

## ✅ Key Takeaways

1. **Every question answered** creates a record in `userAnswers`
2. **User progress** is continuously updated in `users/{userId}/progress/current`
3. **Question statistics** are updated for everyone's benefit
4. **All data is linked** to the anonymous user ID
5. **Privacy is maintained** - users can only see their own detailed data
6. **Data persists** even if user upgrades to social login
7. **Works offline** with local Hive storage as backup

---

**Questions?** Let me know if you want to add more data tracking or analytics features!

**Last Updated:** 2025-01-20