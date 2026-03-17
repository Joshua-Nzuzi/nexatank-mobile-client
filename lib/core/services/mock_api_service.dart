import 'dart:async';
import 'dart:math';

class MockApiService {
  // --- Singleton Pattern ---
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService() {
    return _instance;
  }
  MockApiService._internal();
  // --- Fin du Singleton Pattern ---

  // Base de données simulée pour les utilisateurs.
  // Fait maintenant partie de l'instance unique du singleton.
  final List<Map<String, dynamic>> _users = [];

  // INSCRIPTION + GÉNÉRATION CODE UNIQUE
  Future<Map<String, dynamic>> register(String name, String role, String phone) async {
    await Future.delayed(const Duration(seconds: 1));

    // Vérifier si l'utilisateur existe déjà
    if (_users.any((user) => user['phone'] == phone)) {
      return {
        "success": false,
        "message": "Un utilisateur avec ce numéro de téléphone existe déjà."
      };
    }

    // Créer un nouvel utilisateur
    final code = Random().nextInt(9000) + 1000; // code 1000-9999
    _users.add({
      'id': _users.length + 1,
      'name': name,
      'role': role,
      'phone': phone,
      'code': code,
    });

    return {
      "success": true,
      "code": code,
      "message": "Inscription réussie pour $role"
    };
  }

  // LOGIN PAR TÉLÉPHONE + CODE
  Future<Map<String, dynamic>> loginWithCode(String phone, int code) async {
    await Future.delayed(const Duration(seconds: 1));

    for (final user in _users) {
      if (user['phone'] == phone && user['code'] == code) {
        return {
          "success": true,
          "user": {
            "id": user['id'],
            "name": user['name'],
            "role": user['role']
          }
        };
      }
    }

    return {"success": false, "message": "Téléphone ou code incorrect"};
  }

  // RÉGÉNÉRER CODE
  Future<Map<String, dynamic>> regenerateCode(String phone) async {
    await Future.delayed(const Duration(seconds: 1));

    final userIndex = _users.indexWhere((user) => user['phone'] == phone);

    if (userIndex != -1) {
      final newCode = Random().nextInt(9000) + 1000;
      _users[userIndex]['code'] = newCode;

      return {
        "success": true,
        "code": newCode,
        "message": "Nouveau code généré"
      };
    }

    return {
      "success": false,
      "message": "Aucun utilisateur trouvé avec ce numéro de téléphone."
    };
  }
}
