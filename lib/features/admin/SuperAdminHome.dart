import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:nexatank/core/services/api_service.dart';
import 'package:nexatank/features/shared/screens/landing_page.dart';
import 'package:nexatank/features/shared/widgets/tank_widget.dart';
import '../../../core/services/storage_service.dart';
import '../shared/widgets/protected_page.dart';

class SuperAdminHome extends StatefulWidget {
  const SuperAdminHome({super.key});

  @override
  State<SuperAdminHome> createState() => _SuperAdminHomeState();
}

class _SuperAdminHomeState extends State<SuperAdminHome> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  List<dynamic> _tanks = [];
  List<dynamic> _recentMeasures = [];
  bool _isLoading = true;
  String? _adminName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final name = await _storageService.getUserName();
    if (mounted) setState(() => _adminName = name);
    _fetchTanks();
  }

  Future<void> _fetchTanks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final response = await _apiService.getTanks();
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          _tanks = response['tanks'] ?? [];
          _recentMeasures = response['recentMeasures'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  void _showUsersDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Gestion des Comptes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _apiService.getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              final users = snapshot.data?['users'] as List? ?? [];
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final u = users[index];
                  return ListTile(
                    title: Text(u['name'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(u['role'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () async {
                        await _apiService.deleteUser(u['id']);
                        Navigator.pop(context);
                        _showUsersDialog();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // PANNEAU HISTORIQUE UNIFORMISÉ
  void _showMeasurementsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
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
                const Text("HISTORIQUE DES MESURES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const Divider(color: Colors.white10, height: 30),
                Expanded(
                  child: _recentMeasures.isEmpty 
                    ? const Center(child: Text("Aucune donnée", style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _recentMeasures.length,
                        itemBuilder: (context, index) {
                          final m = _recentMeasures[index];
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
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PANNEAU CALCUL UNIFORMISÉ
  void _showCalculateDialog() {
    dynamic selectedTankId;
    final depthController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(color: Color(0xFF1A237E), borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: StatefulBuilder(
              builder: (context, setModalState) => Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 28, right: 28, top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                    const SizedBox(height: 25),
                    const Text("Calcul Rapide Joshua", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 25),
                    DropdownButtonFormField<dynamic>(
                      dropdownColor: const Color(0xFF1A237E),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Cuve", Icons.gas_meter),
                      items: _tanks.map((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'], style: const TextStyle(color: Colors.white)))).toList(),
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
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: selectedTankId == null ? null : () async {
                        await _apiService.calculateVolume(selectedTankId, double.parse(depthController.text));
                        await _fetchTanks();
                        Navigator.pop(context);
                      },
                      child: const Text("CALCULER", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    double totalVol = _tanks.fold(0.0, (sum, t) => sum + ((t['current_volume'] as num?)?.toDouble() ?? 0.0));
    return ProtectedPage(
      allowedRoles: const ['superAdmin'],
      child: Scaffold(
        body: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF000000)])),
          child: SafeArea(
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('NexaTank System', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('SuperAdmin: ${_adminName ?? "Joshua"} 👑', style: TextStyle(fontSize: 11, color: Colors.blueAccent.withOpacity(0.8), fontWeight: FontWeight.bold)),
                      ]),
                      IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20), onPressed: () async {
                        await _storageService.clearSession();
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
                      }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    _buildActionButton("COMPTES", Icons.people_alt_rounded, _showUsersDialog),
                    const SizedBox(width: 10),
                    _buildActionButton("MESURES", Icons.history_edu_rounded, _showMeasurementsList),
                    const SizedBox(width: 10),
                    _buildActionButton("CALCUL", Icons.calculate_rounded, _showCalculateDialog),
                  ]),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _buildCommandStat("STATION", "ACTIVE", Icons.online_prediction, Colors.greenAccent),
                      _buildCommandStat("STOCK TOTAL", "${totalVol.toInt()} L", Icons.analytics, Colors.blueAccent),
                    ]),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
                    itemCount: _tanks.length,
                    itemBuilder: (context, index) {
                      final t = _tanks[index];
                      return TankWidget(name: t['name'], capacity: (t['capacity'] as num).toDouble(), type: t['type'], currentVolume: (t['current_volume'] as num).toDouble());
                    },
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

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return Expanded(child: InkWell(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Column(children: [Icon(icon, color: Colors.blueAccent, size: 18), const SizedBox(height: 4), Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))]),
    )));
  }

  Widget _buildCommandStat(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      Text(label, style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
    ]);
  }
}
