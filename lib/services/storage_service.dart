import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity.dart';

class StorageService {
  static const String activitiesBoxName = 'activities';
  static const String settingsBoxName = 'settings';
  static const String categoriesBoxName = 'categories';
  
  static late Box<Activity> activitiesBox;
  static late Box settingsBox;
  static late Box categoriesBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ActivityAdapter());
    }
    
    // Open boxes
    activitiesBox = await Hive.openBox<Activity>(activitiesBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
    categoriesBox = await Hive.openBox(categoriesBoxName);
  }

  // Activities
  static Future<void> saveActivity(Activity activity) async {
    await activitiesBox.put(activity.id, activity);
  }

  static List<Activity> getAllActivities() {
    return activitiesBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Activity> getActivitiesByCategory(String category) {
    return activitiesBox.values
        .where((activity) => activity.category == category)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Activity> getActivitiesByName(String name) {
    return activitiesBox.values
        .where((activity) => activity.name.toLowerCase() == name.toLowerCase())
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> updateActivity(Activity activity) async {
    await activitiesBox.put(activity.id, activity);
  }

  static Future<void> deleteActivity(String id) async {
    await activitiesBox.delete(id);
  }

  static Activity? getActivity(String id) {
    return activitiesBox.get(id);
  }

  // Categories with colors
  static Future<void> saveCategoryColor(String category, String colorHex) async {
    await categoriesBox.put(category, colorHex);
  }

  static String? getCategoryColor(String category) {
    return categoriesBox.get(category);
  }

  static Map<String, String> getAllCategoryColors() {
    final Map<String, String> colors = {};
    for (var key in categoriesBox.keys) {
      colors[key as String] = categoriesBox.get(key) as String;
    }
    return colors;
  }

  static Future<void> applyCategoryColorToActivities(String category, String colorHex) async {
    final activities = getActivitiesByCategory(category);
    for (var activity in activities) {
      activity.colorHex = colorHex;
      await updateActivity(activity);
    }
    await saveCategoryColor(category, colorHex);
  }

  // Settings
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue);
  }

  // Statistics
  static Map<String, dynamic> getStatistics() {
    final activities = getAllActivities();
    final uniqueNames = activities.map((a) => a.name.toLowerCase()).toSet();
    final categories = activities.map((a) => a.category).toSet();
    final providers = activities.map((a) => a.provider).where((p) => p != 'Sin proveedor').toSet();
    final countries = activities.map((a) => a.country).where((c) => c != 'Sin país').toSet();
    
    final activeDates = activities.map((a) => 
        DateTime(a.date.year, a.date.month, a.date.day)).toSet();

    return {
      'totalActivities': activities.length,
      'uniqueActivities': uniqueNames.length,
      'categories': categories.length,
      'providers': providers.length,
      'countries': countries.length,
      'activeDays': activeDates.length,
    };
  }

  static Map<String, int> getCategoryDistribution() {
    final activities = getAllActivities();
    final Map<String, int> distribution = {};
    
    for (var activity in activities) {
      distribution[activity.category] = (distribution[activity.category] ?? 0) + 1;
    }
    
    return distribution;
  }

  static Map<String, int> getProviderDistribution() {
    final activities = getAllActivities()
        .where((a) => a.provider != 'Sin proveedor')
        .toList();
    final Map<String, int> distribution = {};
    
    for (var activity in activities) {
      distribution[activity.provider] = (distribution[activity.provider] ?? 0) + 1;
    }
    
    return distribution;
  }

  static Map<String, int> getCountryDistribution() {
    final activities = getAllActivities()
        .where((a) => a.country != 'Sin país')
        .toList();
    final Map<String, int> distribution = {};
    
    for (var activity in activities) {
      distribution[activity.country] = (distribution[activity.country] ?? 0) + 1;
    }
    
    return distribution;
  }

  // Clean all data
  static Future<void> clearAllData() async {
    await activitiesBox.clear();
    await settingsBox.clear();
    await categoriesBox.clear();
  }
}