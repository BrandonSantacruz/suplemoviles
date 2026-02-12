import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final supabase = Supabase.instance.client;

  static Future<bool> enviarMiUbicacion(double lat, double lng) async {
    try {
      await supabase.from('ubicaciones').insert({
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toIso8601String()
      });
      return true;
    } catch (e) {
      print('Error al enviar ubicación: $e');
      return false;
    }
  }

  static Future<void> enviarUbicacionTiempoReal(double lat, double lng) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await supabase.from('temporal').upsert({
        'id': user.id,           // importante: asegura fila única por usuario
        'email': user.email,
        'lat': lat,
        'lng': lng,
        'fecha': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error al enviar ubicación en tiempo real: $e');
    }
  }

  static void escucharUbicaciones(Function(String, LatLng) callback) {
    supabase.from('ubicaciones')
      .stream(primaryKey: ['id'])
      .listen((data) {
        for (final item in data) {
          final lat = item['lat'];
          final lng = item['lng'];

          if (lat != null && lng != null) {
            callback('desconocido', LatLng(lat, lng)); 
          }
        }
      });
  }
}
