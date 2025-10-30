import 'package:flutter/material.dart';
import '../models/activity.dart';
import '../services/storage_service.dart';

class ActivityProvider extends ChangeNotifier {
  List<Activity> _activities = [];
  Map<String, String> _categoryColors = {};
  bool _isLoading = false;
  
  List<Activity> get activities => _activities;
  Map<String, String> get categoryColors => _categoryColors;
  bool get isLoading => _isLoading;
  
  List<String> get categories => _activities
      .map((a) => a.category)
      .toSet()
      .toList()
    ..sort();
  
  List<String> get providers => _activities
      .map((a) => a.provider)
      .where((p) => p != 'Sin proveedor')
      .toSet()
      .toList()
    ..sort();
    
  List<String> get countries => _activities
      .map((a) => a.country)
      .where((c) => c != 'Sin país')
      .toSet()
      .toList()
    ..sort();

  ActivityProvider() {
    loadActivities();
  }

  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();
    
    _activities = StorageService.getAllActivities();
    _categoryColors = StorageService.getAllCategoryColors();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addActivity(Activity activity) async {
    await StorageService.saveActivity(activity);
    _activities.insert(0, activity);
    notifyListeners();
  }

  Future<void> updateActivity(Activity activity) async {
    await StorageService.updateActivity(activity);
    final index = _activities.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      _activities[index] = activity;
      notifyListeners();
    }
  }

  Future<void> deleteActivity(String id) async {
    await StorageService.deleteActivity(id);
    _activities.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> applyCategoryColor(String category, String colorHex) async {
    await StorageService.applyCategoryColorToActivities(category, colorHex);
    _categoryColors[category] = colorHex;
    
    // Update activities in memory
    for (var activity in _activities) {
      if (activity.category == category) {
        activity.colorHex = colorHex;
      }
    }
    notifyListeners();
  }

  String? getCategoryColor(String category) {
    return _categoryColors[category];
  }

  List<Activity> getFilteredActivities({
    String? category,
    String? provider,
    String? country,
    String? searchQuery,
  }) {
    var filtered = _activities;
    
    if (category != null && category != 'Todas las categorías') {
      filtered = filtered.where((a) => a.category == category).toList();
    }
    
    if (provider != null && provider != 'Todos los proveedores') {
      filtered = filtered.where((a) => a.provider == provider).toList();
    }
    
    if (country != null && country != 'Todos los países') {
      filtered = filtered.where((a) => a.country == country).toList();
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((a) => 
        a.name.toLowerCase().contains(query) ||
        a.category.toLowerCase().contains(query) ||
        a.notes?.toLowerCase().contains(query) == true
      ).toList();
    }
    
    return filtered;
  }

  Map<String, Duration> getActivityIntervals(String activityName) {
    final sameActivities = _activities
        .where((a) => a.name.toLowerCase() == activityName.toLowerCase())
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    
    if (sameActivities.length < 2) {
      return {'average': Duration.zero, 'last': Duration.zero};
    }
    
    final intervals = <Duration>[];
    for (int i = 1; i < sameActivities.length; i++) {
      intervals.add(sameActivities[i].date.difference(sameActivities[i - 1].date));
    }
    
    final totalSeconds = intervals.fold<int>(
      0,
      (sum, interval) => sum + interval.inSeconds,
    );
    final averageSeconds = totalSeconds ~/ intervals.length;
    
    return {
      'average': Duration(seconds: averageSeconds),
      'last': intervals.last,
      'min': intervals.reduce((a, b) => a.inSeconds < b.inSeconds ? a : b),
      'max': intervals.reduce((a, b) => a.inSeconds > b.inSeconds ? a : b),
    };
  }

  Map<String, int> getWeeklyFrequency() {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    final weekActivities = _activities
        .where((a) => a.date.isAfter(oneWeekAgo))
        .toList();
    
    final Map<String, int> frequency = {
      'Lun': 0,
      'Mar': 0,
      'Mié': 0,
      'Jue': 0,
      'Vie': 0,
      'Sáb': 0,
      'Dom': 0,
    };
    
    final dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    
    for (var activity in weekActivities) {
      final dayName = dayNames[activity.date.weekday];
      frequency[dayName] = (frequency[dayName] ?? 0) + 1;
    }
    
    return frequency;
  }

  Map<String, dynamic> getStatistics() {
    return StorageService.getStatistics();
  }

  Map<String, int> getCategoryDistribution() {
    return StorageService.getCategoryDistribution();
  }

  Map<String, int> getProviderDistribution() {
    return StorageService.getProviderDistribution();
  }

  Map<String, int> getCountryDistribution() {
    return StorageService.getCountryDistribution();
  }
}
