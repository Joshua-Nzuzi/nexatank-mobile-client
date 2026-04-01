import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/core/services/storage_service.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/widgets/tank_widget.dart';
import 'package:nexatank/features/shared/widgets/measure_feedback.dart';
import 'package:nexatank/features/shared/widgets/app_feedback.dart';
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

  final Color _primaryDark = const Color(0xFF002B26);
  final Color _accentTeal = const Color(0xFF00BFA5);
  final Color _darkBg = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await _storageService.getUserName();
    if (mounted) setState(() => _adminName = name);
    WidgetsBinding.instance.addPostFrameCallback((_) => showWelcomeSnackBar(context, name));
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

  void _showMeasurementsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGlassModal(
        context,
        heightFactor: 0.75,
        child: Column(
          children: [
            const Text("HISTORIQUE DES MESURES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: _recentMeasures.isEmpty 
                ? const Center(child: Text("Aucune donnée", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _recentMeasures.length,
                    itemBuilder: (context, index) => _buildMeasureCard(_recentMeasures[index]),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCalculateDialog() {
    dynamic selectedTankId;
    final depthController = TextEditingController();
    bool isProcessing = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildGlassModal(
          context,
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Calcul Rapide Gérant", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                DropdownButtonFormField<dynamic>(
                  dropdownColor: _primaryDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Choisir la cuve", Icons.gas_meter),
                  items: _tanks.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'] ?? "Inconnu", style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setModalState(() => selectedTankId = v),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: depthController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _inputDecoration("Profondeur (cm)", Icons.straighten),
                ),
                const SizedBox(height: 18),
                StatefulBuilder(builder: (context2, setLocal) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _accentTeal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: (selectedTankId == null || isProcessing) ? null : () async {
                        final depthStr = depthController.text.trim();
                        final tankName = _tanks.firstWhere((t) => t['id'] == selectedTankId, orElse: () => {'name': '---'})['name'];
                        if (depthStr.isEmpty) {
                          await showMeasureResult(context, success: false, message: 'Veuillez entrer la profondeur.', summary: {'tank': tankName});
                          return;
                        }
                        final depth = double.tryParse(depthStr);
                        if (depth == null) {
                          await showMeasureResult(context, success: false, message: 'Profondeur invalide.', summary: {'tank': tankName});
                          return;
                        }
                        setLocal(() => isProcessing = true);
                        try {
                          final res = await _apiService.calculateVolume(selectedTankId, depth);
                          if (!mounted) return;
                          if (res['success']) {
                            await _fetchAdminData();
                          }
                          await showMeasureResult(
                            context, 
                            success: res['success'] == true, 
                            message: res['message'] ?? (res['success'] == true ? 'Mesure effectuée' : 'Erreur lors du calcul'),
                            summary: {
                              'tank': tankName,
                              'depth': depth,
                              'volume': res['volume'] ?? res['data']?['volume'] ?? '--'
                            }
                          );
                          if (res['success'] == true) Navigator.pop(context);
                        } catch (e) {
                          showNetworkError(context);
                        } finally {
                          setLocal(() => isProcessing = false);
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isProcessing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("CALCULER", key: ValueKey('calc_text'), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassModal(BuildContext context, {required double heightFactor, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * heightFactor,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: _primaryDark.withOpacity(0.95), borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasureCard(dynamic m) {
    String timeStr = "---";
    if (m['date'] != null) {
      try {
        // FORCE HEURE KINSHASA (GMT+1)
        final DateTime date = DateTime.parse(m['date']).toUtc().add(const Duration(hours: 1));
        timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: _accentTeal, size: 22),
          const SizedBox(width: 15),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${m['tank']} • par ${m['user']}", style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(timeStr, style: TextStyle(color: _accentTeal.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(children: [
                Text("${m['depth']} cm", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_right_alt, color: Colors.white24)),
                Text("${m['volume']} L", style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ]),
            ],
          )),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _accentTeal)),
    );
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
          width: double.infinity, height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_primaryDark, _darkBg])),
          child: SafeArea(
            child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _fetchAdminData,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('NexaTank', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                                Text('Gérant: ${_adminName ?? "---"}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(children: [
                              IconButton(icon: Icon(Icons.history_edu_rounded, color: _accentTeal), onPressed: _showMeasurementsList),
                              IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20), onPressed: () async {
                                final bool confirmed = await confirmLogoutDialog(context);
                                if (confirmed) {
                                  await _storageService.clearSession();
                                  if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
                                }
                              }),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(color: Colors.white10, height: 1)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard("Volume Global", "${totalVolume.toInt()} L", Icons.analytics_rounded, _accentTeal)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildStatCard("Alertes", "$_alertCount", Icons.warning_rounded, _alertCount > 0 ? Colors.redAccent : Colors.greenAccent)),
                          ],
                        ),
                      ),
                    ),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("État des Cuves", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            IconButton(icon: Icon(Icons.calculate_rounded, color: _accentTeal), onPressed: _showCalculateDialog),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: 0.72, crossAxisSpacing: 15, mainAxisSpacing: 15),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tank = _tanks[index];
                            return TankWidget(name: tank['name'] ?? '---', capacity: (tank['capacity'] as num?)?.toDouble() ?? 0.0, type: tank['type'] ?? 'Essence', currentVolume: (tank['current_volume'] as num?)?.toDouble() ?? 0.0);
                          },
                          childCount: _tanks.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white24))))),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(title, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildStockIndicator(String label, double volume, Color color, double total) {
    double percent = total > 0 ? (volume / total).clamp(0.0, 1.0) : 0.0;
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white.withOpacity(0.7), letterSpacing: 1)),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: percent, backgroundColor: Colors.white.withOpacity(0.05), color: color, minHeight: 6)),
      const SizedBox(height: 6),
      Text("${volume.toInt()} L", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
    ]));
  }
}
