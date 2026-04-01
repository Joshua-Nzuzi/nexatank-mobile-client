import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'user';

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;

  // Palette Obsidian Teal
  final Color _primaryDark = const Color(0xFF002B26); 
  final Color _accentTeal = const Color(0xFF00BFA5); 
  final Color _darkBg = const Color(0xFF121212);

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent.withOpacity(0.8) : _accentTeal.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    
    try {
      final response = await _apiService.register(_nameController.text.trim(), _selectedRole, phone);
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        await _storageService.saveUserPhone(phone: phone);
        _showSuccessDialog(response['code']);
      } else {
        _showSnack(response['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Impossible de joindre le serveur. Vérifiez votre connexion.");
    }
  }

  void _showSuccessDialog(dynamic code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text("Inscription Réussie !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Voici votre code d'accès personnel :", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _accentTeal.withOpacity(0.5)),
              ),
              child: Text("$code", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 8, color: _accentTeal)),
            ),
            const SizedBox(height: 20),
            const Text("Notez-le bien, il vous sera demandé pour chaque connexion.", style: TextStyle(fontSize: 12, color: Colors.white38), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            child: Text("J'AI COMPRIS", style: TextStyle(color: _accentTeal, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_primaryDark, _darkBg],
          ),
        ),
        child: Stack(
          children: [
            Positioned(top: -50, right: -50, child: Container(width: 200, height: 200, decoration: BoxDecoration(color: _accentTeal.withOpacity(0.1), shape: BoxShape.circle))),
            Positioned(bottom: 100, left: -30, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
            
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                              const Text('La jauge Intelligente', style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 1)),
                              const Spacer(),
                              const SizedBox(height: 40),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1), 
                                      borderRadius: BorderRadius.circular(30), 
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                    ),
                                    child: Form(
                                      key: _formKey,
                                      child: Column(
                                        children: [
                                          _buildTextField(
                                            controller: _nameController, 
                                            label: 'Nom complet', 
                                            icon: Icons.person_outline,
                                            action: TextInputAction.next,
                                          ),
                                          const SizedBox(height: 20),
                                          _buildTextField(
                                            controller: _phoneController, 
                                            label: 'Téléphone (+243...)', 
                                            icon: Icons.phone_android_outlined, 
                                            keyboard: TextInputType.phone,
                                            action: TextInputAction.done,
                                            onSubmitted: (_) => _register(),
                                          ),
                                          const SizedBox(height: 20),
                                          
                                          DropdownButtonFormField<String>(
                                            value: _selectedRole,
                                            dropdownColor: _primaryDark,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: _inputDecoration('Rôle', Icons.badge_outlined),
                                            items: const [
                                              DropdownMenuItem(value: 'user', child: Text('Pompiste')),
                                              DropdownMenuItem(value: 'admin', child: Text('Gérant')),
                                            ],
                                            onChanged: (val) => setState(() => _selectedRole = val!),
                                          ),
                                          
                                          const SizedBox(height: 40),

                                          Container(
                                            width: double.infinity,
                                            height: 55,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              gradient: LinearGradient(colors: [_accentTeal, const Color(0xFF00897B)]),
                                              boxShadow: [BoxShadow(color: _accentTeal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                                            ),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent, 
                                                shadowColor: Colors.transparent, 
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                              ),
                                              onPressed: _isLoading ? null : _register,
                                              child: _isLoading 
                                                  ? const CircularProgressIndicator(color: Colors.white) 
                                                  : const Text('CRÉER MON COMPTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
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
                                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                child: const Text('Vous avez déjà un compte ? Se connecter', style: TextStyle(color: Colors.white70)),
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

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      onFieldSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
      validator: (val) => (val == null || val.isEmpty) ? 'Champ requis' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _accentTeal, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
