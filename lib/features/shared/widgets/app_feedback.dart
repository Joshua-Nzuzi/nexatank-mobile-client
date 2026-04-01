import 'package:flutter/material.dart';

void showWelcomeSnackBar(BuildContext context, String? name) {
  final message = (name == null || name.isEmpty) ? 'Bienvenue dans NexaTank' : 'Ravi de vous revoir, $name';
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.teal,
      duration: const Duration(seconds: 2),
    ));
  });
}

Future<bool> confirmLogoutDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF002B26),
      title: const Text('Confirmer la déconnexion', style: TextStyle(color: Colors.white)),
      content: const Text('Voulez-vous vraiment vous déconnecter ?', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler', style: TextStyle(color: Colors.white70))),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Déconnecter', style: TextStyle(color: Colors.redAccent))),
      ],
    ),
  ) ?? false;
}

void showNetworkError(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Vérifiez votre connexion internet'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.redAccent,
      duration: Duration(seconds: 3),
    ));
  });
}
