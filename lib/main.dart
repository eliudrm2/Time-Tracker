import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/error_handler.dart';
import 'utils/device_info_helper.dart';

void main() async {
  // Asegurar inicialización de widgets
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configuración de orientación (solo retrato para consistencia)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar manejo global de errores
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log del error
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      // En producción, enviar a Firebase Crashlytics
      ErrorHandler.logError(details.exception, details.stack);
    }
  };
  
  // Capturar errores asíncronos
  runZonedGuarded(() {
    runApp(const TimeTrackerApp());
  }, (error, stack) {
    ErrorHandler.logError(error, stack);
  });
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker - NavShock Studio',
      debugShowCheckedModeBanner: false,
      
      // Tema profesional y consistente
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A90E2),
          secondary: Color(0xFF50C878),
          surface: Color(0xFF1A1A2E),
          error: Color(0xFFFF6B6B),
        ),
        fontFamily: 'Roboto',
        
        // Configuración específica de componentes
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFF262640),
        ),
      ),
      
      // Rutas nombradas para navegación
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      
      // Manejo de errores de navegación
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const ErrorScreen(),
        );
      },
    );
  }
}

// Pantalla principal optimizada
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  List<TimeEntry> _timeEntries = [];
  late SharedPreferences _prefs;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _checkDeviceCompatibility();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  // Manejar ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveData();
    } else if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }
  
  Future<void> _checkDeviceCompatibility() async {
    // Verificar compatibilidad del dispositivo
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    if (kDebugMode) {
      print('Device: ${deviceInfo['model']} - Android ${deviceInfo['version']}');
    }
  }
  
  Future<void> _loadData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Cargar entradas guardadas
      final entriesJson = _prefs.getStringList('timeEntries') ?? [];
      setState(() {
        _timeEntries = entriesJson.map((e) => TimeEntry.fromJson(e)).toList();
      });
      
      // Restaurar timer si estaba activo
      final isRunning = _prefs.getBool('isRunning') ?? false;
      if (isRunning) {
        final startTimeMillis = _prefs.getInt('startTime');
        if (startTimeMillis != null) {
          _startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
          _startTimer();
        }
      }
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
      _showErrorSnackBar('Error al cargar datos');
    }
  }
  
  Future<void> _saveData() async {
    try {
      // Guardar entradas
      final entriesJson = _timeEntries.map((e) => e.toJson()).toList();
      await _prefs.setStringList('timeEntries', entriesJson);
      
      // Guardar estado del timer
      await _prefs.setBool('isRunning', _isRunning);
      if (_startTime != null) {
        await _prefs.setInt('startTime', _startTime!.millisecondsSinceEpoch);
      }
    } catch (e, stack) {
      ErrorHandler.logError(e, stack);
    }
  }
  
  void _startTimer() {
    setState(() {
      _isRunning = true;
      _startTime ??= DateTime.now();
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedTime = DateTime.now().difference(_startTime!);
        });
      }
    });
  }
  
  void _stopTimer() {
    _timer?.cancel();
    
    if (_startTime != null) {
      final entry = TimeEntry(
        startTime: _startTime!,
        duration: _elapsedTime,
        description: 'Sesión de trabajo',
      );
      
      setState(() {
        _timeEntries.insert(0, entry);
        _isRunning = false;
        _startTime = null;
        _elapsedTime = Duration.zero;
      });
      
      _saveData();
    }
  }
  
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        title: const Text(
          'Time Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer Display
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _formatDuration(_elapsedTime),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF50C878),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _stopTimer : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de entradas
            Expanded(
              child: _timeEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No hay registros aún',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _timeEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _timeEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF4A90E2),
                              child: Icon(Icons.timer, color: Colors.white),
                            ),
                            title: Text(
                              entry.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              _formatDateTime(entry.startTime),
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            trailing: Text(
                              _formatDuration(entry.duration),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF50C878),
                              ),
                            ),
                            onLongPress: () {
                              // Opción para eliminar
                              _showDeleteDialog(index);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Future<void> _showDeleteDialog(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF262640),
        title: const Text('Eliminar entrada'),
        content: const Text('¿Estás seguro de eliminar esta entrada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() {
        _timeEntries.removeAt(index);
      });
      _saveData();
    }
  }
}

// Modelo de datos
class TimeEntry {
  final DateTime startTime;
  final Duration duration;
  final String description;
  
  TimeEntry({
    required this.startTime,
    required this.duration,
    required this.description,
  });
  
  String toJson() {
    return '${startTime.millisecondsSinceEpoch}|${duration.inSeconds}|$description';
  }
  
  static TimeEntry fromJson(String json) {
    final parts = json.split('|');
    return TimeEntry(
      startTime: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
      duration: Duration(seconds: int.parse(parts[1])),
      description: parts.length > 2 ? parts[2] : 'Sesión de trabajo',
    );
  }
}

// Pantalla de error
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Oops! Algo salió mal',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}