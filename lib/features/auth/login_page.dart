import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/services/api_service.dart';
import '../../core/services/storage_service.dart';
import '../admin/SuperAdminHome.dart';
import '../admin/admin_home.dart';
import '../operator/operator_home.dart';
import 'screens/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  bool _obscureCode = true;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final code = int.tryParse(_codeController.text.trim());

    if (code == null) {
      _showSnackBar('Code invalide.');
      setState(() => _isLoading = false);
      return;
    }

    final response = await _apiService.loginWithCode(code);
    
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      final user = response['user'];
      await _storage.saveUserSession(
        token: response['token'], 
        role: user['role'], 
        phone: user['phone'] ?? '', 
        name: user['name']
      );

      if (user['role'] == 'superAdmin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SuperAdminHome()));
      } else if (user['role'] == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHome()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OperatorHome()));
      }
    } else {
      _showSnackBar(response['message'] ?? 'Code incorrect');
    }
  }

  void _forgotCode() {
    final forgotPhoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Récupérer mon code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Entrez votre téléphone pour recevoir un nouveau code."),
            const SizedBox(height: 16),
            TextField(
              controller: forgotPhoneController, 
              keyboardType: TextInputType.phone, 
              decoration: const InputDecoration(labelText: "Téléphone (+243...)", border: OutlineInputBorder())
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final phone = forgotPhoneController.text.trim();
              if (phone.isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final response = await _apiService.regenerateCode(phone);
              setState(() => _isLoading = false);
              if (response['success'] == true) {
                _showSuccessDialog("Nouveau code : ${response['code']}");
              } else {
                _showSnackBar(response['message'] ?? "Erreur");
              }
            },
            child: const Text("Générer"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Succès"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1A237E), Color(0xFF121212)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 100,
              left: -50,
              child: Container(width: 250, height: 250, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.15), shape: BoxShape.circle)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                          child: Column(
                            children: [
                              Hero(
                                tag: 'logo',
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  child: const Text('N', style: TextStyle(fontSize: 50, fontWeight: FontWeight.w900, color: Colors.white)),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('NexaTank', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
                              const Text('La jauge Intelligente', style: TextStyle(fontSize: 14, color: Colors.white70)),
                              const Spacer(),
                              const SizedBox(height: 40),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(30),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          const Text(
                                            "Code d'accès",
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                                          ),
                                          const SizedBox(height: 20),
                                          TextFormField(
                                            controller: _codeController,
                                            keyboardType: TextInputType.number,
                                            obscureText: _obscureCode,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                            decoration: InputDecoration(
                                              hintText: "----",
                                              hintStyle: const TextStyle(color: Colors.white24),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
                                              suffixIcon: IconButton(
                                                icon: Icon(_obscureCode ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                                                onPressed: () => setState(() => _obscureCode = !_obscureCode),
                                              ),
                                            ),
                                            validator: (value) => (value == null || value.length != 4) ? '4 chiffres requis' : null,
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight, 
                                            child: TextButton(
                                              onPressed: _forgotCode, 
                                              child: const Text('Code oublié ?', style: TextStyle(color: Colors.white60))
                                            )
                                          ),
                                          const SizedBox(height: 30),
                                          Container(
                                            width: double.infinity,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              gradient: const LinearGradient(colors: [Colors.blueAccent, Color(0xFF3949AB)]),
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                              ),
                                              onPressed: _isLoading ? null : _login,
                                              child: _isLoading 
                                                  ? const CircularProgressIndicator(color: Colors.white) 
                                                  : const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 30),
                              TextButton(
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegisterPage())), 
                                child: const Text('Créer un compte', style: TextStyle(color: Colors.white70))
                              ),
                              const SizedBox(height: 10),
                              const Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white38)),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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
}
