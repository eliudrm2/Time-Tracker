import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'activity.g.dart';

@HiveType(typeId: 0)
class Activity extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String category;
  
  @HiveField(3)
  String provider;
  
  @HiveField(4)
  String country;
  
  @HiveField(5)
  DateTime date;
  
  @HiveField(6)
  String colorHex;
  
  @HiveField(7)
  String? notes;
  
  @HiveField(8)
  DateTime createdAt;

  Activity({
    String? id,
    required this.name,
    required this.category,
    required this.provider,
    required this.country,
    required this.date,
    required this.colorHex,
    this.notes,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  
  set color(Color newColor) {
    final red = newColor.red.toRadixString(16).padLeft(2, '0');
    final green = newColor.green.toRadixString(16).padLeft(2, '0');
    final blue = newColor.blue.toRadixString(16).padLeft(2, '0');
    colorHex = '#${(red + green + blue).toUpperCase()}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'provider': provider,
      'country': country,
      'date': date.toIso8601String(),
      'colorHex': colorHex,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: _normalizeLegacyValue(json['name'] as String? ?? 'Actividad sin nombre'),
      category: _normalizeLegacyValue(json['category'] as String? ?? 'Sin categoría'),
      provider: _normalizeLegacyValue(json['provider'] as String? ?? 'Sin proveedor'),
      country: _normalizeLegacyValue(json['country'] as String? ?? 'Sin país'),
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      colorHex: (json['colorHex'] as String?) ?? '#8B5CF6',
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String? ?? '')
                  ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Activity copyWith({
    String? name,
    String? category,
    String? provider,
    String? country,
    DateTime? date,
    String? colorHex,
    String? notes,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      provider: provider ?? this.provider,
      country: country ?? this.country,
      date: date ?? this.date,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

String _normalizeLegacyValue(String value) {
  var normalized = value;
  const replacements = {
    'Sin categoría': 'Sin categoría',
    'Sin categor�a': 'Sin categoría',
    'Sin país': 'Sin país',
    'Sin pa�s': 'Sin país',
    'categor�a': 'categoría',
    'Categor�a': 'Categoría',
    'categor�as': 'categorías',
    'Categor�as': 'Categorías',
    'pa�s': 'país',
    'Pa�s': 'País',
    'pa�ses': 'países',
    'Pa�ses': 'Países',
  };
  for (final entry in replacements.entries) {
    if (normalized.contains(entry.key)) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
  }
  return normalized;
}



