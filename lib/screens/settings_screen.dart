import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_handler.dart';
import '../utils/device_info_helper.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _autoBackup = true;
  // String _backupFrequency = 'daily'; // No usado actualmente
  Map<String, dynamic> _deviceInfo = {};
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceInfo();
  }
  
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = _prefs.getBool('notifications') ?? true;
      _darkModeEnabled = _prefs.getBool('darkMode') ?? true;
      _autoBackup = _prefs.getBool('autoBackup') ?? true;
      // _backupFrequency = _prefs.getString('backupFrequency') ?? 'daily';
    });
  }
  
  Future<void> _loadDeviceInfo() async {
    final info = await DeviceInfoHelper.getDeviceInfo();
    setState(() {
      _deviceInfo = info;
    });
  }
  
  Future<void> _saveSetting(String key, dynamic value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Preferencias
              _buildSectionTitle('Preferencias'),
              Card(
                color: const Color(0xFF262640),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Notificaciones'),
                      subtitle: const Text('Recibir alertas de tiempo'),
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _saveSetting('notifications', value);
                      },
                      activeThumbColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Modo Oscuro'),
                      subtitle: const Text('Tema oscuro para la aplicación'),
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                        _saveSetting('darkMode', value);
                      },
                      activeThumbColor: const Color(0xFF4A90E2),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Respaldo Automático'),
                      subtitle: const Text('Guardar datos automáticamente'),
                      value: _autoBackup,
                      onChanged: (value) {
                        setState(() {
                          _autoBackup = value;
                        });
                        _saveSetting('autoBackup', value);
                      },
                      activeThumbColor: const Color(0xFF4A90E2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Sección de Datos
              _buildSectionTitle('Gestión de Datos'),
              Card(
                color: const Color(0xFF262640),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                      title: const Text('Limpiar Caché'),
                      subtitle: const Text('Liberar espacio de almacenamiento'),
                      onTap: () async {
                        // Limpiar caché
                        await ErrorHandler.clearErrorLogs();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Caché limpiado exitosamente'),
                              backgroundColor: Color(0xFF50C878),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.backup, color: Colors.green),
                      title: const Text('Exportar Datos'),
                      subtitle: const Text('Crear copia de seguridad'),
                      onTap: () {
                        // Implementar exportación
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función disponible próximamente'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Eliminar Todos los Datos'),
                      subtitle: const Text('Eliminar permanentemente todos los registros'),
                      onTap: () {
                        _showDeleteAllDataDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Información del Dispositivo
              _buildSectionTitle('Información del Dispositivo'),
              Card(
                color: const Color(0xFF262640),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Tipo de dispositivo', 
                        _deviceInfo['deviceType']?.toString() ?? 'Desconocido'),
                      _buildInfoRow('Densidad de pantalla', 
                        _deviceInfo['screenDensity']?.toString() ?? 'Desconocido'),
                      _buildInfoRow('Resolución', 
                        '${_deviceInfo['screenWidth']?.toStringAsFixed(0) ?? '-'} x ${_deviceInfo['screenHeight']?.toStringAsFixed(0) ?? '-'}'),
                      if (_deviceInfo['operatingSystem'] != null)
                        _buildInfoRow('Sistema Operativo', 
                          _deviceInfo['operatingSystem'].toString()),
                      if (_deviceInfo['numberOfProcessors'] != null)
                        _buildInfoRow('Procesadores', 
                          _deviceInfo['numberOfProcessors'].toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Debugging (solo en modo debug)
              if (kDebugMode) ...[
                _buildSectionTitle('Herramientas de Desarrollo'),
                Card(
                  color: const Color(0xFF262640),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bug_report, color: Colors.amber),
                        title: const Text('Ver Logs de Errores'),
                        subtitle: Text(
                          'Errores capturados: ${ErrorHandler.getErrorSummary()['totalErrors']}',
                        ),
                        onTap: () {
                          _showErrorLogsDialog();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.phone_android, color: Colors.blue),
                        title: const Text('Verificar Compatibilidad'),
                        onTap: () async {
                          final check = await DeviceInfoHelper.checkCompatibility();
                          if (mounted) {
                            _showCompatibilityDialog(check);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Acerca de
              _buildSectionTitle('Acerca de'),
              Card(
                color: const Color(0xFF262640),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF50C878)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.timer, color: Colors.white),
                      ),
                      title: const Text(
                        'Time Tracker',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Versión 1.0.0'),
                          SizedBox(height: 4),
                          Text(
                            'Desarrollado por NavShock Studio',
                            style: TextStyle(
                              color: Color(0xFF4A90E2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.policy, color: Colors.grey),
                      title: const Text('Política de Privacidad'),
                      onTap: () {
                        // Abrir política de privacidad
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description, color: Colors.grey),
                      title: const Text('Términos y Condiciones'),
                      onTap: () {
                        // Abrir términos
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Footer con branding
              Center(
                child: Column(
                  children: [
                    Text(
                      '© 2025 NavShock Studio',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Innovación Digital',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[400]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262640),
        title: const Text('⚠️ Advertencia'),
        content: const Text(
          'Esta acción eliminará permanentemente todos tus registros de tiempo. '
          'Esta acción no se puede deshacer.\n\n'
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              // Eliminar todos los datos
              await _prefs.clear();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos los datos han sido eliminados'),
                    backgroundColor: Colors.red,
                  ),
                );
                // Volver a la pantalla principal
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );
  }
  
  void _showErrorLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF262640),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Registro de Errores',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: ErrorLogViewer(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCompatibilityDialog(CompatibilityCheck check) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262640),
        title: Text(
          check.isCompatible ? '✅ Dispositivo Compatible' : '⚠️ Problemas de Compatibilidad',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (check.issues.isNotEmpty) ...[
                const Text(
                  'Problemas encontrados:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                ...check.issues.map((issue) => Text('• $issue')),
                const SizedBox(height: 12),
              ],
              if (check.warnings.isNotEmpty) ...[
                const Text(
                  'Advertencias:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                ...check.warnings.map((warning) => Text('• $warning')),
              ],
              if (check.isCompatible && check.warnings.isEmpty)
                const Text('Tu dispositivo es completamente compatible con la aplicación.'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}