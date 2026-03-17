import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/core/services/storage_service.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/widgets/tank_widget.dart';
import 'package:nexatank/features/shared/widgets/protected_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<dynamic> _tanks = [];
  List<dynamic> _recentMeasures = [];
  bool _isLoading = true;
  String? _adminName;
  int _alertCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await _storageService.getUserName();
    if (mounted) setState(() => _adminName = name);
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getTanks();
      if (response['success'] == true && response['tanks'] != null) {
        if (mounted) {
          setState(() {
            _tanks = List.from(response['tanks']);
            _recentMeasures = List.from(response['recentMeasures'] ?? []);
            _calculateStats();
            _isLoading = false;
          });
        }
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    if (!mounted) return;
    setState(() {
      _tanks = [
        { "id": 1, "name": "Sc1", "capacity": 10000.0, "type": "Essence", "current_volume": 10000.0 },
        { "id": 2, "name": "Sc2", "capacity": 22000.0, "type": "Essence", "current_volume": 22000.0 },
        { "id": 3, "name": "Sc3", "capacity": 44000.0, "type": "Essence", "current_volume": 44000.0 },
        { "id": 4, "name": "Go1", "capacity": 28000.0, "type": "Gazole", "current_volume": 28000.0 },
        { "id": 5, "name": "Go2", "capacity": 16000.0, "type": "Gazole", "current_volume": 16000.0 }
      ];
      _calculateStats();
      _isLoading = false;
    });
  }

  void _calculateStats() {
    int count = 0;
    for (var t in _tanks) {
      final double cap = (t['capacity'] as num?)?.toDouble() ?? 0.0;
      final double vol = (t['current_volume'] as num?)?.toDouble() ?? 0.0;
      if (cap > 0 && (vol / cap) < 0.15) count++;
    }
    setState(() => _alertCount = count);
  }

  @override
  Widget build(BuildContext context) {
    double totalEssence = 0;
    double totalGazole = 0;
    for (var t in _tanks) {
      final vol = (t['current_volume'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'Essence') totalEssence += vol;
      else if (t['type'] == 'Gazole') totalGazole += vol;
    }
    double totalVolume = totalEssence + totalGazole;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return ProtectedPage(
      allowedRoles: const ['admin', 'superAdmin'],
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF121212)],
            ),
          ),
          child: SafeArea(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _fetchAdminData,
                child: CustomScrollView(
                  slivers: [
                    // Header Gérant
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NexaTank', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                                Text('Gérant: ${_adminName ?? "---"}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24), color: Colors.white.withOpacity(0.05)),
                              child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: Divider(color: Colors.white10, height: 1)),

                    // Stat Cards Glass
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard("Volume Global", "${totalVolume.toInt()} L", Icons.analytics_rounded, Colors.blueAccent)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStatCard("Alertes", "$_alertCount", Icons.warning_rounded, _alertCount > 0 ? Colors.redAccent : Colors.greenAccent)),
                          ],
                        ),
                      ),
                    ),

                    // Répartition Carburant Glass
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                              child: Row(
                                children: [
                                  _buildStockIndicator("ESSENCE", totalEssence, Colors.redAccent, totalVolume),
                                  const SizedBox(width: 30),
                                  _buildStockIndicator("GAZOLE", totalGazole, Colors.amber, totalVolume),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Historique Horizontal
                    if (_recentMeasures.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                          child: Text("Dernières Mesures", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 110,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: _recentMeasures.length,
                            itemBuilder: (context, index) {
                              final m = _recentMeasures[index];
                              return Container(
                                width: 180,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(m['tank'] ?? "---", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text("${m['volume'] ?? 0} L", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                    Text("par ${m['user'] ?? '---'}", style: const TextStyle(fontSize: 10, color: Colors.white38)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],

                    // Grille des Cuves
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                        child: Text("État des Cuves", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tank = _tanks[index];
                            return TankWidget(
                              name: tank['name'] ?? 'Inconnu',
                              capacity: (tank['capacity'] as num?)?.toDouble() ?? 0.0,
                              type: tank['type'] ?? 'Essence',
                              currentVolume: (tank['current_volume'] as num?)?.toDouble() ?? 0.0,
                            );
                          },
                          childCount: _tanks.length,
                        ),
                      ),
                    ),

                    // Footer Signature
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () async {
                                await _storageService.clearSession();
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
                              },
                              child: Text("Déconnexion", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                            ),
                            const Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white24)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(String label, double volume, Color color, double total) {
    double percent = total > 0 ? (volume / total).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent, 
              backgroundColor: Colors.white.withOpacity(0.05),
              color: color,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text("${volume.toInt()} L", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
