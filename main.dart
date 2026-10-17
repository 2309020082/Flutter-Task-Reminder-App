import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'pages/calendar_page.dart';
import 'pages/chart_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'database/db_helper.dart';
import 'services/notif_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.database;
  await NotifServices.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Cek apakah sudah login
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tugas Kuliah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MainPage(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    ChartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2563EB),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Kalender',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Statistik',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}