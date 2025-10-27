import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../services/storage_service.dart';
import '../services/import_export_service.dart';
import '../providers/activity_provider.dart';
import 'package:provider/provider.dart';
import 'add_activity_screen.dart';
import 'activities_list_screen.dart';
import 'network_map_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = const [
    ActivitiesListScreen(),
    NetworkMapScreen(),
    StatisticsScreen(),
  ];
  
  final List<String> _titles = const [
    'Registro de Actividades',
    'Mapa de Actividades',
    'Estadísticas y Análisis',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: AppTheme.primaryPurple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Time Tracker',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        _showSettingsDialog();
                      },
                    ),
                  ],
                ),
              ),
              
              // Screen Content
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.cardDark.withValues(alpha: 0.95),
              AppTheme.backgroundDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryPurple,
          unselectedItemColor: Colors.white.withValues(alpha: 0.5),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.listCheck),
              activeIcon: Icon(FontAwesomeIcons.listCheck, size: 22),
              label: 'Registro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.scatter_plot),
              activeIcon: Icon(Icons.scatter_plot, size: 26),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.chartLine),
              activeIcon: Icon(FontAwesomeIcons.chartLine, size: 22),
              label: 'Estadísticas',
            ),
          ],
        ),
      ),
      
      // Floating Action Button (only visible on Activities List)
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddActivityScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    setState(() {});
                  }
                });
              },
              backgroundColor: AppTheme.primaryPurple,
              elevation: 8,
              child: const Icon(
                Icons.add,
                size: 28,
              ),
            )
          : null,
    );
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.settings,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              const Text(
                'Configuración',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Exportar datos
              ListTile(
                leading: const Icon(
                  Icons.upload_file,
                  color: Colors.green,
                ),
                title: const Text(
                  'Exportar Datos',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Exportar todas las actividades a JSON',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final success = await ImportExportService.exportAndShare(context);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Datos exportados exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              
              // Importar datos
              ListTile(
                leading: const Icon(
                  Icons.download,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Importar Datos',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Importar actividades desde archivo JSON',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ImportExportService.importFromFile(context);
                  // Recargar datos después de importar
                  if (mounted) {
                    context.read<ActivityProvider>().loadActivities();
                    setState(() {});
                  }
                },
              ),
              
              // Ver backups
              ListTile(
                leading: const Icon(
                  Icons.backup,
                  color: AppTheme.lightPurple,
                ),
                title: const Text(
                  'Backups Automáticos',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Ver y restaurar backups locales',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showBackupsDialog();
                },
              ),
              
              const Divider(color: Colors.white24),
              
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppTheme.lightPurple,
                ),
                title: const Text(
                  'Acerca de',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Time Tracker v1.0.1',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog();
                },
              ),
              
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                ),
                title: const Text(
                  'Borrar todos los datos',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Esta acción no se puede deshacer',
                  style: TextStyle(
                    color: Colors.red.withValues(alpha: 0.6),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmClearAllData();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
  
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Time Tracker',
      applicationVersion: '1.0.1',
      applicationIcon: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryPurple,
            width: 2,
          ),
        ),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
      children: [
        const Text(
          'Time Tracker es una aplicación elegante para registrar y visualizar '
          'actividades a lo largo del tiempo.\n\n'
          'Permite llevar un seguimiento detallado de cuándo realizas cada actividad, '
          'calcular intervalos entre repeticiones y visualizar patrones de comportamiento.',
        ),
      ],
    );
  }
  
  void _showBackupsDialog() async {
    final backups = await ImportExportService.getBackupsList();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.backup,
                color: AppTheme.primaryPurple,
              ),
              const SizedBox(width: 12),
              const Text(
                'Backups Automáticos',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: backups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.backup_outlined,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay backups disponibles',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: backups.length,
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      return Card(
                        color: AppTheme.surfaceDark,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.backup,
                            color: AppTheme.lightPurple,
                          ),
                          title: Text(
                            backup.fileName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${backup.sizeFormatted} • ${DateFormat('dd/MM/yyyy HH:mm').format(backup.date)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.restore,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final result = await ImportExportService.restoreFromBackup(backup.filePath);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.success 
                                            ? '✅ Backup restaurado exitosamente'
                                            : '❌ Error al restaurar backup',
                                        ),
                                        backgroundColor: result.success ? Colors.green : Colors.red,
                                      ),
                                    );
                                    if (result.success) {
                                      context.read<ActivityProvider>().loadActivities();
                                      setState(() {});
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  await Share.shareXFiles(
                                    [XFile(backup.filePath)],
                                    subject: 'Time Tracker Backup',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final success = await ImportExportService.createAutoBackup();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                          ? '✅ Backup creado exitosamente'
                          : '❌ Error al crear backup',
                      ),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                  if (success) {
                    _showBackupsDialog();
                  }
                }
              },
              child: const Text('Crear Backup'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }
  
  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: const Text(
            '⚠️ Confirmar eliminación',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Estás seguro de que deseas eliminar TODOS los datos? '
            'Esta acción no se puede deshacer y perderás todas las actividades registradas.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await StorageService.clearAllData();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Todos los datos han sido eliminados'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar todo'),
            ),
          ],
        );
      },
    );
  }
}
