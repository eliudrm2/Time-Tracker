import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ErrorHandler {
  static final List<ErrorLog> _errorLogs = [];
  static const int _maxErrorLogs = 100;
  
  // Registrar error en memoria y persistencia
  static Future<void> logError(dynamic error, StackTrace? stack) async {
    try {
      final errorLog = ErrorLog(
        error: error.toString(),
        stackTrace: stack?.toString() ?? 'No stack trace',
        timestamp: DateTime.now(),
        deviceInfo: await _getDeviceContext(),
      );
      
      _errorLogs.add(errorLog);
      
      // Mantener solo los últimos 100 errores
      if (_errorLogs.length > _maxErrorLogs) {
        _errorLogs.removeAt(0);
      }
      
      // En modo debug, imprimir el error
      if (kDebugMode) {
        print('🔴 Error capturado: ${errorLog.error}');
        print('📍 Stack trace: ${errorLog.stackTrace}');
      }
      
      // Guardar en persistencia local
      await _saveErrorLogs();
      
      // En producción, aquí enviarías a Firebase Crashlytics
      // FirebaseCrashlytics.instance.recordError(error, stack);
      
    } catch (e) {
      // Si falla el registro de errores, al menos imprimirlo
      if (kDebugMode) {
        print('Error al registrar error: $e');
      }
    }
  }
  
  // Obtener contexto del dispositivo
  static Future<Map<String, dynamic>> _getDeviceContext() async {
    try {
      return {
        'platform': defaultTargetPlatform.toString(),
        'isDebug': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
        // Aquí podrías agregar más información del dispositivo
      };
    } catch (e) {
      return {'error': 'Could not get device context'};
    }
  }
  
  // Guardar logs en SharedPreferences
  static Future<void> _saveErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _errorLogs
          .map((log) => log.toJson())
          .toList()
          .take(50); // Solo guardar los últimos 50 en persistencia
      
      final jsonString = json.encode(logsJson.toList());
      await prefs.setString('error_logs', jsonString);
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar logs: $e');
      }
    }
  }
  
  // Cargar logs guardados
  static Future<List<ErrorLog>> loadErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('error_logs');
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => ErrorLog.fromJson(json))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al cargar logs: $e');
      }
    }
    return [];
  }
  
  // Limpiar todos los logs
  static Future<void> clearErrorLogs() async {
    _errorLogs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('error_logs');
  }
  
  // Obtener resumen de errores para debugging
  static Map<String, dynamic> getErrorSummary() {
    final errorTypes = <String, int>{};
    
    for (var log in _errorLogs) {
      final errorType = log.error.split(':').first;
      errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
    }
    
    return {
      'totalErrors': _errorLogs.length,
      'errorTypes': errorTypes,
      'lastError': _errorLogs.isNotEmpty ? _errorLogs.last.error : null,
      'lastErrorTime': _errorLogs.isNotEmpty 
          ? _errorLogs.last.timestamp.toIso8601String() 
          : null,
    };
  }
}

// Modelo para registro de errores
class ErrorLog {
  final String error;
  final String stackTrace;
  final DateTime timestamp;
  final Map<String, dynamic> deviceInfo;
  
  ErrorLog({
    required this.error,
    required this.stackTrace,
    required this.timestamp,
    required this.deviceInfo,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stackTrace': stackTrace.substring(0, stackTrace.length.clamp(0, 500)), // Limitar tamaño
      'timestamp': timestamp.toIso8601String(),
      'deviceInfo': deviceInfo,
    };
  }
  
  static ErrorLog fromJson(Map<String, dynamic> json) {
    return ErrorLog(
      error: json['error'] ?? 'Unknown error',
      stackTrace: json['stackTrace'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      deviceInfo: json['deviceInfo'] ?? {},
    );
  }
}

// Widget para mostrar errores en desarrollo
class ErrorLogViewer extends StatelessWidget {
  const ErrorLogViewer({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ErrorLog>>(
      future: ErrorHandler.loadErrorLogs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No hay errores registrados'),
          );
        }
        
        final logs = snapshot.data!;
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ExpansionTile(
              title: Text(
                log.error.split('\n').first,
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${log.timestamp.hour}:${log.timestamp.minute} - ${log.timestamp.day}/${log.timestamp.month}',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stack Trace:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        log.stackTrace,
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}