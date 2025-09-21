import 'package:hive_flutter/hive_flutter.dart';
import 'package:egg_toeic/core/constants/hive_constants.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    _initialized = true;
  }

  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_initialized) {
      await initialize();
    }

    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }

    return await Hive.openBox<T>(boxName);
  }

  Future<void> closeBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
    }
  }

  Future<void> deleteBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
  }

  Future<void> clearAllData() async {
    final boxNames = [
      HiveConstants.userProgressBox,
      HiveConstants.wrongAnswersBox,
      HiveConstants.favoritesBox,
      HiveConstants.sessionsBox,
      HiveConstants.settingsBox,
    ];

    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }

  Future<void> registerAdapters() async {
    // Adapters will be registered in the repository implementations
    // This method is kept for future use if needed
  }

  bool get isInitialized => _initialized;

  Future<void> compactAllBoxes() async {
    final boxNames = [
      HiveConstants.userProgressBox,
      HiveConstants.wrongAnswersBox,
      HiveConstants.favoritesBox,
      HiveConstants.sessionsBox,
      HiveConstants.settingsBox,
    ];

    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).compact();
      }
    }
  }

  Future<Map<String, int>> getBoxSizes() async {
    final boxNames = [
      HiveConstants.userProgressBox,
      HiveConstants.wrongAnswersBox,
      HiveConstants.favoritesBox,
      HiveConstants.sessionsBox,
      HiveConstants.settingsBox,
    ];

    final sizes = <String, int>{};

    for (final boxName in boxNames) {
      if (Hive.isBoxOpen(boxName)) {
        sizes[boxName] = Hive.box(boxName).length;
      }
    }

    return sizes;
  }
}