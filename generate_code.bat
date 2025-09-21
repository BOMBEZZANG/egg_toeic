@echo off
echo "Generating Freezed and Hive code..."
cd /d C:\Projects\egg_toeic
flutter pub get
dart run build_runner build --delete-conflicting-outputs
echo "Code generation complete!"
pause