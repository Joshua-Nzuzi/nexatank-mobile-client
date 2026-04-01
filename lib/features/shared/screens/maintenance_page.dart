import 'package:flutter/material.dart';
import 'dart:ui';

class MaintenancePage extends StatelessWidget {
  final String message;
  const MaintenancePage({super.key, required this.message});

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
            colors: [Color(0xFF002B26), Color(0xFF121212)],
          ),
        ),
        child: Stack(
          children: [
            // Animation de fond légère
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00BFA5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icône de maintenance Premium
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00BFA5).withOpacity(0.2)),
                        color: const Color(0xFF00BFA5).withOpacity(0.05),
                      ),
                      child: const Icon(
                        Icons.settings_suggest_rounded,
                        size: 60,
                        color: Color(0xFF00BFA5),
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    const Text(
                      "NexaTank",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "SYSTÈME SOUS OPTIMISATION",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF00BFA5),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Bouton Actualiser
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00BFA5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: () {
                          // Tente de recharger l'application
                          Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
                        },
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00BFA5)),
                        label: const Text(
                          "ACTUALISER",
                          style: TextStyle(color: Color(0xFF00BFA5), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    const Text(
                      'powered by JoshuaDev',
                      style: TextStyle(fontSize: 10, color: Colors.white24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
