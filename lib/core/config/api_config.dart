import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // URL officielle de production sur Railway
  static const String _productionUrl = "https://nexa-backend-production-82d7.up.railway.app"; 

  static String get baseUrl {
    if (kIsWeb) {
      // Pour le test web local ou mobile via IP locale (si besoin de repasser en local)
      // return "http://10.221.227.226:3000"; 
      return "http://localhost:3000"; 
    } else {
      // Pour le mobile, on utilise désormais l'URL du Cloud Railway
      return _productionUrl;
    }
  }
}
