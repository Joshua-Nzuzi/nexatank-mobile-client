import 'package:flutter/material.dart';

class TankWidget extends StatelessWidget {
  final String name;
  final double capacity;
  final String type;
  final double currentVolume;

  const TankWidget({
    super.key,
    required this.name,
    required this.capacity,
    required this.type,
    required this.currentVolume,
  });

  @override
  Widget build(BuildContext context) {
    final double fillPercent = capacity > 0 ? (currentVolume / capacity).clamp(0.0, 1.0) : 0.0;

    Color statusColor;
    if (fillPercent >= 0.6) {
      statusColor = const Color(0xFF44C28D); // green
    } else if (fillPercent >= 0.4) {
      statusColor = const Color(0xFFF39C12); // orange
    } else {
      statusColor = const Color(0xFFDC3545); // red
    }

    final bgColor = const Color(0xFF0E0F10);
    final cardBorder = statusColor.withOpacity(0.18);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Capacité max: ${capacity.toInt()} L',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Volume actuel: ${currentVolume.toInt()} L',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fillPercent,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(fillPercent * 100).toInt()}%',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
