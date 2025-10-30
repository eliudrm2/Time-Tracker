import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../utils/theme.dart';
import '../l10n/app_localizations.dart';
import 'add_activity_screen.dart';

class ActivitiesListScreen extends StatefulWidget {
  const ActivitiesListScreen({Key? key}) : super(key: key);

  @override
  State<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends State<ActivitiesListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedProvider;
  String? _selectedCountry;
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatInterval(Duration duration, BuildContext context) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    
    if (days > 0) {
      final dayWord = context.loc('common.days', fallback: 'días');
      final hourWord = context.loc('common.hours', fallback: 'horas');
      return '$days $dayWord $hours $hourWord';
    } else {
      final hourWord = context.loc('common.hours', fallback: 'horas');
      return '$hours $hourWord';
    }
  }

  String _getTimeSince(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return context.loc('activities.timeSince.days',
          fallback: 'hace {days} días',
          args: {'days': difference.inDays.toString()});
    } else if (difference.inHours > 0) {
      return context.loc('activities.timeSince.hours',
          fallback: 'hace {hours} horas',
          args: {'hours': difference.inHours.toString()});
    } else if (difference.inMinutes > 0) {
      return context.loc('activities.timeSince.minutes',
          fallback: 'hace {minutes} minutos',
          args: {'minutes': difference.inMinutes.toString()});
    } else {
      return context.loc('activities.timeSince.moment',
          fallback: 'hace un momento');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    
    final filteredActivities = provider.getFilteredActivities(
      category: _selectedCategory,
      provider: _selectedProvider,
      country: _selectedCountry,
      searchQuery: _searchController.text,
    );

    // Group activities by name for interval calculation
    final Map<String, List<Activity>> activityGroups = {};
    for (var activity in provider.activities) {
      final key = activity.name.toLowerCase();
      activityGroups[key] ??= [];
      activityGroups[key]!.add(activity);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          FontAwesomeIcons.listCheck,
                          color: AppTheme.primaryPurple,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.loc('activities.header',
                              fallback: 'Registro de Actividades'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _showFilters 
                                ? Icons.filter_alt 
                                : Icons.filter_alt_outlined,
                            color: AppTheme.primaryPurple,
                          ),
                          onPressed: () {
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: context.loc('activities.search.hint',
                            fallback: 'Buscar actividad...'),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppTheme.lightPurple,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceDark.withValues(alpha: 0.5),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    
                    // Filters
                    if (_showFilters) ...[
                      const SizedBox(height: 12),
                      FadeInDown(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          children: [
                            // Category Filter
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: context.loc('activities.filter.category',
                                    fallback: 'Categoría'),
                                prefixIcon: const Icon(Icons.category),
                              ),
                              dropdownColor: AppTheme.surfaceDark,
                              style: const TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(context.loc('activities.filter.allCategories',
                                      fallback: 'Todas las categorías')),
                                ),
                                ...provider.categories.map((cat) => 
                                  DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Provider Filter
                            DropdownButtonFormField<String>(
                              value: _selectedProvider,
                              decoration: InputDecoration(
                                labelText: context.loc('activities.filter.provider',
                                    fallback: 'Proveedor'),
                                prefixIcon: const Icon(Icons.business),
                              ),
                              dropdownColor: AppTheme.surfaceDark,
                              style: const TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(context.loc('activities.filter.allProviders',
                                      fallback: 'Todos los proveedores')),
                                ),
                                ...provider.providers.map((prov) => 
                                  DropdownMenuItem(
                                    value: prov,
                                    child: Text(prov),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedProvider = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Country Filter  
                            DropdownButtonFormField<String>(
                              value: _selectedCountry,
                              decoration: InputDecoration(
                                labelText: context.loc('activities.filter.country',
                                    fallback: 'País'),
                                prefixIcon: const Icon(Icons.public),
                              ),
                              dropdownColor: AppTheme.surfaceDark,
                              style: const TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(context.loc('activities.filter.allCountries',
                                      fallback: 'Todos los países')),
                                ),
                                ...provider.countries.map((country) => 
                                  DropdownMenuItem(
                                    value: country,
                                    child: Text(country),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountry = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Update Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      provider.loadActivities();
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(context.loc('common.refresh', fallback: 'Actualizar')),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Activities List
              Expanded(
                child: filteredActivities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.loc('activities.empty.title',
                                  fallback: 'No hay actividades registradas'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredActivities.length,
                        itemBuilder: (context, index) {
                          final activity = filteredActivities[index];
                          final activityList = activityGroups[activity.name.toLowerCase()] ?? [];
                          final activityIndex = activityList.indexWhere((a) => a.id == activity.id);
                          
                          // Calculate interval
                          Duration? interval;
                          String? previousDateText;
                          bool isFirstRecord = activityIndex == activityList.length - 1;
                          
                          if (activityIndex < activityList.length - 1 && activityIndex >= 0) {
                            final previousActivity = activityList[activityIndex + 1];
                            interval = activity.date.difference(previousActivity.date);
                            previousDateText = DateFormat('dd/MM/yyyy HH:mm').format(previousActivity.date);
                          }
                          
                          // Calculate average interval
                          final intervals = provider.getActivityIntervals(activity.name);
                          final averageInterval = intervals['average'];
                          
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 50)),
                            child: _buildActivityCard(
                              activity: activity,
                              interval: interval,
                              previousDateText: previousDateText,
                              averageInterval: averageInterval,
                              isFirstRecord: isFirstRecord,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddActivityScreen(),
            ),
          );
          
          if (result == true) {
            setState(() {});
          }
        },
        backgroundColor: AppTheme.primaryPurple,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildActivityCard({
    required Activity activity,
    Duration? interval,
    String? previousDateText,
    Duration? averageInterval,
    required bool isFirstRecord,
  }) {
    final isRecent = DateTime.now().difference(activity.date).inHours < 24;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddActivityScreen(activityToEdit: activity),
              ),
            );
            
            if (result == true) {
              setState(() {});
            }
          },
          onLongPress: () {
            _showActivityOptions(activity);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppTheme.lightPurple,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(activity.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: activity.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: activity.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm').format(activity.date),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Activity name with color indicator
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: activity.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                activity.category,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isRecent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          context.loc('common.recent', fallback: 'Reciente'),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Provider and Country
                if (activity.provider != 'Sin proveedor' || 
                    activity.country != 'Sin país') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (activity.provider != 'Sin proveedor') ...[
                        Icon(
                          Icons.business,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.provider,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (activity.country != 'Sin país') ...[
                        Icon(
                          Icons.public,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.country,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                
                // Interval Information
                if (!isFirstRecord && interval != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 16,
                              color: AppTheme.primaryPurple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${context.loc("activities.interval.label", fallback: "Intervalo")}: ${_formatInterval(interval, context)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${context.loc("activities.interval.from", fallback: "Desde")}: $previousDateText',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        if (averageInterval != null && averageInterval.inSeconds > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${context.loc("activities.interval.avgLabel", fallback: "Promedio")}: ${_formatInterval(averageInterval, context)}',
                            style: TextStyle(
                              color: AppTheme.lightPurple.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (isFirstRecord) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_new,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.loc('activities.firstRecord',
                              fallback: 'Primer registro de "{name}"',
                              args: {'name': activity.name}),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Notes
                if (activity.notes != null && activity.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activity.notes!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Time since
                const SizedBox(height: 12),
                Text(
                  _getTimeSince(activity.date, context),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityOptions(Activity activity) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: Text(context.loc('activities.menu.edit', fallback: 'Editar'),
                    style: const TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddActivityScreen(activityToEdit: activity),
                    ),
                  );
                  if (result == true) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(context.loc('activities.menu.delete', fallback: 'Eliminar'),
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(activity);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Activity activity) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          title: Text(context.loc('activities.dialog.delete.title',
              fallback: 'Confirmar eliminación')),
          content: Text(
            context.loc('activities.dialog.delete.message',
                fallback: '¿Estás seguro de que deseas eliminar "{name}"?',
                args: {'name': activity.name}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.loc('activities.dialog.delete.cancel',
                  fallback: 'Cancelar')),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<ActivityProvider>().deleteActivity(activity.id);
                Navigator.pop(context);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(context.loc('activities.dialog.delete.confirm',
                  fallback: 'Eliminar')),
            ),
          ],
        );
      },
    );
  }
}