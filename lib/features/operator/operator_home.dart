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
  bool _showHistory = false;
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
      _useFallback();
    }
  }

  void _useFallback() {
    setState(() {
      _tanks = [
        { "id": 1, "name": "Sc1", "capacity": 10000.0, "type": "Essence", "current_volume": 10000.0 },
        { "id": 2, "name": "Sc2", "capacity": 22000.0, "type": "Essence", "current_volume": 22000.0 },
        { "id": 3, "name": "Sc3", "capacity": 44000.0, "type": "Essence", "current_volume": 44000.0 },
        { "id": 4, "name": "Go1", "capacity": 28000.0, "type": "Gazole", "current_volume": 28000.0 },
        { "id": 5, "name": "Go2", "capacity": 16000.0, "type": "Gazole", "current_volume": 16000.0 }
      ];
      _isLoading = false;
    });
  }

  void _showGetVolumeDialog() {
    dynamic selectedTankId;
    final depthController = TextEditingController();
    bool isCalculating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                left: 28, right: 28, top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 25),
                  const Text("Nouvelle Mesure", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 25),
                  
                  DropdownButtonFormField<dynamic>(
                    dropdownColor: const Color(0xFF1A237E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Choisir la cuve", Icons.gas_meter_outlined),
                    items: _tanks.map((tank) => DropdownMenuItem(value: tank['id'], child: Text(tank['name'], style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (val) => setModalState(() => selectedTankId = val),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: depthController,
                    enabled: selectedTankId != null,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                    decoration: _inputDecoration("Profondeur (cm)", Icons.straighten_rounded),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: (isCalculating || selectedTankId == null) ? null : () async {
                        if (depthController.text.isEmpty) return;
                        setModalState(() => isCalculating = true);
                        final depth = double.tryParse(depthController.text);
                        final response = await _apiService.calculateVolume(selectedTankId, depth!);
                        if (response['success'] == true) {
                          await _fetchTanks(); 
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Volume mis à jour !"), behavior: SnackBarBehavior.floating));
                        } else {
                          setModalState(() => isCalculating = false);
                        }
                      },
                      child: isCalculating ? const CircularProgressIndicator(color: Colors.white) : const Text("VALIDER LA MESURE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
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
            child: _isLoading ? const Center(child: CircularProgressIndicator(color: Colors.white)) : Column(
              children: [
                // Header Premium
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('NexaTank', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          if (_userName != null) Text('Pompiste: $_userName', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24), color: Colors.white.withOpacity(0.05)),
                        child: const Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ],
                  ),
                ),
                
                const Divider(color: Colors.white10, height: 1),

                // Stats Glassmorphism
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      _buildMiniStat("ESSENCE", totalEssence, Colors.redAccent),
                      const SizedBox(width: 12),
                      _buildMiniStat("GAZOLE", totalGazole, Colors.amber),
                    ],
                  ),
                ),

                // Header section avec historique toggle
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station_rounded, color: Colors.white70, size: 22),
                      const SizedBox(width: 10),
                      const Text("État des Cuves", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Spacer(),
                      IconButton(
                        icon: Icon(_showHistory ? Icons.history_toggle_off_rounded : Icons.history_rounded, 
                             color: _showHistory ? Colors.blueAccent : Colors.white38, size: 22),
                        onPressed: () => setState(() => _showHistory = !_showHistory),
                      ),
                      IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 22), onPressed: _fetchTanks),
                    ],
                  ),
                ),

                // Historique Glass
                if (_showHistory && _recentMeasures.isNotEmpty)
                  Container(
                    height: 85,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentMeasures.length,
                      itemBuilder: (context, index) {
                        final m = _recentMeasures[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(m['tank'] ?? "---", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                                  Text("${m['volume'] ?? 0} L", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                  Text("par ${m['user'] ?? '---'}", style: const TextStyle(fontSize: 8, color: Colors.white38), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchTanks,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      itemCount: _tanks.length,
                      itemBuilder: (context, index) {
                        final tank = _tanks[index];
                        return TankWidget(
                          name: tank['name'],
                          capacity: (tank['capacity'] as num).toDouble(),
                          type: tank['type'],
                          currentVolume: (tank['current_volume'] as num).toDouble(),
                        );
                      },
                    ),
                  ),
                ),

                // Actions Footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TextButton.icon(
                          onPressed: _showGetVolumeDialog,
                          icon: const Icon(Icons.add_chart_rounded, color: Colors.blueAccent),
                          label: const Text("NOUVELLE MESURE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () async {
                          await _storageService.clearSession();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LandingPage()), (route) => false);
                        },
                        child: Text("Déconnexion", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ),
                      const Text('powered by JoshuaDev', style: TextStyle(fontSize: 10, color: Colors.white24)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double volume, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                Text("${volume.toInt()} L", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
