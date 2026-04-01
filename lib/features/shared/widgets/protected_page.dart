import 'package:flutter/material.dart';
import 'dart:async';
import 'package:nexatank/core/services/storage_service.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/features/admin/SuperAdminHome.dart';
import 'package:nexatank/features/admin/admin_home.dart';
import 'package:nexatank/features/operator/operator_home.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/screens/maintenance_page.dart';

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
  StreamSubscription? _maintenanceSubscription;

  @override
  void initState() {
    super.initState();
    _roleFuture = _storageService.getUserRole();
    
    // ÉCOUTE DU MODE MAINTENANCE
    _maintenanceSubscription = ApiService.maintenanceStream.listen((message) {
      if (mounted) {
        _redirect(MaintenancePage(message: message));
      }
    });
  }

  @override
  void dispose() {
    _maintenanceSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _roleFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00BFA5))),
          );
        }

        final userRole = snapshot.data;

        if (snapshot.hasError || userRole == null) {
          _redirect(const LandingPage());
          return const Scaffold(backgroundColor: Color(0xFF121212), body: SizedBox.shrink());
        }

        if (widget.allowedRoles.contains(userRole)) {
          return widget.child;
        } else {
          _redirectToCorrectHome(userRole);
          return const Scaffold(backgroundColor: Color(0xFF121212), body: SizedBox.shrink());
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
