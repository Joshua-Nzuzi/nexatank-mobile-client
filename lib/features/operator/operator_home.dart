import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/widgets/tank_widget.dart';
import '../../../core/services/storage_service.dart';
import '../shared/widgets/protected_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final name = await _storageService.getUserName();
    setState(() => _userName = name);
    _fetchTanks();
  }

  Future<void> _fetchTanks() async {
    setState(() => _isLoading = true);
    final response = await _apiService.getTanks();
    if (response['success'] == true && response['tanks'] != null) {
      setState(() {
        _tanks = response['tanks'];
        _recentMeasures = response['recentMeasures'] ?? [];
        _isLoading = false;
      });
    } else {
      _isLoading = false;
    }
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
            const Text("HISTORIQUE TECHNIQUE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
            const Divider(color: Colors.white10, height: 30),
            Expanded(
              child: _recentMeasures.isEmpty 
                ? const Center(child: Text("Aucune donnée", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _recentMeasures.length,
                    itemBuilder: (context, index) {
                      final m = _recentMeasures[index];
                      return _buildMeasureCard(m);
                    },
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _buildGlassModal(
          context,
          heightFactor: 0.6,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Nouvelle Mesure", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                DropdownButtonFormField<dynamic>(
                  dropdownColor: const Color(0xFF1A237E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Choisir la cuve", Icons.gas_meter),
                  items: _tanks.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'], style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setModalState(() => selectedTankId = val),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: depthController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  decoration: _inputDecoration("Profondeur (cm)", Icons.straighten),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: selectedTankId == null ? null : () async {
                    final res = await _apiService.calculateVolume(selectedTankId, double.parse(depthController.text));
                    if (res['success']) {
                      await _fetchTanks();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("VALIDER LA MESURE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassModal(BuildContext context, {required double heightFactor, required Widget child}) {
    return Container(
      height: MediaQuery.of(context).size.height * heightFactor,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(color: Color(0xFF1A237E), borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
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
    );
  }

  Widget _buildMeasureCard(dynamic m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          const Icon(Icons.history_edu_rounded, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 15),
          Expanded(child: Column(
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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.blueAccent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalEssence = _tanks.where((t) => t['type'] == 'Essence').fold(0.0, (sum, t) => sum + ((t['current_volume'] as num?)?.toDouble() ?? 0.0));
    double totalGazole = _tanks.where((t) => t['type'] == 'Gazole').fold(0.0, (sum, t) => sum + ((t['current_volume'] as num?)?.toDouble() ?? 0.0));
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    return ProtectedPage(
      allowedRoles: const ['user', 'admin', 'superAdmin'],
      child: Scaffold(
        body: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF121212)])),
          child: SafeArea(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('NexaTank', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Pompiste: $_userName', style: const TextStyle(fontSize: 11, color: Colors.white38, fontWeight: FontWeight.bold)),
                      ]),
                      Row(children: [
                        IconButton(icon: const Icon(Icons.history_edu_rounded, color: Colors.blueAccent), onPressed: _showMeasurementsList),
                        IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20), onPressed: () async {
                          await _storageService.clearSession();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
                        }),
                      ]),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(children: [
                    _buildMiniStat("ESSENCE", totalEssence, Colors.redAccent),
                    const SizedBox(width: 10),
                    _buildMiniStat("GAZOLE", totalGazole, Colors.amber),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: _showGetVolumeDialog,
                    icon: const Icon(Icons.add_chart_rounded, color: Colors.white),
                    label: const Text("NOUVELLE MESURE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
        Text("${volume.toInt()} L", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
      ]),
    ));
  }
}
