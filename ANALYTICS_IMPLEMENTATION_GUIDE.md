# Question Analytics Implementation Guide

## 🎯 Overview
This implementation allows you to track every user's answer to each question and display aggregated statistics showing correct/wrong answer rates for each question.

## 📊 What We've Built

### 1. **Data Models**
- **`UserAnswer`** - Tracks individual user submissions
- **`QuestionAnalytics`** - Stores aggregated statistics per question

### 2. **Firebase Collections**
- **`userAnswers`** - Individual user submissions
- **`questionAnalytics`** - Aggregated question statistics

### 3. **Services & Repositories**
- **`AnalyticsService`** - Firebase operations
- **`AnalyticsRepository`** - Business logic layer
- **Providers** - Riverpod state management

### 4. **UI Components**
- **`QuestionAnalyticsWidget`** - Displays question statistics

## 🚀 How to Use

### 1. Submit User Answers
```dart
// In your question answering screen
final analyticsRepo = ref.read(analyticsRepositoryProvider);

await analyticsRepo.submitAnswer(
  userId: currentUser.id,
  question: currentQuestion,
  selectedAnswerIndex: userSelectedIndex,
  sessionId: sessionId, // Optional
  timeSpentSeconds: timeSpent, // Optional
);
```

### 2. Display Question Analytics
```dart
// Show analytics for a specific question
Consumer(
  builder: (context, ref, child) {
    final analyticsAsync = ref.watch(questionAnalyticsProvider(questionId));

    return analyticsAsync.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading analytics'),
      data: (analytics) => QuestionAnalyticsWidget(
        analytics: analytics,
        isCompact: true, // or false for detailed view
      ),
    );
  },
)
```

### 3. Show Multiple Question Analytics
```dart
// Analytics for multiple questions (e.g., in question list)
final analyticsAsync = ref.watch(multipleQuestionAnalyticsProvider(questionIds));

return analyticsAsync.when(
  data: (analyticsList) => ListView.builder(
    itemCount: questions.length,
    itemBuilder: (context, index) {
      final question = questions[index];
      final analytics = analyticsList.firstWhere(
        (a) => a.questionId == question.id,
        orElse: () => null,
      );

      return ListTile(
        title: Text(question.questionText),
        trailing: QuestionAnalyticsWidget(
          analytics: analytics,
          isCompact: true,
        ),
      );
    },
  ),
  // ... loading/error states
);
```

### 4. User Performance Stats
```dart
// Get comprehensive user performance
final userStatsAsync = ref.watch(userPerformanceStatsProvider(userId));

return userStatsAsync.when(
  data: (stats) => Column(
    children: [
      Text('Total Answered: ${stats['totalAnswered']}'),
      Text('Accuracy: ${stats['accuracy']}%'),
      Text('Average Time: ${stats['averageTime']}s'),
      Text('Strong Points: ${stats['strongGrammarPoints'].join(', ')}'),
      Text('Weak Points: ${stats['weakGrammarPoints'].join(', ')}'),
    ],
  ),
  // ... other states
);
```

## 🔧 Firebase Setup Required

### 1. Deploy Updated Security Rules
```bash
cd /mnt/c/Projects/toeic-egg-admin
firebase deploy --only firestore:rules
```

### 2. Verify Collections
The system will automatically create collections when first used:
- `/userAnswers/{answerId}`
- `/questionAnalytics/{questionId}`

## 📈 Analytics Features

### Question Analytics Include:
- **Success Rate** - Overall correct percentage
- **Total Attempts** - Number of users who answered
- **Answer Distribution** - How many chose each option (A/B/C/D)
- **Average Time** - How long users take to answer
- **Difficulty Assessment** - Easy/Medium/Hard based on success rate
- **Mode/Type** - Practice vs Exam, Grammar vs Vocabulary

### User Analytics Include:
- **Personal Performance** - Accuracy, total answered, average time
- **Grammar Point Analysis** - Strong vs weak areas
- **Learning Trends** - Progress over time

## 🎨 UI Examples

### Compact Analytics View
```dart
QuestionAnalyticsWidget(
  analytics: analytics,
  isCompact: true, // Shows: 78% correct, 45 attempts, Level 2
)
```

### Detailed Analytics View
```dart
QuestionAnalyticsWidget(
  analytics: analytics,
  isCompact: false, // Shows: Full breakdown with charts
)
```

## 📋 Next Steps

### Integration Points:
1. **Question Screens** - Add `submitAnswer()` when user answers
2. **Question Lists** - Show analytics in question overview
3. **Review Screens** - Highlight difficult questions
4. **Statistics Page** - Add comprehensive analytics dashboard
5. **Teacher Dashboard** - Show which questions need review

### Code Generation:
```bash
# Run this to generate Freezed models
dart run build_runner build
```

### Example Integration:
See `ANALYTICS_IMPLEMENTATION_GUIDE.md` for complete examples of integrating into your existing question screens.

## 🔒 Security
- Users can only submit their own answers
- Analytics are publicly readable (for showing stats)
- Only admins can modify analytics data
- Validated data structure in Firestore rules

## 📊 Sample Analytics Output
```
Question: "If Ms. Clark ____ the interview..."
✅ 78.5% Success Rate (157/200 attempts)
📊 Answer Distribution:
   A) had attended: 78.5% ✓ (correct)
   B) will attend: 12.3%
   C) attends: 6.7%
   D) attended: 2.5%
⏱️ Average Time: 23 seconds
📈 Difficulty: Medium
```

The system is now ready to collect analytics and display meaningful insights about question performance!