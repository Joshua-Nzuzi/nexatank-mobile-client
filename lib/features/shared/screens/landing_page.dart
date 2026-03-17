import 'package:flutter/material.dart';
import 'dart:ui';
import '../../auth/login_page.dart';
import '../../auth/screens/register_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF121212)],
          ),
        ),
        child: Stack(
          children: [
            // Décoration de fond
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(width: 300, height: 300, decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), shape: BoxShape.circle)),
            ),
            
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Branding
                      Hero(
                        tag: 'logo',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                            color: Colors.white.withOpacity(0.05),
                          ),
                          child: const Center(
                            child: Text('N', style: TextStyle(fontSize: 50, color: Colors.white, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Texte hiérarchisé
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Bienvenu sur\n',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.white70, letterSpacing: 1),
                            ),
                            TextSpan(
                              text: 'NexaTank',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'la Jauge intelligente',
                        style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 1.2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 80),

                      // Actions avec Glassmorphism
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                    child: const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.white24),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    ),
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                                    child: const Text('CRÉER UN COMPTE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),
                      const Text(
                        'powered by JoshuaDev',
                        style: TextStyle(fontSize: 11, color: Colors.white24, letterSpacing: 0.5),
                      ),
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
}
