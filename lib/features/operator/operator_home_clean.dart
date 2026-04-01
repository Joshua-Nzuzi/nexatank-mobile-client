import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/core/services/storage_service.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/widgets/tank_widget.dart';
import 'package:nexatank/features/shared/widgets/measure_feedback.dart';
import 'package:nexatank/features/shared/widgets/app_feedback.dart';
import 'package:nexatank/features/shared/widgets/protected_page.dart';

class OperatorHome extends StatefulWidget {
  const OperatorHome({super.key});

  @override
  State<OperatorHome> createState() => _OperatorHomeState();
}

class _OperatorHomeState extends State<OperatorHome> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<dynamic> _tanks = [];
  List<dynamic> _recentMeasures = [];
  bool _isLoading = true;
  String? _userName;

  final Color _primaryDark = const Color(0xFF002B26);
  final Color _accentTeal = const Color(0xFF00BFA5);
  final Color _darkBg = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final name = await _storageService.getUserName();
      if (mounted) setState(() => _userName = name);
      WidgetsBinding.instance.addPostFrameCallback((_) => showWelcomeSnackBar(context, name));
      await _fetchTanks();
    } catch (_) {}
  }

  Future<void> _fetchTanks() async {
    setState(() => _isLoading = true);
    try {
      final resp = await _apiService.getTanks();
      if (resp != null && resp['success'] == true) {
        final tanks = resp['tanks'] as List<dynamic>? ?? [];
        final recent = resp['recentMeasures'] as List<dynamic>? ?? [];
        if (mounted) setState(() {
          _tanks = List.from(tanks);
          _recentMeasures = List.from(recent);
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showNetworkError(context);
    }
  }

  void _showMeasurementsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildGlassModal(
        ctx,
        heightFactor: 0.75,
        child: Column(
          children: [
            const Text('HISTORIQUE TECHNIQUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: _recentMeasures.isEmpty
                  ? const Center(child: Text('Aucune donnée', style: TextStyle(color: Colors.white24)))
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

  void _showGetVolumeDialog() {
    dynamic selectedTankId;
    final depthController = TextEditingController();
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return _buildGlassModal(
          context,
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('Nouvelle Mesure', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<dynamic>(
                  dropdownColor: _primaryDark,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Choisir la cuve', Icons.gas_meter),
                  items: _tanks.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'] ?? 'Inconnu', style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (v) => setModalState(() => selectedTankId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: depthController,
                  enabled: selectedTankId != null,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _inputDecoration('Profondeur (cm)', Icons.straighten),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _accentTeal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: (selectedTankId == null || isProcessing)
                        ? null
                        : () async {
                            final depthStr = depthController.text.trim();
                            final tankName = _tanks.firstWhere((t) => t['id'] == selectedTankId, orElse: () => {'name': selectedTankId})['name'];
                            if (depthStr.isEmpty) {
                              await showMeasureResult(context, success: false, message: 'Veuillez entrer la profondeur.', summary: {'tank': tankName});
                              return;
                            }
                            final depth = double.tryParse(depthStr);
                            if (depth == null) {
                              await showMeasureResult(context, success: false, message: 'Profondeur invalide.', summary: {'tank': tankName});
                              return;
                            }
                            setModalState(() => isProcessing = true);
                            try {
                              final res = await _apiService.calculateVolume(selectedTankId, depth);
                              if (res != null && res['success'] == true) {
                                await _fetchTanks();
                              }
                              await showMeasureResult(context, success: res['success'] == true, message: res['message'] ?? '', summary: {'tank': tankName, 'depth': depth, 'volume': res['volume'] ?? res['data']?['volume'] ?? '--'});
                              if (res['success'] == true) Navigator.pop(context);
                            } catch (e) {
                              showNetworkError(context);
                            } finally {
                              setModalState(() => isProcessing = false);
                            }
                          },
                    child: const Text('VALIDER LA MESURE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGlassModal(BuildContext context, {required double heightFactor, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * heightFactor,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: _primaryDark.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(Icons.history_edu_rounded, color: _accentTeal, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${m['tank']} • par ${m['user']}", style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(children: [
                  Text("${m['depth']} cm", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_right_alt, color: Colors.white24)),
                  Text("${m['volume']} L", style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white24)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: _accentTeal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalEssence = _tanks.where((t) => t['type'] == 'Essence').fold(0.0, (s, t) => s + ((t['current_volume'] as num?)?.toDouble() ?? 0.0));
    final double totalGazole = _tanks.where((t) => t['type'] == 'Gazole').fold(0.0, (s, t) => s + ((t['current_volume'] as num?)?.toDouble() ?? 0.0));
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return ProtectedPage(
      allowedRoles: const ['user', 'admin', 'superAdmin'],
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_primaryDark, _darkBg])),
          child: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('NexaTank', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Pompiste: ${_userName ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
                            ]),
                            Row(children: [
                              IconButton(icon: Icon(Icons.history_edu_rounded, color: _accentTeal), onPressed: _showMeasurementsList),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                                onPressed: () async {
                                  final ok = await confirmLogoutDialog(context);
                                  if (!ok) return;
                                  await _storageService.clearSession();
                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c) => const LandingPage()), (route) => false);
                                },
                              ),
                            ]),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(children: [
                          _buildMiniStat('ESSENCE', totalEssence, Colors.redAccent),
                          const SizedBox(width: 10),
                          _buildMiniStat('GAZOLE', totalGazole, Colors.amber),
                        ]),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
                          itemCount: _tanks.length,
                          itemBuilder: (context, index) {
                            final t = _tanks[index];
                            return TankWidget(name: t['name'], capacity: (t['capacity'] as num).toDouble(), type: t['type'], currentVolume: (t['current_volume'] as num).toDouble());
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: _accentTeal, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: _showGetVolumeDialog,
                          icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
                          label: const Text('NOUVELLE MESURE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white24, height: 2)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double volume, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
          Text('${volume.toInt()} L', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      ),
    );
  }
}
