import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:graphview/GraphView.dart';
import 'dart:math' as math;
import '../providers/activity_provider.dart';
import '../utils/theme.dart';
import '../models/activity.dart';
import '../l10n/app_localizations.dart';

class NetworkMapScreen extends StatefulWidget {
  const NetworkMapScreen({Key? key}) : super(key: key);

  @override
  State<NetworkMapScreen> createState() => _NetworkMapScreenState();
}

class _NetworkMapScreenState extends State<NetworkMapScreen> 
    with SingleTickerProviderStateMixin {
  
  bool _isTemporalView = true;
  final Graph _graph = Graph();
  SugiyamaConfiguration _builder = SugiyamaConfiguration();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_animationController);
    
    _builder
      ..nodeSeparation = 50
      ..levelSeparation = 50
      ..orientation = SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
    
    _buildGraph();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _buildGraph() {
    _graph.nodes.clear();
    _graph.edges.clear();
    
    final provider = context.read<ActivityProvider>();
    final activities = provider.activities;
    
    if (activities.isEmpty) return;
    
    if (_isTemporalView) {
      _buildTemporalGraph(activities);
    } else {
      _buildCategoryGraph(activities);
    }
  }

  void _buildTemporalGraph(List<Activity> activities) {
    // Sort activities by date
    final sortedActivities = List<Activity>.from(activities)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Create nodes for each unique activity name
    final Map<String, Node> activityNodes = {};
    final Map<String, List<Activity>> activityGroups = {};
    
    for (var activity in sortedActivities) {
      final key = activity.name.toLowerCase();
      
      if (!activityNodes.containsKey(key)) {
        final node = Node.Id(key);
        activityNodes[key] = node;
        _graph.addNode(node);
      }
      
      activityGroups[key] ??= [];
      activityGroups[key]!.add(activity);
    }
    
    // Create edges based on temporal relationships
    final processedPairs = <String>{};
    
    for (var i = 0; i < sortedActivities.length - 1; i++) {
      final current = sortedActivities[i];
      final next = sortedActivities[i + 1];
      
      final currentKey = current.name.toLowerCase();
      final nextKey = next.name.toLowerCase();
      
      if (currentKey != nextKey) {
        final pairKey = '$currentKey-$nextKey';
        
        if (!processedPairs.contains(pairKey)) {
          processedPairs.add(pairKey);
          
          _graph.addEdge(
            activityNodes[currentKey]!,
            activityNodes[nextKey]!,
          );
        }
      }
    }
  }

  void _buildCategoryGraph(List<Activity> activities) {
    // Create central node for categories view
    final centerNode = Node.Id('center');
    _graph.addNode(centerNode);
    
    // Group activities by category
    final Map<String, List<Activity>> categoryGroups = {};
    for (var activity in activities) {
      categoryGroups[activity.category] ??= [];
      categoryGroups[activity.category]!.add(activity);
    }
    
    // Create category nodes
    final Map<String, Node> categoryNodes = {};
    for (var category in categoryGroups.keys) {
      final categoryNode = Node.Id('cat_$category');
      categoryNodes[category] = categoryNode;
      _graph.addNode(categoryNode);
      
      // Connect category to center
      _graph.addEdge(centerNode, categoryNode);
    }
    
    // Create activity nodes and connect to categories
    for (var entry in categoryGroups.entries) {
      final category = entry.key;
      final categoryActivities = entry.value;
      
      // Get unique activity names in this category
      final uniqueNames = categoryActivities
          .map((a) => a.name)
          .toSet();
      
      for (var name in uniqueNames) {
        final activityNode = Node.Id('act_${category}_$name');
        _graph.addNode(activityNode);
        
        // Connect to category
        _graph.addEdge(categoryNodes[category]!, activityNode);
      }
    }
  }

  Widget _getNodeWidget(String nodeId) {
    final provider = context.read<ActivityProvider>();
    
    // Parse node ID to determine type
    if (nodeId == 'center') {
      return _buildCenterNode();
    } else if (nodeId.startsWith('cat_')) {
      final category = nodeId.substring(4);
      return _buildCategoryNode(category);
    } else if (nodeId.startsWith('act_')) {
      final parts = nodeId.substring(4).split('_');
      final category = parts[0];
      final activityName = parts.sublist(1).join('_');
      return _buildActivityNode(activityName, category);
    } else {
      // Temporal view node (activity name)
      final activities = provider.activities
          .where((a) => a.name.toLowerCase() == nodeId)
          .toList();
      
      if (activities.isNotEmpty) {
        return _buildTemporalNode(activities.first);
      }
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildCenterNode() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppTheme.primaryPurple,
                AppTheme.primaryPurple.withValues(alpha: 0.5),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: _animation.value,
              child: const Icon(
                Icons.hub,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryNode(String category) {
    final provider = context.read<ActivityProvider>();
    final categoryColor = provider.getCategoryColor(category);
    final color = categoryColor != null 
        ? Color(int.parse(categoryColor.replaceFirst('#', '0xff')))
        : AppTheme.categoryColors[
            category.hashCode % AppTheme.categoryColors.length
          ];
    
    final count = provider.activities
        .where((a) => a.category == category)
        .length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityNode(String name, String category) {
    final provider = context.read<ActivityProvider>();
    final activities = provider.activities
        .where((a) => a.name == name && a.category == category)
        .toList();
    
    if (activities.isEmpty) return const SizedBox.shrink();
    
    final activity = activities.first;
    final count = activities.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: activity.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: activity.color,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.length > 10 ? '${name.substring(0, 10)}...' : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          if (count > 1) ...[
            const SizedBox(height: 2),
            Text(
              '×$count',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemporalNode(Activity activity) {
    final provider = context.read<ActivityProvider>();
    final sameActivities = provider.activities
        .where((a) => a.name.toLowerCase() == activity.name.toLowerCase())
        .length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activity.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: activity.color,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: activity.color.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            activity.name.length > 12 
                ? '${activity.name.substring(0, 12)}...' 
                : activity.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.loc('network.times',
                  fallback: '{count} veces',
                  args: {'count': sameActivities.toString()}),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    
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
                          Icons.scatter_plot,
                          color: AppTheme.primaryPurple,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.loc('network.header',
                              fallback: 'Mapa de Actividades'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // View Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isTemporalView = true;
                                  _buildGraph();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isTemporalView 
                                      ? AppTheme.primaryPurple 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.timeline,
                                      color: _isTemporalView 
                                          ? Colors.white 
                                          : Colors.white.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.loc('network.view.timeline',
                                          fallback: 'Vista Temporal'),
                                      style: TextStyle(
                                        color: _isTemporalView 
                                            ? Colors.white 
                                            : Colors.white.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isTemporalView = false;
                                  _buildGraph();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isTemporalView 
                                      ? AppTheme.primaryPurple 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: !_isTemporalView 
                                          ? Colors.white 
                                          : Colors.white.withValues(alpha: 0.6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.loc('network.view.categories',
                                          fallback: 'Vista por Categorías'),
                                      style: TextStyle(
                                        color: !_isTemporalView 
                                            ? Colors.white 
                                            : Colors.white.withValues(alpha: 0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Graph View
              Expanded(
                child: provider.activities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.scatter_plot,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.loc('network.empty.title',
                                  fallback: 'No hay actividades para mostrar'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.loc('network.empty.subtitle',
                                  fallback: 'Agrega actividades para ver el mapa'),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : InteractiveViewer(
                        constrained: false,
                        boundaryMargin: const EdgeInsets.all(100),
                        minScale: 0.01,
                        maxScale: 5.6,
                        child: GraphView(
                          graph: _graph,
                          algorithm: SugiyamaAlgorithm(_builder),
                          paint: Paint()
                            ..color = AppTheme.primaryPurple.withValues(alpha: 0.3)
                            ..strokeWidth = 2.5
                            ..style = PaintingStyle.stroke,
                          builder: (Node node) {
                            final nodeId = node.key?.value as String;
                            return _getNodeWidget(nodeId);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




