import 'dart:convert';

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

    await _migrateLegacyData();
  }

  // Activities
  static Future<void> saveActivity(Activity activity) async {
    _normalizeActivityFields(activity);
    await activitiesBox.put(activity.id, activity);
  }

  static List<Activity> getAllActivities() {
    final activities = activitiesBox.values.toList();
    for (final activity in activities) {
      _normalizeActivityFields(activity);
    }
    activities.sort((a, b) => b.date.compareTo(a.date));
    return activities;
  }

  static List<Activity> getActivitiesByCategory(String category) {
    final normalizedCategory = _normalizeText(category);
    return activitiesBox.values
        .where((activity) {
          _normalizeActivityFields(activity);
          return activity.category == normalizedCategory;
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<Activity> getActivitiesByName(String name) {
    final normalizedName = _normalizeText(name);
    return activitiesBox.values
        .where((activity) {
          _normalizeActivityFields(activity);
          return _normalizeText(activity.name).toLowerCase() ==
              normalizedName.toLowerCase();
        })
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> updateActivity(Activity activity) async {
    _normalizeActivityFields(activity);
    await activitiesBox.put(activity.id, activity);
  }

  static Future<void> deleteActivity(String id) async {
    await activitiesBox.delete(id);
  }

  static Activity? getActivity(String id) {
    final activity = activitiesBox.get(id);
    if (activity != null) {
      _normalizeActivityFields(activity);
    }
    return activity;
  }

  // Categories with colors
  static Future<void> saveCategoryColor(String category, String colorHex) async {
    final normalizedCategory = _normalizeText(category);
    await categoriesBox.put(normalizedCategory, colorHex);
  }

  static String? getCategoryColor(String category) {
    final normalizedCategory = _normalizeText(category);
    return categoriesBox.get(normalizedCategory);
  }

  static Map<String, String> getAllCategoryColors() {
    final Map<String, String> colors = {};
    for (var key in categoriesBox.keys) {
      if (key is String) {
        final normalizedKey = _normalizeText(key);
        final value = categoriesBox.get(key);
        if (value is String) {
          colors[normalizedKey] = value;
        }
      }
    }
    return colors;
  }

  static Future<void> applyCategoryColorToActivities(String category, String colorHex) async {
    final normalizedCategory = _normalizeText(category);
    final activities = getActivitiesByCategory(normalizedCategory);
    for (var activity in activities) {
      activity.colorHex = colorHex;
      await updateActivity(activity);
    }
    await saveCategoryColor(normalizedCategory, colorHex);
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

  static Future<void> _migrateLegacyData() async {
    for (final activity in activitiesBox.values) {
      if (_normalizeActivityFields(activity)) {
        await activity.save();
      }
    }

    final keys = categoriesBox.keys.whereType<String>().toList();
    for (final key in keys) {
      final normalizedKey = _normalizeText(key);
      if (normalizedKey != key) {
        final value = categoriesBox.get(key);
        await categoriesBox.delete(key);
        await categoriesBox.put(normalizedKey, value);
      }
    }
  }

  static bool _normalizeActivityFields(Activity activity) {
    var changed = false;

    final normalizedName = _normalizeText(activity.name);
    if (normalizedName != activity.name) {
      activity.name = normalizedName;
      changed = true;
    }

    final normalizedCategory = _normalizeText(activity.category);
    if (normalizedCategory != activity.category) {
      activity.category = normalizedCategory;
      changed = true;
    }

    final normalizedProvider = _normalizeText(activity.provider);
    if (normalizedProvider != activity.provider) {
      activity.provider = normalizedProvider;
      changed = true;
    }

    final normalizedCountry = _normalizeText(activity.country);
    if (normalizedCountry != activity.country) {
      activity.country = normalizedCountry;
      changed = true;
    }

    if (activity.notes != null) {
      final normalizedNotes = _normalizeText(activity.notes!);
      if (normalizedNotes != activity.notes) {
        activity.notes = normalizedNotes;
        changed = true;
      }
    }

    return changed;
  }

  static String _normalizeText(String value) {
    var normalized = value;

    if (normalized.contains('Ã') || normalized.contains('Â') || normalized.contains('â')) {
      try {
        normalized = utf8.decode(latin1.encode(normalized), allowMalformed: true);
      } catch (_) {
        // ignore decoding errors and keep original value
      }
    }

    const replacements = {
      'Sin categor\u00eda': 'Sin categoría',
      'Sin categor�a': 'Sin categoría',
      'Sin pa\u00eds': 'Sin país',
      'Sin pa�s': 'Sin país',
      'categor\u00eda': 'categoría',
      'categor�a': 'categoría',
      'Categor\u00eda': 'Categoría',
      'Categor�a': 'Categoría',
      'categor\u00edas': 'categorías',
      'categor�as': 'categorías',
      'Categor\u00edas': 'Categorías',
      'Categor�as': 'Categorías',
      'pa\u00eds': 'país',
      'pa�s': 'país',
      'Pa\u00eds': 'País',
      'Pa�s': 'País',
      'pa\u00edses': 'países',
      'pa�ses': 'países',
      'Pa\u00edses': 'Países',
      'Pa�ses': 'Países',
      'Listo': 'Listo',
    };

    for (final entry in replacements.entries) {
      if (normalized.contains(entry.key)) {
        normalized = normalized.replaceAll(entry.key, entry.value);
      }
    }

    return normalized;
  }
}

