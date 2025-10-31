# Question Generation and Firebase Storage System Documentation

## Overview
This document provides a comprehensive analysis of how TOEIC questions for Part 2, Part 5, and Part 6 are generated, structured, and stored in Firebase through the **toeic-egg-admin** project.

---

## Table of Contents
1. [Firebase Collections Structure](#firebase-collections-structure)
2. [Part 5 (Grammar & Vocabulary) Structure](#part-5-structure)
3. [Part 2 (Listening - Q&R) Structure](#part-2-structure)
4. [Part 6 (Text Completion) Structure](#part-6-structure)
5. [ID Format Conventions](#id-format-conventions)
6. [Field Mapping Comparison](#field-mapping-comparison)
7. [Critical Issues and Inefficiencies](#critical-issues-and-inefficiencies)
8. [Recommendations](#recommendations)

---

## 1. Firebase Collections Structure

### Collections Hierarchy

```
Firestore Database
├── examQuestions/                    ← Part 5 Exam Questions
│   ├── EXAM_R1_L2_GRAM_Q1_timestamp
│   ├── EXAM_R1_L1_VOCAB_Q2_timestamp
│   └── ...
│
├── practiceQuestions/                ← Part 5 Practice Questions
│   ├── PRAC_2025_10_09_Q1_timestamp
│   ├── PRAC_2025_10_10_Q2_timestamp
│   └── ...
│
├── part2examQuestions/               ← Part 2 Exam Questions
│   ├── Part2_EXAM_T1_P2_Q7
│   ├── Part2_EXAM_T1_P2_Q8
│   └── ...
│
├── part2practiceQuestions/           ← Part 2 Practice Questions
│   ├── Part2_PRAC_2025_10_09_P2_Q1
│   ├── Part2_PRAC_2025_10_10_P2_Q2
│   └── ...
│
├── part6examQuestions/               ← Part 6 Exam Questions
│   ├── Part6_EXAM_T1_L1_GRAM_Q131
│   ├── Part6_EXAM_T1_L1_VOCAB_Q132
│   └── ...
│
├── part6practiceQuestions/           ← Part 6 Practice Questions
│   ├── Part6_PRAC_2025_10_09_Q1
│   ├── Part6_PRAC_2025_10_10_Q2
│   └── ...
│
├── questionHistory/                  ← Change tracking for all questions
├── reviewComments/                   ← Workflow comments
└── adminLogs/                        ← Activity logs
```

### Collection Naming Pattern

| Part | Mode      | Collection Name            | Count |
|------|-----------|----------------------------|-------|
| 5    | Exam      | `examQuestions`            | 30 per round |
| 5    | Practice  | `practiceQuestions`        | 10 per day |
| 2    | Exam      | `part2examQuestions`       | 25 per round (Q7-31) |
| 2    | Practice  | `part2practiceQuestions`   | 5 per day |
| 6    | Exam      | `part6examQuestions`       | 16 per round (Q131-146) |
| 6    | Practice  | `part6practiceQuestions`   | 4 per day |

---

## 2. Part 5 (Grammar & Vocabulary) Structure

### Document ID Format

**Exam:**
```
EXAM_R{round}_L{level}_{type}_Q{number}_{timestamp}
```
Example: `EXAM_R1_L2_GRAM_Q15_1696234567890`

**Practice:**
```
PRAC_{YYYY}_{MM}_{DD}_Q{number}_{timestamp}
```
Example: `PRAC_2025_10_09_Q3_1696234567890`

### Data Structure

```typescript
{
  // Identification
  id: "EXAM_R1_L2_GRAM_Q15_1696234567890",
  mode: "exam" | "practice",
  part: "part5",                        // Auto-detected from ID

  // Question Content
  questionText: string,                 // English sentence with blank
  options: [string, string, string, string],  // 4 options (A, B, C, D)
  correctAnswerIndex: 0 | 1 | 2 | 3,

  // Classification
  questionType: "grammar" | "vocabulary",
  grammarPoint?: string,                // e.g., "present perfect", "passive voice"
  difficultyLevel: 1 | 2 | 3,           // 1=Easy, 2=Medium, 3=Hard
  tags: string[],                       // e.g., ["verb tense", "workplace"]

  // Explanation
  explanation: string,                  // Detailed Korean explanation

  // Exam Specific (mode: "exam")
  testNumber?: number,                  // Round number (1, 2, 3...)
  questionNumber?: number,              // Position in test (1-30)

  // Practice Specific (mode: "practice")
  date?: string,                        // "YYYY-MM-DD"

  // Metadata
  status: "draft" | "in_review" | "approved" | "published",
  createdAt: Date,
  createdBy: string,
  updatedAt: Date,
  updatedBy: string,
  version: number
}
```

### Firebase Storage Location

```
Collection: examQuestions or practiceQuestions
Document ID: {generated ID as shown above}
```

**Code Reference:**
- Type Definition: `/src/types/question.ts`
- Upload Logic: `/src/lib/services/question-service.ts:172-196`
- Collection Selection: Line 175

---

## 3. Part 2 (Listening - Q&R) Structure

### Document ID Format

**Exam:**
```
Part2_EXAM_T{test}_P2_Q{questionNumber}
```
Example: `Part2_EXAM_T1_P2_Q7` (Q7-31)

**Practice:**
```
Part2_PRAC_{YYYY}_{MM}_{DD}_P2_Q{number}
```
Example: `Part2_PRAC_2025_10_09_P2_Q1`

### Data Structure

```typescript
{
  // Identification
  id: "Part2_EXAM_T1_P2_Q7",
  questionNumber: number,               // 7-31 for exam, 1-5 for practice

  // Question Type
  questionType: "wh-question" | "yes-no-question" | "tag-question" |
                "statement" | "choice-question" | "suggestion-request",
  questionCategory?: string,            // "who", "what", "when", "where", "why", "how"

  // Question Content (All audio-based)
  questionText: string,                 // Question/statement transcript
  responses: [string, string, string],  // 3 response options (A, B, C)
  correctAnswerIndex: 0 | 1 | 2,        // 0=A, 1=B, 2=C
  correctAnswer: string,                // Correct response text

  // Audio Files
  audioFiles?: {
    question: string,                   // Firebase Storage URL for question audio
    responseA: string,                  // Firebase Storage URL for response A
    responseB: string,                  // Firebase Storage URL for response B
    responseC: string                   // Firebase Storage URL for response C
  },

  // Explanation
  difficultyLevel: 1 | 2 | 3,
  explanation: string,                  // Korean explanation
  wrongAnswerAnalysis: [string, string], // Analysis of 2 incorrect answers
  keyPhrase?: string,                   // Key expression
  tags: string[],                       // e.g., ["workplace", "invitation", "wh-question"]

  // Detailed Explanation (Optional)
  detailedExplanation?: {
    questionAnalysis: string,
    correctAnswerReason: string,
    distractorAnalysis: string[],
    keyPoint: string,
    similarExpressions?: string[],
    tags: string[]
  },

  // Metadata
  status?: "draft" | "in_review" | "approved" | "published",
  createdAt?: Date | string,
  updatedAt?: Date | string,
  createdBy?: string,
  updatedBy?: string,
  version?: number
}
```

### Firebase Storage Location

```
Collection: part2examQuestions or part2practiceQuestions
Document ID: {generated ID as shown above}

Audio Files Storage:
gs://{bucket}/part2-audio/{mode}/{testNumber or date}/
  ├── question_{questionNumber}.mp3
  ├── responseA_{questionNumber}.mp3
  ├── responseB_{questionNumber}.mp3
  └── responseC_{questionNumber}.mp3
```

**Code References:**
- Type Definition: `/src/types/part2-types.ts:10-61`
- Collection Selection: `/src/lib/services/question-service.ts:354-359`
- Generation API: `/src/app/api/generate/part2/route.ts`

### Question Type Distribution (Exam Template)

```typescript
EXAM_25_TEMPLATE = {
  totalQuestions: 25,
  startQuestionNumber: 7,
  endQuestionNumber: 31,
  distribution: {
    'wh-question': 11,          // ~44% (Who, What, When, Where, Why, How)
    'yes-no-question': 6,       // ~24% (Simple yes/no questions)
    'statement': 4,             // ~16% (Respond to statements)
    'choice-question': 2,       // ~8%  (A or B? type questions)
    'tag-question': 1,          // ~4%  (Tag questions)
    'suggestion-request': 1     // ~4%  (Suggestions/requests)
  }
}
```

---

## 4. Part 6 (Text Completion) Structure

### Document ID Format

**Exam:**
```
Part6_EXAM_T{test}_L{level}_{type}_Q{questionNumber}
```
Example: `Part6_EXAM_T1_L1_GRAM_Q131`

**Practice:**
```
Part6_PRAC_{YYYY}_{MM}_{DD}_Q{number}
```
Example: `Part6_PRAC_2025_10_09_Q1`

### Data Structure

#### Passage Structure
```typescript
{
  // Passage Identification
  passageId: string,                    // "EXAM_T1_P6_PASSAGE_1"
  passageNumber: number,                // 1-4 (in exam)

  // Passage Content
  passageText: string,                  // English text with blanks
  passageTextKorean?: string,           // Korean translation

  // Passage Metadata
  documentType: string,                 // "email", "letter", "memo", "notice", "article"
  title: string,                        // Document title
  questionRange: string,                // "131-134", "135-138", etc.

  // Associated Questions
  questions: Part6Question[]            // Exactly 4 questions per passage
}
```

#### Question Structure
```typescript
{
  // Identification
  id: "Part6_EXAM_T1_L1_GRAM_Q131",
  passageId: string,                    // Links to parent passage
  questionNumber: number,               // 131-146 for exam

  // Question Type
  questionType: "grammar" | "vocabulary" | "sentence-insertion",
  questionCategory?: string,            // Subcategory (e.g., "verb tense", "preposition")

  // Question Content
  questionText: string,                 // Question text (or sentence to insert)
  options: [string, string, string, string],
  correctAnswerIndex: 0 | 1 | 2 | 3,
  correctAnswer: string,

  // Explanation
  difficultyLevel: 1 | 2 | 3,
  explanation: string,                  // Korean explanation
  grammarPoint?: string,
  tags: string[],

  // Detailed Explanation (Optional)
  detailedExplanation?: {
    problemAnalysis: string,
    wrongAnswerNote: string[],
    keyPoint: string,
    exampleSentence: string,
    tags: string[]
  },

  // Metadata
  status?: "draft" | "in_review" | "approved" | "published",
  createdAt?: Date | string,
  updatedAt?: Date | string,
  createdBy?: string,
  updatedBy?: string,
  version?: number
}
```

### Firebase Storage Location

```
Collection: part6examQuestions or part6practiceQuestions
Document ID: {generated ID as shown above}

Note: Passages are NOT stored separately - questions include passage data
```

**Code References:**
- Type Definition: `/src/types/part6-types.ts`
- Collection Selection: `/src/lib/services/question-service.ts:354-359`
- Generation API: `/src/app/api/generate/part6/route.ts`

### Passage Structure (Exam)

```
Exam Test = 4 passages × 4 questions each = 16 questions total
├── Passage 1 (Q131-134)
│   ├── Q131 (grammar/vocabulary/sentence-insertion)
│   ├── Q132
│   ├── Q133
│   └── Q134
├── Passage 2 (Q135-138)
├── Passage 3 (Q139-142)
└── Passage 4 (Q143-146)
```

---

## 5. ID Format Conventions

### Summary Table

| Part | Mode     | ID Prefix Pattern | Example | Question Numbers |
|------|----------|-------------------|---------|------------------|
| 5    | Exam     | `EXAM_R{round}_L{level}_{type}_Q{num}_{ts}` | `EXAM_R1_L2_GRAM_Q15_1696234567890` | 1-30 |
| 5    | Practice | `PRAC_{YYYY}_{MM}_{DD}_Q{num}_{ts}` | `PRAC_2025_10_09_Q3_1696234567890` | Variable |
| 2    | Exam     | `Part2_EXAM_T{test}_P2_Q{num}` | `Part2_EXAM_T1_P2_Q7` | 7-31 |
| 2    | Practice | `Part2_PRAC_{YYYY}_{MM}_{DD}_P2_Q{num}` | `Part2_PRAC_2025_10_09_P2_Q1` | 1-5 |
| 6    | Exam     | `Part6_EXAM_T{test}_L{level}_{type}_Q{num}` | `Part6_EXAM_T1_L1_GRAM_Q131` | 131-146 |
| 6    | Practice | `Part6_PRAC_{YYYY}_{MM}_{DD}_Q{num}` | `Part6_PRAC_2025_10_09_Q1` | Variable |

### ID Component Breakdown

**Part 5:**
- `EXAM_R{round}` - Exam round number
- `L{level}` - Difficulty level (1-3)
- `{type}` - GRAM or VOCAB
- `Q{num}` - Question number
- `{timestamp}` - Unix timestamp

**Part 2:**
- `Part2_` - Part identifier
- `EXAM_T{test}` or `PRAC_{date}` - Mode and identifier
- `P2` - Part 2 marker
- `Q{num}` - Question number (7-31 for exam)

**Part 6:**
- `Part6_` - Part identifier
- `EXAM_T{test}` or `PRAC_{date}` - Mode and identifier
- `L{level}_{type}` - Difficulty and type (for exam)
- `Q{num}` - Question number (131-146 for exam)

---

## 6. Field Mapping Comparison

### Common Fields Across All Parts

| Field Name | Part 2 | Part 5 | Part 6 | Notes |
|------------|:------:|:------:|:------:|-------|
| `id` | ✅ | ✅ | ✅ | Document ID (different formats) |
| `mode` | ❌ | ✅ | ❌ | Inferred from collection in Part 2/6 |
| `part` | ❌ | ✅ | ❌ | Auto-detected in Part 5 only |
| `questionText` | ✅ | ✅ | ✅ | Question content |
| `options` | ❌ | ✅ | ✅ | Part 2 uses `responses` instead |
| `responses` | ✅ | ❌ | ❌ | Part 2 only - 3 response choices |
| `correctAnswerIndex` | ✅ | ✅ | ✅ | Index of correct answer |
| `correctAnswer` | ✅ | ❌ | ✅ | Part 5 calculates from options |
| `difficultyLevel` | ✅ | ✅ | ✅ | 1, 2, or 3 |
| `questionType` | ✅ | ✅ | ✅ | Different values per part |
| `explanation` | ✅ | ✅ | ✅ | Korean explanation |
| `tags` | ✅ | ✅ | ✅ | String array |

### Part-Specific Fields

#### Part 2 Only
- `responses` - Array of 3 response options
- `audioFiles` - Object with question and response URLs
- `wrongAnswerAnalysis` - Analysis of incorrect answers
- `keyPhrase` - Key expression
- `questionCategory` - Subcategory (who, what, when, etc.)

#### Part 5 Only
- `mode` - Explicitly stored
- `part` - Auto-detected from ID
- `grammarPoint` - Grammar concept
- `testNumber` - Exam round number
- `date` - Practice date
- `questionNumber` - Position in test

#### Part 6 Only
- `passageId` - Links to passage
- `passageNumber` - Passage order
- `passageText` - Full passage text
- `passageTextKorean` - Korean translation
- `documentType` - Type of document
- `title` - Document title

### Inconsistencies Identified

| Issue | Description | Impact |
|-------|-------------|--------|
| **Field Name Variations** | Part 2 uses `responses`, Part 5/6 use `options` | Confusing, requires special handling |
| **Missing `mode` field** | Part 2/6 don't store `mode` explicitly | Must infer from collection name |
| **ID Format Chaos** | Each part uses completely different ID format | Hard to parse, no standardization |
| **Timestamp Inconsistency** | Part 5 includes timestamp in ID, Part 2/6 don't | Duplicate prevention issues |
| **Explanation Structure** | Part 2 has `detailedExplanation`, Part 6 has it, Part 5 doesn't | Inconsistent data richness |

---

## 7. Critical Issues and Inefficiencies

### 🔴 Issue #1: Collection Proliferation

**Problem:**
6 separate collections for 3 parts × 2 modes

```
- examQuestions (Part 5 Exam)
- practiceQuestions (Part 5 Practice)
- part2examQuestions (Part 2 Exam)
- part2practiceQuestions (Part 2 Practice)
- part6examQuestions (Part 6 Exam)
- part6practiceQuestions (Part 6 Practice)
```

**Impact:**
- ❌ Difficult to query across parts
- ❌ Code duplication in mobile app
- ❌ Maintenance nightmare
- ❌ Inconsistent data structures

**Better Approach:**
```
questions/
  ├── {part}_{mode}_{id}
```
OR use subcollections:
```
questions/
  ├── part2/
  │   ├── exam/
  │   └── practice/
  ├── part5/
  └── part6/
```

---

### 🔴 Issue #2: No `part` Field in Part 2/6

**Problem:**
Part 2 and Part 6 documents don't have an explicit `part` field.

**Current Logic:**
```typescript
// question-service.ts:113
const part = id.startsWith('Part6_') ? 'part6' : 'part5';
```

**Impact:**
- ❌ Must parse ID to determine part
- ❌ Part 2 gets incorrectly identified as Part 5!
- ❌ Fragile string matching

**Example Bug:**
```typescript
Question ID: "Part2_EXAM_T1_P2_Q7"
Detected as: "part5" ❌  (because it doesn't start with "Part6_")
Should be: "part2" ✅
```

---

### 🔴 Issue #3: Field Name Inconsistency

**Problem:**
Different field names for same concept:

| Concept | Part 2 | Part 5 | Part 6 |
|---------|--------|--------|--------|
| Answer choices | `responses` | `options` | `options` |
| Options count | 3 | 4 | 4 |

**Impact:**
- ❌ Mobile app needs special handling
- ❌ Cannot use unified Question model
- ❌ Confusion for developers

**Current Mobile App Code:**
```dart
// SimpleQuestion class has both!
final List<String> options;  // For Part 5/6
final List<String>? responses;  // For Part 2 only
```

---

### 🔴 Issue #4: Redundant Passage Data in Part 6

**Problem:**
Every Part 6 question includes the full passage text.

**Example:**
```
Passage 1 (Q131-134) - 4 questions, each containing:
  - passageText: "Dear Valued Customer..." (500+ characters)
  - passageTextKorean: "친애하는 고객님..." (500+ characters)

Total storage: Passage text × 4 questions = 2000+ characters of duplication
Per exam: 4 passages × 4 questions = 16x duplication
```

**Impact:**
- ❌ **Massive data duplication** (4x per passage)
- ❌ **Increased Firebase reads** (downloading same passage 4 times)
- ❌ **Bandwidth waste** on mobile app
- ❌ **Inconsistency risk** (updating one question's passage but not others)

**Better Approach:**
Store passages separately:
```
part6passages/
  ├── EXAM_T1_PASSAGE_1 (single copy of passage)

part6examQuestions/
  ├── Part6_EXAM_T1_L1_GRAM_Q131 (references PASSAGE_1)
  ├── Part6_EXAM_T1_L1_VOCAB_Q132 (references PASSAGE_1)
  ├── Part6_EXAM_T1_L1_GRAM_Q133 (references PASSAGE_1)
  └── Part6_EXAM_T1_L1_SENT_Q134 (references PASSAGE_1)
```

**Savings:**
- Storage: 75% reduction per exam
- Bandwidth: 75% reduction on mobile
- Consistency: Single source of truth

---

### 🟡 Issue #5: No Standardized questionNumber

**Problem:**
Question numbers vary by part and are not consistently stored.

| Part | Field Name | Exam Range | Practice |
|------|----------|------------|----------|
| 2 | `questionNumber` | 7-31 | 1-5 |
| 5 | `questionNumber` | 1-30 | Variable |
| 6 | `questionNumber` | 131-146 | Variable |

**Impact:**
- ❌ Cannot sort questions universally
- ❌ Must know part to interpret number
- ❌ Gaps in numbering (Part 2 starts at 7)

---

### 🟡 Issue #6: Audio Storage Inefficiency (Part 2)

**Problem:**
Audio files stored separately for each component.

**Current:**
```
part2-audio/exam/T1/
  ├── question_7.mp3
  ├── responseA_7.mp3
  ├── responseB_7.mp3
  └── responseC_7.mp3
```

**Impact:**
- ❌ 4 separate file requests per question
- ❌ Slower loading on mobile
- ❌ More complex state management

**Better Approach:**
Pre-merge audio files:
```
part2-audio/exam/T1/
  └── complete_Q7.mp3  (question + all responses in one file)
```

**Benefits:**
- ✅ 75% fewer HTTP requests
- ✅ Faster playback start
- ✅ Simpler mobile code

**Note:** Current mobile app ALREADY expects merged audio:
```dart
// part2_exam_screen.dart:104
final completeAudioUrl = question.audioFiles?['complete'] ?? '';
```

---

## 8. Recommendations

### Immediate Actions (High Priority)

#### 1. **Add `part` Field to All Documents**

```typescript
// Add to Part 2 and Part 6 documents
{
  part: 'part2' | 'part5' | 'part6',  // Explicit part identification
  ...
}
```

**Files to Update:**
- `/src/types/part2-types.ts` - Add `part: 'part2'`
- `/src/types/part6-types.ts` - Add `part: 'part6'`
- `/src/lib/services/question-service.ts` - Include in all saves

---

#### 2. **Standardize Field Names**

Option A: Rename `responses` to `options` in Part 2
```typescript
// Part 2 documents
{
  options: [string, string, string],  // Standardized name
  optionsCount: 3,                    // Explicit count
}
```

Option B: Keep `responses` but add alias
```typescript
{
  responses: [string, string, string],
  options: [string, string, string],  // Alias for compatibility
}
```

---

#### 3. **Separate Part 6 Passages from Questions**

**New Collection:**
```typescript
part6passages/
  EXAM_T1_PASSAGE_1: {
    passageId: "EXAM_T1_PASSAGE_1",
    passageNumber: 1,
    passageText: string,
    passageTextKorean: string,
    documentType: string,
    title: string,
    questionRange: "131-134",
    questionIds: ["Part6_EXAM_T1_L1_GRAM_Q131", ...]
  }
```

**Updated Questions:**
```typescript
part6examQuestions/
  Part6_EXAM_T1_L1_GRAM_Q131: {
    passageId: "EXAM_T1_PASSAGE_1",  // Reference only
    // Remove: passageText, passageTextKorean
    ...
  }
```

**Mobile App Update:**
```dart
// Fetch passage once
final passage = await getPassage(passageId);

// Fetch all 4 questions for that passage
final questions = await getQuestionsByPassage(passageId);
```

---

### Long-term Improvements (Medium Priority)

#### 4. **Consolidate Collections**

**Option A: Single `questions` collection**
```
questions/
  ├── part2_exam_T1_Q7
  ├── part2_practice_20251009_Q1
  ├── part5_exam_R1_Q1
  ├── part5_practice_20251009_Q1
  ├── part6_exam_T1_Q131
  └── part6_practice_20251009_Q1
```

**Option B: Hierarchical structure**
```
questions/
  ├── part2/
  │   ├── exam/
  │   │   └── T1_Q7
  │   └── practice/
  │       └── 20251009_Q1
  ├── part5/
  └── part6/
```

**Querying:**
```typescript
// All Part 2 exam questions
db.collection('questions')
  .where('part', '==', 'part2')
  .where('mode', '==', 'exam')

// Or with subcollections
db.collection('questions/part2/exam')
```

---

#### 5. **Add Metadata Collection per Part**

```typescript
questionMetadata/
  part2_metadata: {
    totalExamQuestions: 1250,  // 50 rounds × 25 questions
    totalPracticeQuestions: 500,
    lastExamRound: 50,
    lastPracticeDate: "2025-10-28"
  },
  part5_metadata: { ... },
  part6_metadata: { ... }
```

---

#### 6. **Implement Merged Audio for Part 2**

Update TTS service to generate single audio file:
```typescript
// part2-tts-service.ts
async generateMergedAudio(question, responses) {
  // Generate individual audio files
  const questionAudio = await generateSpeech(question.questionText);
  const responseA = await generateSpeech(responses[0]);
  const responseB = await generateSpeech(responses[1]);
  const responseC = await generateSpeech(responses[2]);

  // Merge with pauses
  const merged = await mergeAudioFiles([
    questionAudio,
    { silence: 1000 },  // 1 second pause
    responseA,
    { silence: 500 },
    responseB,
    { silence: 500 },
    responseC
  ]);

  return merged;
}
```

---

### Migration Strategy

#### Phase 1: Add Missing Fields (No Breaking Changes)
1. Add `part` field to all new Part 2/6 questions
2. Backfill existing documents with migration script
3. Update admin UI to include `part` field

#### Phase 2: Create Separate Passages Collection
1. Create `part6passages` collection
2. Extract unique passages from existing Part 6 questions
3. Update questions to reference passages
4. Update mobile app to fetch passages separately
5. Delete redundant passage data from questions

#### Phase 3: Standardize Field Names
1. Add `options` field to Part 2 (keep `responses` for compatibility)
2. Update mobile app to use `options` first, fall back to `responses`
3. Eventually deprecate `responses`

#### Phase 4: Collection Consolidation (Optional)
1. Design new unified structure
2. Migrate data in batches
3. Update all services and apps
4. Deprecate old collections

---

## Summary

### Current State
- **6 separate collections** for 3 parts × 2 modes
- **Inconsistent ID formats** across parts
- **Missing `part` field** in Part 2/6
- **Field name inconsistencies** (`responses` vs `options`)
- **Massive data duplication** in Part 6 (4x per passage)
- **Inefficient audio storage** in Part 2 (4 files per question)

### Impact
- ❌ Complex mobile app code
- ❌ Difficult maintenance
- ❌ High Firebase costs (storage + bandwidth)
- ❌ Slower mobile performance
- ❌ Data inconsistency risks

### Recommended Priority
1. **HIGH:** Add `part` field to all documents
2. **HIGH:** Separate Part 6 passages from questions
3. **MEDIUM:** Standardize field names
4. **MEDIUM:** Implement merged audio for Part 2
5. **LOW:** Consider collection consolidation

---

## File References

### Admin Project Files

**Type Definitions:**
- `/src/types/question.ts` - Part 5 (general Question type)
- `/src/types/part2-types.ts` - Part 2 specific types
- `/src/types/part6-types.ts` - Part 6 specific types

**Services:**
- `/src/lib/services/question-service.ts` - Main CRUD operations
  - Line 18-50: Collection determination logic
  - Line 172-196: Create question
  - Line 209-246: Update question
  - Line 354-359: Bulk import (collection selection)

**API Routes:**
- `/src/app/api/generate/part2/route.ts` - Part 2 generation
- `/src/app/api/generate/part6/route.ts` - Part 6 generation
- `/src/app/api/upload/exam/route.ts` - Part 5 exam upload
- `/src/app/api/upload/practice/route.ts` - Part 5 practice upload

**Mobile App References:**
- `/lib/data/models/simple_models.dart` - Question model
- `/lib/data/repositories/question_repository.dart` - Question fetching
- `/lib/features/part2/views/part2_exam_screen.dart` - Part 2 UI
- `/lib/features/part6/views/part6_exam_screen.dart` - Part 6 UI

---

## Appendix: Complete Field List

### Part 2 Fields (26 fields)
```
id, questionNumber, questionType, questionCategory, questionText,
responses, correctAnswerIndex, correctAnswer, audioFiles,
difficultyLevel, explanation, wrongAnswerAnalysis, keyPhrase,
tags, detailedExplanation, status, createdAt, updatedAt,
createdBy, updatedBy, version
```

### Part 5 Fields (19 fields)
```
id, mode, part, questionText, options, correctAnswerIndex,
questionType, grammarPoint, difficultyLevel, explanation,
tags, testNumber, questionNumber, date, status, createdAt,
updatedAt, createdBy, updatedBy, version
```

### Part 6 Fields (24 fields)
```
id, passageId, questionNumber, passageText, passageTextKorean,
passageNumber, documentType, title, questionType, questionCategory,
questionText, options, correctAnswerIndex, correctAnswer,
difficultyLevel, explanation, grammarPoint, tags,
detailedExplanation, status, createdAt, updatedAt, createdBy,
updatedBy, version
```
