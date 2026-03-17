import 'package:flutter/material.dart';
import 'package:nexatank/core/services/storage_service.dart';
import 'package:nexatank/features/admin/SuperAdminHome.dart';
import 'package:nexatank/features/admin/admin_home.dart';
import 'package:nexatank/features/operator/operator_home.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';

class ProtectedPage extends StatefulWidget {
  final List<String> allowedRoles;
  final Widget child;

  const ProtectedPage({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  @override
  State<ProtectedPage> createState() => _ProtectedPageState();
}

class _ProtectedPageState extends State<ProtectedPage> {
  late Future<String?> _roleFuture;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // On ne lance le futur qu'une seule fois !
    _roleFuture = _storageService.getUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userRole = snapshot.data;

        if (snapshot.hasError || userRole == null) {
          _redirect(const LandingPage());
          return const Scaffold(body: SizedBox.shrink());
        }

        if (widget.allowedRoles.contains(userRole)) {
          return widget.child;
        } else {
          _redirectToCorrectHome(userRole);
          return const Scaffold(body: SizedBox.shrink());
        }
      },
    );
  }

  void _redirect(Widget page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => page),
          (route) => false,
        );
      }
    });
  }

  void _redirectToCorrectHome(String role) {
    Widget correctHome;
    switch (role) {
      case 'superAdmin':
        correctHome = const SuperAdminHome();
        break;
      case 'admin':
        correctHome = const AdminHome();
        break;
      default:
        correctHome = const OperatorHome();
    }
    _redirect(correctHome);
  }
}
