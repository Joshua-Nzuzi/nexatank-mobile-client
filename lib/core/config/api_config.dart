import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // REMPLACEZ CETTE URL PAR VOTRE VRAIE URL RAILWAY
  static const String _productionUrl = "https://votre-backend.up.railway.app"; 

  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000"; // Pour le test web local
    } else {
      // Pour le mobile, on utilise désormais l'URL du Cloud
      return _productionUrl;
    }
  }
}
