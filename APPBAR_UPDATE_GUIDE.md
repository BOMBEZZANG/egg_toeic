# AppBar Home Icon Update Guide

This guide shows how to add the home navigation icon to all AppBars except the home screen.

## Changes Made

### 1. Created CustomAppBar Widget
Created `lib/core/widgets/custom_app_bar.dart` - A custom AppBar widget that:
- Adds a home icon to all screens (can be disabled with `showHomeIcon: false`)
- Maintains all existing AppBar functionality
- Simple and reliable implementation

### 2. Updated Example Screens
Updated the following screens to demonstrate the pattern:

#### Example 1: Exam Result Screen
```dart
// Before
appBar: AppBar(
  title: Text('Exam Results'),
  backgroundColor: Colors.green,
),

// After
appBar: CustomAppBar(
  title: 'Exam Results',
  backgroundColor: Colors.green,
),
```

#### Example 2: Part5 Mode Selection Screen
```dart
// Before
appBar: AppBar(
  title: const Text('파트 5: 모드 선택'),
  backgroundColor: const Color(0xFF58CC02),
  foregroundColor: Colors.white,
),

// After
appBar: CustomAppBar(
  title: '파트 5: 모드 선택',
  backgroundColor: const Color(0xFF58CC02),
  foregroundColor: Colors.white,
),
```

### 3. How to Update Your Screens

To add the home icon to any screen:

1. **Add the import:**
```dart
import 'package:egg_toeic/core/widgets/custom_app_bar.dart';
```

2. **Replace AppBar with CustomAppBar:**
```dart
// Change this:
appBar: AppBar(
  title: Text('Your Title'),
  // ... other properties
),

// To this:
appBar: CustomAppBar(
  title: 'Your Title',
  // ... other properties (same as AppBar)
),
```

### 4. Features
- ✅ **Home Navigation**: Shows home icon on all screens by default
- ✅ **Backward compatible**: Supports all existing AppBar properties
- ✅ **Customizable**: Can disable home icon with `showHomeIcon: false`
- ✅ **Navigation**: Clicking home icon navigates to `/` route
- ✅ **Tooltip**: Shows "홈으로" tooltip on home icon

### 5. For Home Screen
If you need to use CustomAppBar on the home screen itself, disable the home icon:
```dart
appBar: CustomAppBar(
  title: 'Home',
  showHomeIcon: false, // Disable home icon on home screen
),
```

### 5. Updated Files
- `lib/core/widgets/custom_app_bar.dart` (new)
- `lib/features/part5/views/exam_result_screen.dart`
- `lib/features/part5/views/exam_mode_screen.dart`
- `lib/features/part5/views/part5_mode_selection_screen.dart`

### 6. Next Steps
To complete the home icon implementation across the entire app:

1. **Update remaining screens** - Replace `AppBar` with `CustomAppBar` in:
   - Practice mode screens
   - Statistics screens
   - Settings screens
   - Other feature screens

2. **Search and replace pattern:**
```bash
# Find all AppBar usages
grep -r "appBar: AppBar" lib/

# Replace with CustomAppBar following the pattern above
```

### 7. Benefits
- **Consistent navigation**: Users can always return to home from any screen
- **Better UX**: No need to use back button multiple times
- **Automatic**: No manual route detection needed
- **Maintainable**: Single widget to manage home navigation logic