import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../utils/theme.dart';
import '../services/storage_service.dart';
import '../services/import_export_service.dart';
import '../providers/activity_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
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
              _buildHeader(context),
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
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryPurple,
              elevation: 8,
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddActivityScreen(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
          Text(
            context.loc('home.header.subtitle', fallback: 'Time Tracker'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
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
          setState(() => _selectedIndex = index);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryPurple,
        unselectedItemColor: Colors.white.withValues(alpha: 0.5),
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(FontAwesomeIcons.listCheck),
            activeIcon: const Icon(FontAwesomeIcons.listCheck, size: 22),
            label: context.loc('nav.log', fallback: 'Registro'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.scatter_plot),
            activeIcon: const Icon(Icons.scatter_plot, size: 26),
            label: context.loc('nav.map', fallback: 'Mapa'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(FontAwesomeIcons.chartLine),
            activeIcon: const Icon(FontAwesomeIcons.chartLine, size: 22),
            label: context.loc('nav.stats', fallback: 'Estadísticas'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final localeProvider = context.read<LocaleProvider>();
    final activityProvider = context.read<ActivityProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        Locale selectedLocale = localeProvider.locale;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.settings, color: AppTheme.primaryPurple),
                  const SizedBox(width: 12),
                  Text(
                    dialogContext.loc(
                      'home.settings.title',
                      fallback: 'Configuración',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageSelector(
                      dialogContext,
                      selectedLocale,
                      onChanged: (locale) async {
                        if (locale == null) return;
                        setDialogState(() => selectedLocale = locale);
                        await localeProvider.setLocale(locale);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsTile(
                      icon: Icons.ios_share,
                      title: context.loc(
                        'home.settings.export',
                        fallback: 'Exportar Datos',
                      ),
                      subtitle: context.loc(
                        'home.settings.export.subtitle',
                        fallback: 'Exportar todas las actividades a JSON',
                      ),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        final success =
                            await ImportExportService.exportAndShare(context);
                        _showSnackBar(
                          success
                              ? context.loc(
                                  'home.dialog.export.success',
                                  fallback:
                                      '¡Listo! Datos exportados exitosamente',
                                )
                              : context.loc(
                                  'home.dialog.export.error',
                                  fallback:
                                      'Hubo un problema al exportar los datos',
                                ),
                          success: success,
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.file_open,
                      title: context.loc(
                        'home.settings.import',
                        fallback: 'Importar Datos',
                      ),
                      subtitle: context.loc(
                        'home.settings.import.subtitle',
                        fallback: 'Importar actividades desde archivo JSON',
                      ),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        final before = activityProvider.activities.length;
                        await ImportExportService.importFromFile(context);
                        final after = activityProvider.activities.length;
                        if (!mounted) return;
                        final imported = after - before;
                        if (imported > 0) {
                          _showSnackBar(
                            context.loc(
                              'home.dialog.import.success',
                              fallback:
                                  '¡Listo! Se importaron {count} actividades exitosamente',
                              args: {'count': imported.toString()},
                            ),
                            success: true,
                          );
                          setState(() {});
                        }
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.backup,
                      title: context.loc(
                        'home.settings.backups',
                        fallback: 'Backups Automáticos',
                      ),
                      subtitle: context.loc(
                        'home.settings.backups.subtitle',
                        fallback: 'Ver y restaurar backups locales',
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showBackupsDialog();
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.info_outline,
                      title: context.loc(
                        'home.settings.about',
                        fallback: 'Acerca de',
                      ),
                      subtitle: context.loc(
                        'home.settings.about.subtitle',
                        fallback:
                            'Time Tracker es una aplicación elegante para registrar y visualizar actividades a lo largo del tiempo.',
                      ),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _showAboutDialog();
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.delete_forever,
                      title: context.loc(
                        'home.settings.delete',
                        fallback: 'Borrar todos los datos',
                      ),
                      subtitle: context.loc(
                        'home.settings.delete.subtitle',
                        fallback: 'Esta acción no se puede deshacer',
                      ),
                      iconColor: Colors.red,
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _confirmClearAllData();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    dialogContext.loc('home.settings.close',
                        fallback: 'Cerrar'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    Locale selectedLocale, {
    required ValueChanged<Locale?> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language, color: AppTheme.lightPurple),
      title: Text(
        context.loc('home.settings.language', fallback: 'Idioma'),
        style: const TextStyle(color: Colors.white),
      ),
      trailing: DropdownButton<Locale>(
        value: selectedLocale,
        dropdownColor: AppTheme.cardDark,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: Colors.white),
        onChanged: onChanged,
        items: LocaleProvider.supportedLocales.map((locale) {
          final label = locale.languageCode == 'es'
              ? context.loc(
                  'home.settings.language.es',
                  fallback: 'Español',
                )
              : context.loc(
                  'home.settings.language.en',
                  fallback: 'Inglés',
                );
          return DropdownMenuItem(
            value: locale,
            child: Text(label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = AppTheme.lightPurple,
  }) {
    return Card(
      color: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showBackupsDialog() async {
    final backups = await ImportExportService.getBackupsList();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final dateLocale = Localizations.localeOf(dialogContext).toString();
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.backup, color: AppTheme.primaryPurple),
              const SizedBox(width: 12),
              Text(
                dialogContext.loc(
                  'home.settings.backups',
                  fallback: 'Backups Automáticos',
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: backups.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.backup_outlined,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        dialogContext.loc(
                          'home.dialog.backup.empty',
                          fallback: 'No hay backups disponibles',
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final backup = backups[index];
                      final formattedDate = DateFormat.yMd(dateLocale)
                          .add_Hm()
                          .format(backup.date);
                      return Card(
                        color: AppTheme.surfaceDark,
                        child: ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file,
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
                            context.loc(
                              'home.dialog.backup.date',
                              fallback:
                                  '${backup.sizeFormatted} • $formattedDate',
                              args: {
                                'size': backup.sizeFormatted,
                                'date': formattedDate,
                              },
                            ),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.restore,
                                    color: Colors.green),
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  final result = await ImportExportService
                                      .restoreFromBackup(
                                    backup.filePath,
                                  );
                                  if (!mounted) return;
                                  _showSnackBar(
                                    result.success
                                        ? context.loc(
                                            'home.dialog.backup.restore.success',
                                            fallback:
                                                '¡Listo! Backup restaurado exitosamente',
                                          )
                                        : context.loc(
                                            'home.dialog.backup.restore.error',
                                            fallback:
                                                'Hubo un problema al restaurar el backup',
                                          ),
                                    success: result.success,
                                  );
                                  if (result.success) {
                                    await context
                                        .read<ActivityProvider>()
                                        .loadActivities();
                                    setState(() {});
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.share, color: Colors.blue),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                dialogContext.loc('common.close', fallback: 'Cerrar'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: context.loc('app.title', fallback: 'Time Tracker'),
      applicationVersion: '1.0.1',
      applicationIcon: Container(
        width: 60,
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryPurple, width: 2),
        ),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
      children: [
        Text(
          context.loc(
            'home.settings.about.subtitle',
            fallback:
                'Time Tracker es una aplicación elegante para registrar y visualizar actividades a lo largo del tiempo.',
          ),
        ),
      ],
    );
  }

  void _confirmClearAllData() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text(
            dialogContext.loc(
              'home.dialog.delete.title',
              fallback: '⚠️ Confirmar eliminación',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            dialogContext.loc(
              'home.dialog.delete.message',
              fallback:
                  '¿Estás seguro de que deseas eliminar TODOS los datos? Esta acción no se puede deshacer y perderás todas las actividades registradas.',
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                dialogContext.loc('common.cancel', fallback: 'Cancelar'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                await StorageService.clearAllData();
                if (!mounted) return;
                Navigator.pop(dialogContext);
                _showSnackBar(
                  dialogContext.loc(
                    'home.dialog.delete.success',
                    fallback: 'Todos los datos han sido eliminados',
                  ),
                  success: false,
                );
                setState(() {});
              },
              child: Text(
                dialogContext.loc('activities.dialog.delete.confirm',
                    fallback: 'Eliminar'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }
}
