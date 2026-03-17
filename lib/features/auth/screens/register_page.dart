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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    final response = await _apiService.register(_nameController.text.trim(), _selectedRole, phone);
    setState(() => _isLoading = false);

    if (response['success'] == true) {
      await _storageService.saveUserPhone(phone: phone);
      _showSuccessDialog(response['code']);
    } else {
      _showSnack(response['message'] ?? 'Erreur inconnue');
    }
  }

  void _showSuccessDialog(dynamic code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Inscription Réussie !"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Voici votre code d'accès personnel :", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.blueGrey[50], borderRadius: BorderRadius.circular(15)),
              child: Text("$code", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5, color: Colors.blueAccent)),
            ),
            const SizedBox(height: 20),
            const Text("Notez-le bien, il vous sera demandé pour chaque connexion.", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
            child: const Text("J'AI COMPRIS"),
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF121212)], // Bleu pétrole profond vers noir
          ),
        ),
        child: Stack(
          children: [
            // Décoration de fond (cercles flous)
            Positioned(
              top: -50,
              right: -50,
              child: Container(width: 200, height: 200, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), shape: BoxShape.circle)),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle)),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    children: [
                      // Branding
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
                      const SizedBox(height: 50),

                      // Carte Formulaire Glassmorphism
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
                                  _buildTextField(controller: _nameController, label: 'Nom complet', icon: Icons.person_outline),
                                  const SizedBox(height: 20),
                                  _buildTextField(controller: _phoneController, label: 'Téléphone (+243...)', icon: Icons.phone_android_outlined, keyboard: TextInputType.phone),
                                  const SizedBox(height: 20),
                                  
                                  // Custom Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedRole,
                                    dropdownColor: const Color(0xFF1A237E),
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _inputDecoration('Rôle', Icons.badge_outlined),
                                    items: const [
                                      DropdownMenuItem(value: 'user', child: Text('Pompiste')),
                                      DropdownMenuItem(value: 'admin', child: Text('Gérant')),
                                    ],
                                    onChanged: (val) => setState(() => _selectedRole = val!),
                                  ),
                                  
                                  const SizedBox(height: 40),

                                  // Bouton S'inscrire Premium
                                  Container(
                                    width: double.infinity,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: const LinearGradient(colors: [Colors.blueAccent, Color(0xFF3949AB)]),
                                      boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
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
                      
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text('Vous avez déjà un compte ? Se connecter', style: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 20),
                      const Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white38)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }
}
