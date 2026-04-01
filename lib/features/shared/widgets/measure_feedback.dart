import 'package:flutter/material.dart';

Future<void> showMeasureResult(BuildContext context, {required bool success, String? title, String? message, Map<String, dynamic>? summary}) {
  final Color bg = const Color(0xFF002B26);
  title ??= success ? 'Succès' : 'Erreur';
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        Icon(success ? Icons.check_circle_outline : Icons.error_outline, color: success ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 10),
        Text(title!, style: const TextStyle(color: Colors.white)),
      ]),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            if (message != null) Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            if (summary != null) ...[
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              if (summary['tank'] != null) _buildSummaryRow('Cuve', summary['tank'].toString()),
              if (summary['depth'] != null) _buildSummaryRow('Profondeur', '${summary['depth']} cm'),
              if (summary['volume'] != null) _buildSummaryRow('Volume', '${summary['volume']} L'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('OK', style: TextStyle(color: success ? Colors.greenAccent : Colors.white70)),
        ),
      ],
    ),
  );
}

Widget _buildSummaryRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
