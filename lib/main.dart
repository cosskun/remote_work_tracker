import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/work_model.dart';
import 'screens/home_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'storage.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress yellow-black zebra stripe overflow warnings across all devices
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };
  
  // Initialize Turkish localization for date formatting
  await initializeDateFormatting('tr_TR', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uzaktan Çalışma Takipçisi',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  double _hourlyRate = 150.0;
  List<WorkLog> _allLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load initial settings and logs from storage
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final double rate = await WorkStorage.getHourlyRate();
    final List<WorkLog> logs = await WorkStorage.getWorkLogs();

    setState(() {
      _hourlyRate = rate;
      _allLogs = logs;
      _isLoading = false;
    });
  }

  // Triggered when logs are added or deleted
  void _onLogsChanged(List<WorkLog> updatedLogs) {
    setState(() {
      _allLogs = updatedLogs;
    });
  }

  // Triggered when hourly rate is modified
  void _onHourlyRateChanged(double newRate) {
    setState(() {
      _hourlyRate = newRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a clean loading indicator while initializing SharedPreferences
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    final List<Widget> screens = [
      HomeScreen(
        allLogs: _allLogs,
        hourlyRate: _hourlyRate,
        onLogsChanged: _onLogsChanged,
        onHourlyRateChanged: _onHourlyRateChanged,
      ),
      ReportsScreen(
        allLogs: _allLogs,
        hourlyRate: _hourlyRate,
      ),
      ProfileScreen(
        hourlyRate: _hourlyRate,
        onHourlyRateChanged: _onHourlyRateChanged,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.workspace_premium, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              'Çalışma Takipçisi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              activeIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
              label: 'Ana Ekran',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              activeIcon: Icon(Icons.analytics_rounded, color: AppColors.primary),
              label: 'Rapor & Excel',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
