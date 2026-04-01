import 'package:flutter/material.dart';
import 'features/shared/screens/landing_page.dart';
import 'features/auth/screens/register_page.dart';
import 'features/auth/login_page.dart';
import 'features/admin/admin_home.dart';
import 'features/operator/operator_home_clean.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final StorageService storage = StorageService();
  final bool isLogged = await storage.hasActiveSession();
  final String? role = await storage.getUserRole();

  Widget initialScreen = const LandingPage();

  if (isLogged && role != null) {
    if (role == 'admin' || role == 'superAdmin') {
      initialScreen = const AdminHome();
    } else {
      initialScreen = const OperatorHome();
    }
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexaTank',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Nouvelle Palette Obsidian Teal
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BFA5),
          primary: const Color(0xFF00BFA5),
          secondary: const Color(0xFF00897B),
          surface: const Color(0xFF121212),
          brightness: Brightness.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: initialScreen,
      routes: {
        '/landing': (_) => const LandingPage(),
        '/register': (_) => const RegisterPage(),
        '/login': (_) => const LoginPage(),
        '/pompisteHome': (_) => const OperatorHome(),
        '/adminHome': (_) => const AdminHome(),
      },
    );
  }
}
