# Code Generation Instructions

## ⚠️ Important: Code Generation Required

The project uses **Freezed** for data models and **Hive** for local storage. Before the app can run properly, you need to generate the required code files.

## 🚀 How to Generate Code

### Option 1: Using the Batch Script (Windows)
```bash
# Run the provided batch script
generate_code.bat
```

### Option 2: Manual Commands
```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code
dart run build_runner build --delete-conflicting-outputs
```

### Option 3: Watch Mode (Development)
```bash
# For continuous code generation during development
dart run build_runner watch --delete-conflicting-outputs
```

## 🔧 What Gets Generated

The code generation will create these files:

### Freezed Files (Data Models)
- `lib/data/models/question_model.freezed.dart`
- `lib/data/models/user_progress_model.freezed.dart`
- `lib/data/models/wrong_answer_model.freezed.dart`
- `lib/data/models/learning_session_model.freezed.dart`
- `lib/data/models/achievement_model.freezed.dart`

### JSON Serialization Files
- `lib/data/models/question_model.g.dart`
- `lib/data/models/user_progress_model.g.dart`
- `lib/data/models/wrong_answer_model.g.dart`
- `lib/data/models/learning_session_model.g.dart`
- `lib/data/models/achievement_model.g.dart`

### Hive Adapter Files
- Hive adapters for local storage of all models

## ✅ After Code Generation

1. **Uncomment the part imports** in all model files:
   ```dart
   // Change from:
   // part 'model_name.freezed.dart';
   // part 'model_name.g.dart';

   // To:
   part 'model_name.freezed.dart';
   part 'model_name.g.dart';
   ```

2. **Files to update**:
   - `lib/data/models/question_model.dart`
   - `lib/data/models/user_progress_model.dart`
   - `lib/data/models/wrong_answer_model.dart`
   - `lib/data/models/learning_session_model.dart`
   - `lib/data/models/achievement_model.dart`

3. **Run the app**:
   ```bash
   flutter run
   ```

## 🐛 Troubleshooting

### Build Runner Issues
```bash
# Clean and regenerate
flutter packages pub run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Dependency Issues
```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Permission Issues
```bash
# Make sure you have write permissions in the project directory
# On Windows, run command prompt as Administrator if needed
```

## 📁 Generated File Structure

After generation, your project will have:

```
lib/data/models/
├── achievement_model.dart          ✅ Source
├── achievement_model.freezed.dart  🔄 Generated
├── achievement_model.g.dart        🔄 Generated
├── question_model.dart             ✅ Source
├── question_model.freezed.dart     🔄 Generated
├── question_model.g.dart           🔄 Generated
├── user_progress_model.dart        ✅ Source
├── user_progress_model.freezed.dart 🔄 Generated
├── user_progress_model.g.dart      🔄 Generated
├── wrong_answer_model.dart         ✅ Source
├── wrong_answer_model.freezed.dart 🔄 Generated
├── wrong_answer_model.g.dart       🔄 Generated
├── learning_session_model.dart     ✅ Source
├── learning_session_model.freezed.dart 🔄 Generated
└── learning_session_model.g.dart   🔄 Generated
```

## 🎯 Why Code Generation?

- **Freezed**: Provides immutable data classes with `copyWith`, `==`, `hashCode`, and `toString` methods
- **JSON Serialization**: Automatic `toJson()` and `fromJson()` methods
- **Hive Adapters**: Type-safe local storage adapters
- **Type Safety**: Compile-time guarantees for data models
- **Performance**: Optimized code generation for better runtime performance

---

**Note**: The part imports are currently commented out to prevent compilation errors. Uncomment them after running code generation!