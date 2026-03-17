import 'package:flutter/material.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import '../../../core/services/storage_service.dart';
import '../shared/widgets/protected_page.dart';

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    return ProtectedPage(
      allowedRoles: const ['superAdmin'], // Utilisation du rôle technique du backend
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard Joshua 👑"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Se déconnecter',
              onPressed: () async {
                await storageService.clearSession();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
        body: const Center(
          child: Text("Bienvenue, Super Administrateur !"),
        ),
      ),
    );
  }
}
