# Data Management System Documentation

## Overview
This document explains the complete data saving and retrieval system for the TOEIC Egg app, including local storage (Hive) and cloud sync (Firebase).

---

## Table of Contents
1. [Data Models](#data-models)
2. [Storage Architecture](#storage-architecture)
3. [Exam Results Flow](#exam-results-flow)
4. [Current Issues](#current-issues)
5. [Recommended Fixes](#recommended-fixes)

---

## 1. Data Models

### ExamResult Model
**Location:** `lib/data/models/exam_result_model.dart`

```dart
class ExamResult {
  final String id;                      // Format: "exam_{examRound}_{timestamp}"
  final String examRound;               // e.g., "ROUND_1", "ROUND_2"
  final List<SimpleQuestion> questions; // Full question data
  final List<int> userAnswers;          // User's selected answers
  final DateTime examStartTime;
  final DateTime examEndTime;
  final int correctAnswers;             // Calculated score
  final double accuracy;                // Percentage (0.0 to 1.0)
  final int? partNumber;                // 2, 5, or 6 (CRITICAL for identification)
}
```

**Key Properties:**
- `id`: Unique identifier per exam attempt
- `examRound`: Just the round number (e.g., "ROUND_1")
- `partNumber`: **CRITICAL** - Identifies which TOEIC part (2/5/6)

---

## 2. Storage Architecture

### Local Storage (Hive)
**Location:** `lib/data/repositories/user_data_repository.dart`

**Box:** `examResultsBox`
**Key:** `'examResults'`
**Value:** List of ExamResult JSON objects

```
Hive Storage Structure:
examResultsBox
└── 'examResults' → [
      {
        "id": "exam_ROUND_1_1761640586441",
        "examRound": "ROUND_1",
        "questions": [...],      // Full question data (25-30 questions)
        "userAnswers": [...],    // Full answer array
        "correctAnswers": 10,
        "accuracy": 0.4,
        "partNumber": 2          // Identifies as Part 2
      },
      {
        "id": "exam_ROUND_7_1761640656078",
        "examRound": "ROUND_7",
        "questions": [...],
        "userAnswers": [...],
        "correctAnswers": 9,
        "accuracy": 0.3,
        "partNumber": 5          // Identifies as Part 5
      }
    ]
```

**What's Saved:**
- ✅ Complete question data
- ✅ Complete user answers
- ✅ Calculated scores
- ✅ Part number

---

### Cloud Storage (Firebase)
**Location:** `lib/data/repositories/user_data_repository.dart:1112-1162`

**Collection Path:** `users/{userId}/examResults/{examRound}`

```
Firestore Structure:
users/
└── {userId}/
    └── examResults/
        ├── ROUND_1/              ⚠️ ISSUE: Multiple parts use same ID!
        │   ├── id: "exam_ROUND_1_1761640586441"
        │   ├── examRound: "ROUND_1"
        │   ├── partNumber: 2     ← Last saved value wins
        │   ├── totalQuestions: 25
        │   ├── correctAnswers: 10
        │   ├── accuracy: 0.4
        │   ├── examStartTime: Timestamp
        │   └── examEndTime: Timestamp
        │
        └── ROUND_7/
            ├── id: "exam_ROUND_7_1761640656078"
            ├── examRound: "ROUND_7"
            ├── partNumber: 5
            ├── totalQuestions: 30
            ├── correctAnswers: 9
            └── ...
```

**What's Saved:**
- ✅ Metadata only (no full questions - saves bandwidth)
- ✅ Part number
- ✅ Scores and timestamps
- ❌ Questions array (intentionally excluded)
- ❌ UserAnswers array (intentionally excluded)

---

## 3. Exam Results Flow

### 3.1. Saving Flow (When User Finishes Exam)

```
┌─────────────────────────────────────────────────────────────┐
│  User completes exam in Part 2/5/6 Exam Screen             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Create ExamResult                                        │
│     - examRound: widget.round (e.g., "ROUND_1")             │
│     - questions: [...full array...]                         │
│     - userAnswers: [...full array...]                       │
│     - partNumber: 2/5/6                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  2. Call userDataRepo.saveExamResult(examResult)            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├──────────────────┬──────────────────────────┐
                 ▼                  ▼                          ▼
┌──────────────────────┐  ┌──────────────────┐  ┌─────────────────────┐
│  Add to _examResults │  │  Save to Hive    │  │  Save to Firebase   │
│  (in-memory list)    │  │  (local disk)    │  │  (cloud sync)       │
└──────────────────────┘  └──────────────────┘  └─────────────────────┘
         │                         │                         │
         │                         │                         │
         ▼                         ▼                         ▼
    Full data               Full data                 Metadata only
    with questions          with questions            (no questions)
    stored in RAM           stored in Hive            stored in Firebase
```

**Code References:**
- Part 2: `lib/features/part2/views/part2_exam_screen.dart:346-357`
- Part 5: `lib/features/part5/views/exam_mode_screen.dart` (similar)
- Part 6: `lib/features/part6/views/part6_exam_screen.dart:350-359`
- Save method: `lib/data/repositories/user_data_repository.dart:1083-1097`

---

### 3.2. Loading Flow (App Startup)

```
┌─────────────────────────────────────────────────────────────┐
│  App starts → UserDataRepository.initialize()               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  1. Load from Hive (local disk)                             │
│     _examResults = Hive.get('examResults')                  │
│     ✅ Has full questions and userAnswers                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  2. When statistics requested:                              │
│     getAllExamResults() is called                           │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Sync from Firebase (_syncExamResultsFromFirestore)      │
│     - Fetch metadata from Firebase                          │
│     - Check if we have each result locally                  │
│     - If missing: add with empty questions array            │
│     - If exists: update partNumber if needed                │
│     - ⚠️ ISSUE: May overwrite local data!                   │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Return exam results to app                              │
└─────────────────────────────────────────────────────────────┘
```

**Code References:**
- Initialize: `lib/data/repositories/user_data_repository.dart:99-223`
- Load from Hive: Line 182-202
- Sync from Firebase: Line 1205-1299
- Provider: `lib/providers/app_providers.dart:393-405`

---

## 4. Current Issues

### 🔴 CRITICAL ISSUE #1: Firebase Document ID Collision

**Problem:**
Multiple parts can have the same round number, causing data to overwrite each other.

**Example:**
```
Part 2 ROUND_1 → Firebase doc: users/{uid}/examResults/ROUND_1
Part 5 ROUND_1 → Firebase doc: users/{uid}/examResults/ROUND_1  ❌ OVERWRITES!
Part 6 ROUND_1 → Firebase doc: users/{uid}/examResults/ROUND_1  ❌ OVERWRITES!
```

**Code Location:** `user_data_repository.dart:1142`
```dart
await _firestore
    .collection('users')
    .doc(userId)
    .collection('examResults')
    .doc(examResult.examRound)  // ❌ Just "ROUND_1" - not unique!
    .set({...});
```

**Impact:**
- ❌ Only the most recent exam result per round number is saved
- ❌ Previous results from other parts are lost
- ❌ Statistics show incorrect data
- ❌ Users lose progress

---

### 🟡 ISSUE #2: Data Loss on Firebase Sync

**Problem:**
When syncing from Firebase, local data with full questions gets overwritten with partial Firebase data.

**What Happens:**
1. User takes Part 2 ROUND_1 exam
2. Full data saved to Hive (with questions array)
3. Metadata saved to Firebase (without questions array)
4. App restarts
5. Loads from Hive (still has full questions) ✅
6. Syncs from Firebase
7. Calls `_saveExamResultsToHive()` ❌
8. Overwrites Hive with partial data (empty questions)

**Code Location:** `user_data_repository.dart:1283-1284`
```dart
if (hasNewOrUpdatedResults) {
    await _saveExamResultsToHive();  // ❌ Saves ALL results, including existing ones
```

**Status:** ✅ PARTIALLY FIXED (added `hasNewOrUpdatedResults` flag)

---

### 🟡 ISSUE #3: Identifying Exam Part

**Problem:**
When loading from Firebase, we can't reliably determine which TOEIC part an exam belongs to without the local data.

**Current Detection Method:**
```dart
// user_data_repository.dart:1099-1110
int? _getPartNumberFromQuestionId(String questionId) {
    if (questionId.contains('PART2') || questionId.contains('Part2')) {
        return 2;
    } else if (questionId.contains('PART6') || questionId.contains('Part6')) {
        return 6;
    } else if ((questionId.startsWith('PRAC_') || questionId.startsWith('EXAM_')) &&
        !questionId.contains('Part6') && !questionId.contains('Part2')) {
        return 5;
    }
    return null;
}
```

**Issues:**
- ❌ Requires questions array to be present
- ❌ Doesn't work with Firebase data (no questions array)
- ❌ Brittle string matching

**Better Approach:**
- ✅ Store `partNumber` in Firebase metadata (already implemented)
- ✅ Use unique composite keys

---

## 5. Recommended Fixes

### Fix #1: Use Composite Document IDs in Firebase

**Current:**
```dart
.doc(examResult.examRound)  // "ROUND_1"
```

**Recommended:**
```dart
.doc('PART${examResult.partNumber}_${examResult.examRound}')  // "PART2_ROUND_1"
```

**Implementation:**
```dart
// user_data_repository.dart:1142
final docId = examResult.partNumber != null
    ? 'PART${examResult.partNumber}_${examResult.examRound}'
    : examResult.examRound;

await _firestore
    .collection('users')
    .doc(userId)
    .collection('examResults')
    .doc(docId)  // ✅ Now unique: "PART2_ROUND_1", "PART5_ROUND_1"
    .set({...});
```

**Benefits:**
- ✅ No more data collision
- ✅ Each part's rounds are separate
- ✅ Can query by part: `.where('partNumber', isEqualTo: 2)`

---

### Fix #2: Update ExamResult.examRound to Include Part

**Option A: Change examRound field**
```dart
// When creating ExamResult
final examResult = ExamResult.create(
    examRound: 'PART2_${widget.round}',  // "PART2_ROUND_1"
    questions: _questions,
    userAnswers: userAnswersList,
    examStartTime: _examStartTime!,
    examEndTime: examEndTime,
    partNumber: 2,
);
```

**Option B: Add new field (better for backwards compatibility)**
```dart
class ExamResult {
    final String id;
    final String examRound;     // Keep as "ROUND_1"
    final String fullExamId;    // New: "PART2_ROUND_1"
    final int? partNumber;
    // ... other fields
}
```

---

### Fix #3: Update getExamResult to Use Part-Specific Lookup

**Current:**
```dart
Future<ExamResult?> getExamResult(String examRound) async {
    return _examResults
        .where((result) => result.examRound == examRound)
        .cast<ExamResult?>()
        .firstWhere((result) => result != null, orElse: () => null);
}
```

**Recommended:**
```dart
Future<ExamResult?> getExamResult(String examRound, {int? partNumber}) async {
    return _examResults
        .where((result) =>
            result.examRound == examRound &&
            (partNumber == null || result.partNumber == partNumber))
        .cast<ExamResult?>()
        .firstWhere((result) => result != null, orElse: () => null);
}
```

**Usage:**
```dart
// In Part 2 screen
final result = await userDataRepo.getExamResult('ROUND_1', partNumber: 2);

// In Part 5 screen
final result = await userDataRepo.getExamResult('ROUND_1', partNumber: 5);
```

---

### Fix #4: Update Round Completion Detection

**Part 2 Current:**
```dart
// part2_exam_round_selection_screen.dart:27-34
final part2Results = allExamResults.where((result) => result.partNumber == 2).toList();

for (final result in part2Results) {
    completedRounds.add(result.examRound);  // "ROUND_1"
}
```

**This is correct!** Already filters by partNumber.

---

### Fix #5: Migration Strategy for Existing Data

Since you already have data in Firebase with ambiguous IDs, you need a migration:

**Step 1: Identify Existing Data**
```dart
// One-time migration code
Future<void> migrateExistingExamResults() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('examResults')
        .get();

    for (final doc in snapshot.docs) {
        final data = doc.data();
        final examRound = data['examRound'];
        final partNumber = data['partNumber'];

        if (partNumber != null && !doc.id.startsWith('PART')) {
            // Need to migrate: create new document with correct ID
            final newDocId = 'PART${partNumber}_$examRound';

            // Copy to new location
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('examResults')
                .doc(newDocId)
                .set(data);

            // Delete old document
            await doc.reference.delete();

            print('✅ Migrated: $examRound → $newDocId');
        }
    }
}
```

---

## Summary

### Current Data Flow
```
Exam Taken → Save Locally (Hive) → Save to Firebase (metadata)
                  ↓
            Full questions stored

App Restart → Load from Hive → Sync from Firebase
                  ↓                    ↓
            Full data           Metadata only
                  ↓                    ↓
              ⚠️ ISSUE: Firebase sync may overwrite local data
```

### Key Issues
1. ❌ Firebase doc IDs not unique across parts (ROUND_1 collision)
2. ⚠️ Sync may overwrite local data with partial Firebase data
3. ❌ Statistics show "0 questions" after app restart

### Required Actions
1. **Immediate:** Implement composite document IDs (`PART2_ROUND_1`)
2. **Important:** Run migration script for existing Firebase data
3. **Important:** Update all getExamResult calls to include partNumber
4. **Optional:** Add migration check in initialize() for one-time fix

---

## File References

### Data Models
- `lib/data/models/exam_result_model.dart` - ExamResult class

### Repositories
- `lib/data/repositories/user_data_repository.dart`
  - `saveExamResult()` - Line 1083-1097
  - `_saveExamResultToFirestore()` - Line 1112-1162
  - `_saveExamResultsToHive()` - Line 1280-1294
  - `_syncExamResultsFromFirestore()` - Line 1205-1299
  - `getExamResult()` - Line 1187-1196

### Providers
- `lib/providers/app_providers.dart`
  - `examResultsProvider` - Line 393-405
  - `combinedStatisticsProvider` - Line 425-475

### Exam Screens (where data is created)
- `lib/features/part2/views/part2_exam_screen.dart` - Line 346-359
- `lib/features/part5/views/exam_mode_screen.dart` - Similar structure
- `lib/features/part6/views/part6_exam_screen.dart` - Line 350-359

### Round Selection (where completed rounds are checked)
- `lib/features/part2/views/part2_exam_round_selection_screen.dart` - Line 19-41
- `lib/features/part5/views/exam_level_selection_screen.dart` - Line 24-64
