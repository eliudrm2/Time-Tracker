import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import 'storage_service.dart';

class BackupInfo {
  final String fileName;
  final String filePath;
  final DateTime date;
  final int size;

  BackupInfo({
    required this.fileName,
    required this.filePath,
    required this.date,
    required this.size,
  });

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class RestoreResult {
  final bool success;
  final String? message;

  RestoreResult({required this.success, this.message});
}

class ImportExportService {
  static const String backupsFolder = 'backups';
  static const int maxBackups = 10;

  /// Export all activities to JSON and share
  static Future<bool> exportAndShare(BuildContext context) async {
    try {
      // Get all activities
      final activities = StorageService.getAllActivities();
      
      // Convert to JSON
      final exportData = {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'totalActivities': activities.length,
        'activities': activities.map((a) => a.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Create temp file
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'time_tracker_export_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Time Tracker - Exportación de datos',
        text: 'Exportación de ${activities.length} actividades',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error exportando datos: $e');
      return false;
    }
  }

  /// Import activities from JSON file
  static Future<void> importFromFile(BuildContext context) async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        _showError(context, 'No se pudo acceder al archivo');
        return;
      }

      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate format
      if (!data.containsKey('activities')) {
        _showError(context, 'Formato de archivo inválido');
        return;
      }

      // Confirm import
      final confirmed = await _showConfirmDialog(
        context,
        'Confirmar Importación',
        '¿Deseas importar ${data['totalActivities']} actividades?\n\n'
        'Las actividades existentes se mantendrán.',
      );

      if (!confirmed) return;

      // Import activities
      final activitiesList = data['activities'] as List;
      int imported = 0;

      for (var activityJson in activitiesList) {
        try {
          final activity = Activity.fromJson(activityJson as Map<String, dynamic>);
          await StorageService.saveActivity(activity);
          imported++;
        } catch (e) {
          debugPrint('Error importando actividad: $e');
        }
      }

      if (context.mounted) {
        _showSuccess(context, '✅ Se importaron $imported actividades exitosamente');
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Error al importar: ${e.toString()}');
      }
    }
  }

  /// Get list of automatic backups
  static Future<List<BackupInfo>> getBackupsList() async {
    try {
      final directory = await _getBackupsDirectory();
      
      if (!await directory.exists()) {
        return [];
      }

      final files = directory.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      final backups = <BackupInfo>[];
      for (var file in files) {
        final stat = await file.stat();
        backups.add(BackupInfo(
          fileName: file.path.split(Platform.pathSeparator).last,
          filePath: file.path,
          date: stat.modified,
          size: stat.size,
        ));
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b.date.compareTo(a.date));

      return backups;
    } catch (e) {
      debugPrint('Error obteniendo lista de backups: $e');
      return [];
    }
  }

  /// Restore from a backup file
  static Future<RestoreResult> restoreFromBackup(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return RestoreResult(
          success: false,
          message: 'El archivo de backup no existe',
        );
      }

      // Read and parse
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      if (!data.containsKey('activities')) {
        return RestoreResult(
          success: false,
          message: 'Formato de backup inválido',
        );
      }

      // Clear current data
      await StorageService.clearAllData();

      // Restore activities
      final activitiesList = data['activities'] as List;
      int restored = 0;

      for (var activityJson in activitiesList) {
        try {
          final activity = Activity.fromJson(activityJson as Map<String, dynamic>);
          await StorageService.saveActivity(activity);
          restored++;
        } catch (e) {
          debugPrint('Error restaurando actividad: $e');
        }
      }

      return RestoreResult(
        success: true,
        message: 'Se restauraron $restored actividades',
      );
    } catch (e) {
      return RestoreResult(
        success: false,
        message: 'Error al restaurar: ${e.toString()}',
      );
    }
  }

  /// Create automatic backup
  static Future<bool> createAutoBackup() async {
    try {
      final activities = StorageService.getAllActivities();
      
      if (activities.isEmpty) {
        return false;
      }

      // Create backup data
      final backupData = {
        'version': '1.0.0',
        'backupDate': DateTime.now().toIso8601String(),
        'totalActivities': activities.length,
        'activities': activities.map((a) => a.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to backups directory
      final directory = await _getBackupsDirectory();
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);

      // Clean old backups (keep only maxBackups)
      await _cleanOldBackups();

      return true;
    } catch (e) {
      debugPrint('Error creando backup automático: $e');
      return false;
    }
  }

  /// Get backups directory
  static Future<Directory> _getBackupsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$backupsFolder');
  }

  /// Clean old backups, keeping only the most recent ones
  static Future<void> _cleanOldBackups() async {
    try {
      final backups = await getBackupsList();
      
      if (backups.length > maxBackups) {
        // Delete oldest backups
        for (int i = maxBackups; i < backups.length; i++) {
          final file = File(backups[i].filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error limpiando backups antiguos: $e');
    }
  }

  // Helper methods for UI
  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ?? false;
  }
}
