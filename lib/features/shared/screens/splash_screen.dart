import 'package:flutter/material.dart';
import 'package:nexatank/features/admin/SuperAdminHome.dart';
import 'package:nexatank/features/admin/admin_home.dart';
import 'package:nexatank/features/operator/operator_home_clean.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import '../../../core/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Attendre un court instant pour l'affichage du splash screen
    await Future.delayed(const Duration(seconds: 2));

    final hasSession = await _storageService.hasActiveSession();

    if (mounted) { // Vérifie si le widget est toujours dans l'arbre des widgets
      if (hasSession) {
        final role = await _storageService.getUserRole();
        Widget home;
        switch (role) {
          case 'Joshua':
            home = const SuperAdminHome();
            break;
          case 'Gérant':
            home = const AdminHome();
            break;
          default:
            home = const OperatorHome();
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => home));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Chargement...'),
          ],
        ),
      ),
    );
  }
}
