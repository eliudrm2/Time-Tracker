import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class DeviceInfoHelper {
  // Cache de información del dispositivo
  static Map<String, dynamic>? _cachedDeviceInfo;
  
  // Obtener información del dispositivo
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }
    
    try {
      final info = <String, dynamic>{};
      
      // Información básica de la plataforma
      if (!kIsWeb) {
        info['isAndroid'] = Platform.isAndroid;
        info['isIOS'] = Platform.isIOS;
        info['operatingSystem'] = Platform.operatingSystem;
        info['operatingSystemVersion'] = Platform.operatingSystemVersion;
        info['numberOfProcessors'] = Platform.numberOfProcessors;
        info['localHostname'] = Platform.localHostname;
      } else {
        info['isWeb'] = true;
        info['userAgent'] = 'Web Browser';
      }
      
      // Información de pantalla y densidad
      info['devicePixelRatio'] = PlatformDispatcher.instance.views.first.devicePixelRatio;
      info['screenWidth'] = PlatformDispatcher.instance.views.first.physicalSize.width;
      info['screenHeight'] = PlatformDispatcher.instance.views.first.physicalSize.height;
      
      // Clasificar el dispositivo por tamaño
      final screenSize = _getScreenSize(info['screenWidth'], info['screenHeight'], info['devicePixelRatio']);
      info['deviceType'] = screenSize;
      
      // Determinar la densidad de pantalla
      info['screenDensity'] = _getScreenDensity(info['devicePixelRatio']);
      
      // Guardar en caché
      _cachedDeviceInfo = info;
      
      return info;
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo información del dispositivo: $e');
      }
      return {
        'error': 'Could not get device info',
        'deviceType': 'unknown',
      };
    }
  }
  
  // Clasificar tamaño de pantalla
  static String _getScreenSize(double width, double height, double pixelRatio) {
    final logicalWidth = width / pixelRatio;
    final logicalHeight = height / pixelRatio;
    final diagonal = (logicalWidth * logicalWidth + logicalHeight * logicalHeight);
    
    if (diagonal < 500000) {
      return 'small'; // Teléfonos pequeños
    } else if (diagonal < 900000) {
      return 'normal'; // Teléfonos normales
    } else if (diagonal < 1500000) {
      return 'large'; // Teléfonos grandes o tablets pequeñas
    } else {
      return 'xlarge'; // Tablets
    }
  }
  
  // Obtener densidad de pantalla
  static String _getScreenDensity(double devicePixelRatio) {
    if (devicePixelRatio <= 1.0) {
      return 'mdpi'; // ~160dpi
    } else if (devicePixelRatio <= 1.5) {
      return 'hdpi'; // ~240dpi
    } else if (devicePixelRatio <= 2.0) {
      return 'xhdpi'; // ~320dpi
    } else if (devicePixelRatio <= 3.0) {
      return 'xxhdpi'; // ~480dpi
    } else {
      return 'xxxhdpi'; // ~640dpi
    }
  }
  
  // Verificar si el dispositivo es de gama baja
  static Future<bool> isLowEndDevice() async {
    final info = await getDeviceInfo();
    
    // Verificar por número de procesadores y RAM disponible
    if (info['numberOfProcessors'] != null && info['numberOfProcessors'] < 4) {
      return true;
    }
    
    // En web, asumir que no es de gama baja
    if (info['isWeb'] == true) {
      return false;
    }
    
    return false;
  }
  
  // Obtener configuración recomendada para el dispositivo
  static Future<DeviceConfiguration> getRecommendedConfiguration() async {
    final info = await getDeviceInfo();
    final isLowEnd = await isLowEndDevice();
    
    if (isLowEnd) {
      return DeviceConfiguration(
        enableAnimations: false,
        enableShadows: false,
        enableBlur: false,
        imageQuality: ImageQuality.low,
        maxCacheSize: 50,
      );
    }
    
    final deviceType = info['deviceType'] ?? 'normal';
    
    switch (deviceType) {
      case 'small':
      case 'normal':
        return DeviceConfiguration(
          enableAnimations: true,
          enableShadows: true,
          enableBlur: true,
          imageQuality: ImageQuality.medium,
          maxCacheSize: 100,
        );
        
      case 'large':
      case 'xlarge':
        return DeviceConfiguration(
          enableAnimations: true,
          enableShadows: true,
          enableBlur: true,
          imageQuality: ImageQuality.high,
          maxCacheSize: 200,
        );
        
      default:
        return DeviceConfiguration(
          enableAnimations: true,
          enableShadows: true,
          enableBlur: false,
          imageQuality: ImageQuality.medium,
          maxCacheSize: 100,
        );
    }
  }
  
  // Verificar compatibilidad específica
  static Future<CompatibilityCheck> checkCompatibility() async {
    final info = await getDeviceInfo();
    final issues = <String>[];
    final warnings = <String>[];
    
    // Verificar versión de Android
    if (info['isAndroid'] == true) {
      final version = info['operatingSystemVersion'] ?? '';
      
      // Extraer versión de Android
      final versionMatch = RegExp(r'(\d+)').firstMatch(version);
      if (versionMatch != null) {
        final androidVersion = int.tryParse(versionMatch.group(1) ?? '0') ?? 0;
        
        if (androidVersion < 5) {
          issues.add('Android version too old. Minimum required: 5.0 (API 21)');
        } else if (androidVersion < 7) {
          warnings.add('Some features may not work on Android < 7.0');
        }
      }
    }
    
    // Verificar espacio en pantalla
    final deviceType = info['deviceType'];
    if (deviceType == 'small') {
      warnings.add('Small screen detected. UI may be cramped.');
    }
    
    // Verificar densidad de pantalla
    final density = info['screenDensity'];
    if (density == 'mdpi' || density == 'hdpi') {
      warnings.add('Low screen density. Images may appear pixelated.');
    }
    
    return CompatibilityCheck(
      isCompatible: issues.isEmpty,
      issues: issues,
      warnings: warnings,
      deviceInfo: info,
    );
  }
}

// Configuración recomendada para el dispositivo
class DeviceConfiguration {
  final bool enableAnimations;
  final bool enableShadows;
  final bool enableBlur;
  final ImageQuality imageQuality;
  final int maxCacheSize;
  
  DeviceConfiguration({
    required this.enableAnimations,
    required this.enableShadows,
    required this.enableBlur,
    required this.imageQuality,
    required this.maxCacheSize,
  });
}

// Calidad de imagen
enum ImageQuality {
  low,
  medium,
  high,
}

// Resultado de verificación de compatibilidad
class CompatibilityCheck {
  final bool isCompatible;
  final List<String> issues;
  final List<String> warnings;
  final Map<String, dynamic> deviceInfo;
  
  CompatibilityCheck({
    required this.isCompatible,
    required this.issues,
    required this.warnings,
    required this.deviceInfo,
  });
}