# TOEIC Part 5 Learning App - MVP Development Requirements Document

## 📋 Project Overview

### Product Name
**Egg_Toeic - Part 5 Practice App**

### Project Scope
Development of a mobile application for TOEIC Part 5 (Incomplete Sentences) practice with gamification elements and learning analytics. This MVP focuses solely on Part 5, with Part 2 planned for v2.0.

### Target Platform
- Flutter (Cross-platform: iOS & Android)
- Minimum iOS: 12.0
- Minimum Android: API 21 (5.0)

### Development Timeline
4 weeks (Week 1-4 phases)

---

## 🏗️ Technical Architecture

### Architecture Pattern
**Feature-First + MVVM with Riverpod**

### Tech Stack
```yaml
Core Technologies:
- Flutter: 3.16.0+
- Dart: 3.2.0+
- State Management: Riverpod 2.4.0+

Local Storage:
- Hive Flutter: 1.1.0+ (learning records, wrong answers)
- Shared Preferences: 2.2.0+ (user settings)

Backend:
- Firebase Core: 2.24.0+
- Cloud Firestore: 4.13.0+ (questions database only)
- Firebase Analytics: 10.7.0+

Code Generation:
- Freezed: 2.4.0+
- JSON Serializable: 6.7.0+
- Build Runner: 2.4.0+

UI/UX:
- Lottie: 2.7.0+ (animations)
- FL Chart: 0.65.0+ (statistics)
```

### Data Architecture
- **Remote Data**: Firebase Firestore (Read-only question bank)
- **Local Data**: All user data stored locally using Hive
- **No User Authentication**: Anonymous usage with local storage

---

## 📅 Development Phases

### **Phase 1: Foundation & Architecture Setup (Week 1)**

#### Objectives
Establish project structure, core architecture, and data models.

#### Deliverables

##### 1.1 Project Structure Setup
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── app_dimensions.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── logger.dart
│       └── extensions.dart
│
├── data/
│   ├── models/
│   │   ├── question_model.dart
│   │   ├── user_progress_model.dart
│   │   ├── learning_session_model.dart
│   │   └── achievement_model.dart
│   ├── repositories/
│   │   ├── question_repository.dart
│   │   └── user_data_repository.dart
│   └── datasources/
│       ├── remote/
│       │   └── firebase_service.dart
│       └── local/
│           └── hive_service.dart
│
├── features/
│   └── (to be implemented in Phase 2)
│
├── providers/
│   └── app_providers.dart
│
└── main.dart
```

##### 1.2 Data Models (with Freezed)

**Question Model**
```dart
@freezed
class Question with _$Question {
  factory Question({
    required String id,
    required String questionText,
    required List<String> options, // 4 options
    required int correctAnswerIndex, // 0-3
    required int difficultyLevel, // 1-3
    required String explanation,
    required String grammarPoint,
    List<String>? tags,
    DateTime? createdAt,
  }) = _Question;
}
```

**User Progress Model**
```dart
@freezed
class UserProgress with _$UserProgress {
  factory UserProgress({
    required int totalQuestionsAnswered,
    required int correctAnswers,
    required int currentStreak,
    required int longestStreak,
    required int experiencePoints,
    required int userLevel,
    required DateTime lastStudyDate,
    required Map<String, int> levelProgress, // {level1: %, level2: %, level3: %}
    required List<String> unlockedAchievements,
    required List<String> favoriteQuestions,
    required List<WrongAnswer> wrongAnswers,
  }) = _UserProgress;
}
```

**Wrong Answer Model**
```dart
@freezed
class WrongAnswer with _$WrongAnswer {
  factory WrongAnswer({
    required String questionId,
    required int selectedAnswer,
    required DateTime answeredAt,
    required int reviewCount,
    bool isResolved = false,
  }) = _WrongAnswer;
}
```

##### 1.3 Repository Interfaces
Define clear contracts for data operations.

##### 1.4 Firebase Setup
- Configure Firebase project
- Create Firestore structure:
```
questions_part5/
  └── {questionId}/
      ├── questionText
      ├── options[]
      ├── correctAnswerIndex
      ├── difficultyLevel
      ├── explanation
      └── grammarPoint
```

##### 1.5 Hive Database Schema
- Configure Hive boxes
- Define adapters for models

---

### **Phase 2: Part 5 Core Functionality (Week 2)**

#### Objectives
Implement complete Part 5 learning flow with immediate feedback.

#### Deliverables

##### 2.1 Feature Structure
```
features/
├── home/
│   ├── views/
│   │   └── home_screen.dart
│   └── viewmodels/
│       └── home_viewmodel.dart
│
├── part5/
│   ├── views/
│   │   ├── part5_home_screen.dart
│   │   ├── practice_mode_screen.dart
│   │   ├── question_screen.dart
│   │   └── explanation_screen.dart
│   ├── viewmodels/
│   │   ├── part5_viewmodel.dart
│   │   └── question_viewmodel.dart
│   └── widgets/
│       ├── question_card.dart
│       ├── option_button.dart
│       ├── progress_indicator.dart
│       └── result_feedback.dart
│
└── wrong_answers/
    ├── views/
    │   └── wrong_answers_screen.dart
    └── viewmodels/
        └── wrong_answers_viewmodel.dart
```

##### 2.2 Main Features

**Home Screen**
- Card-based navigation with playful design
- Display: Current streak, Level, XP
- Three main buttons:
  - "Start Learning Part 5"
  - "Wrong Answers Review"
  - "Learning Statistics"

**Part 5 Learning Flow**
1. **Level Selection Screen**
   - Three difficulty levels (Beginner/Intermediate/Advanced)
   - Show progress percentage for each level
   - Lock/unlock mechanism based on progress

2. **Practice Mode Screen**
   - Display question with 4 options
   - Immediate feedback on selection:
     - Correct: Green highlight + success animation
     - Wrong: Red highlight on selected + Green on correct
   - "Show Explanation" button appears after answer
   - "Next Question" button

3. **Explanation Screen**
   - Detailed grammar explanation
   - Why other options are incorrect
   - Related grammar tips
   - "Add to Favorites" button
   - "Next Question" button

##### 2.3 UI/UX Requirements

**Design System**
- **Primary Color**: Playful blue (#4A90E2)
- **Success Color**: Green (#4CAF50)
- **Error Color**: Red (#F44336)
- **Background**: Light gradient (#F5F7FA → #C3CFE2)

**Typography**
- Question Text: 18sp, Medium weight
- Options: 16sp, Regular weight
- Explanations: 14sp, Regular weight

**Animations**
- Question transition: Slide in from right
- Correct answer: Confetti animation (Lottie)
- Wrong answer: Shake animation
- Level up: Trophy animation

##### 2.4 Question Loading Logic
```dart
class QuestionViewModel {
  // Load 10 questions at a time from Firebase
  // Cache in memory for offline access
  // Randomize order but avoid repetition
  // Track question history in session
}
```

---

### **Phase 3: Local Storage & Analytics (Week 3)**

#### Objectives
Implement comprehensive local data persistence and learning analytics.

#### Deliverables

##### 3.1 Local Storage Implementation

**Hive Boxes**
```dart
// User Progress Box
Box<UserProgress> userProgressBox;

// Wrong Answers Box  
Box<List<WrongAnswer>> wrongAnswersBox;

// Favorite Questions Box
Box<List<String>> favoritesBox;

// Learning Sessions Box
Box<List<LearningSession>> sessionsBox;
```

**Data Persistence Logic**
- Auto-save after each question
- Daily backup of progress
- Data migration support

##### 3.2 Statistics Feature
```
features/
└── statistics/
    ├── views/
    │   ├── statistics_screen.dart
    │   └── detailed_stats_screen.dart
    ├── viewmodels/
    │   └── statistics_viewmodel.dart
    └── widgets/
        ├── accuracy_chart.dart
        ├── progress_chart.dart
        ├── study_calendar.dart
        └── stat_summary_card.dart
```

**Statistics Dashboard**
1. **Overview Section**
   - Total questions answered
   - Overall accuracy rate
   - Current streak
   - Study time this week

2. **Progress Charts**
   - Daily activity (bar chart)
   - Accuracy trend (line chart)
   - Level distribution (pie chart)

3. **Detailed Analytics**
   - Grammar point performance
   - Time per question average
   - Weakest areas identification
   - Improvement suggestions

##### 3.3 Wrong Answer Management

**Wrong Answer Screen Features**
- List of all wrong answers
- Filter by: Date, Grammar point, Level
- Review mode with original context
- Mark as "Resolved" after correct retry
- Smart review scheduling (spaced repetition)

##### 3.4 Data Export/Import
- Export progress as JSON
- Share progress summary
- Manual backup option

---

### **Phase 4: Gamification & UI Polish (Week 4)**

#### Objectives
Add engagement features and polish the overall user experience.

#### Deliverables

##### 4.1 Gamification System

**Experience & Leveling**
```dart
class GameSystem {
  // XP Rewards:
  // Correct answer: +10 XP
  // Wrong answer: +3 XP
  // Daily streak: +50 XP
  // Complete 10 questions: +30 XP
  
  // Levels:
  // Level 1: 0-100 XP
  // Level 2: 101-300 XP
  // Level 3: 301-600 XP
  // etc. (exponential growth)
}
```

**Achievement System**
```
Achievements:
├── First Steps (Answer first question)
├── Perfectionist (10 correct in a row)
├── Daily Warrior (7-day streak)
├── Grammar Master (100% in specific grammar)
├── Speed Demon (Answer in <5 seconds)
├── Persistent (Review 50 wrong answers)
└── Level Milestones (Reach levels 5, 10, 20...)
```

**Daily Challenges**
- "Answer 20 questions"
- "Get 15 correct answers"
- "Review 5 wrong answers"
- "Study for 15 minutes"

##### 4.2 Character System
```
Character Evolution:
Level 1-5: Egg 🥚
Level 6-10: Chick 🐣
Level 11-20: Bird 🐦
Level 21-30: Eagle 🦅
Level 31+: Phoenix 🔥
```

##### 4.3 UI Enhancements

**Micro-interactions**
- Button press effects
- Page transitions
- Pull-to-refresh animations
- Sound effects (optional)

**Empty States**
- Friendly illustrations
- Encouraging messages
- Call-to-action buttons

**Loading States**
- Skeleton screens
- Progress indicators
- Entertaining loading messages

##### 4.4 Settings Screen
```
Settings:
├── Sound Effects (ON/OFF)
├── Daily Reminder Time
├── Question Timer (Optional)
├── Reset Progress
├── About
└── Version Info
```

##### 4.5 Onboarding Flow
- 3-screen tutorial
- Interactive demo question
- Personalization (difficulty preference)
- Enable notifications prompt

---

## 🧪 Testing Requirements

### Unit Tests
- All ViewModels
- Repository implementations
- Data models
- Utility functions

### Widget Tests
- Critical user flows
- Custom widgets
- Navigation

### Integration Tests
- Complete learning session
- Statistics calculation
- Achievement unlocking

---

## 📱 Performance Requirements

- App size: < 50MB
- Cold start: < 3 seconds
- Question loading: < 500ms
- Smooth 60 FPS animations
- Offline capability (except initial question download)

---

## 🎯 Success Metrics

- Daily Active Users (DAU)
- Average session duration > 10 minutes
- 7-day retention > 40%
- Questions per session > 15
- Crash rate < 1%

---

## 🚀 Deployment

### MVP Release Checklist
- [ ] All Phase 1-4 features complete
- [ ] Minimum 500 questions in database
- [ ] Testing coverage > 80%
- [ ] Performance benchmarks met
- [ ] Privacy policy prepared
- [ ] App store assets ready
- [ ] Analytics configured

### Post-MVP Roadmap
- Version 1.1: Bug fixes & performance
- Version 1.2: Social features
- Version 2.0: Part 2 (Listening) addition

---

## 📝 Additional Notes

1. **No user authentication in MVP** - All data stored locally
2. **No ads in MVP** - Focus on core experience
3. **English-only UI** initially
4. **Questions must be legally sourced** or created
5. **Follow Material Design** and iOS HIG guidelines

---

## 🤝 Communication

- Daily standup updates
- Weekly progress demos
- Bi-weekly retrospectives
- Slack for async communication
- GitHub for code management

**Project Start Date**: [TO BE FILLED]
**Expected Completion**: Start Date + 4 weeks

---

This document serves as the single source of truth for MVP development. Any changes must be documented and approved before implementation.