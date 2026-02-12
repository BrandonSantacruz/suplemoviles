import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionService {
  static final UbicacionService _instance = UbicacionService._internal();

  factory UbicacionService() {
    return _instance;
  }

  UbicacionService._internal();

  final supabase = Supabase.instance.client;
  bool _enviandoUbicacion = false;

  // Solicitar permisos de geolocalización
  Future<bool> solicitarPermisos() async {
    final permiso = await Geolocator.requestPermission();
    return permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always;
  }

  // Verificar si el servicio de ubicación está habilitado
  Future<bool> verificarServicioUbicacion() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Obtener ubicación actual
  Future<Position?> obtenerUbicacionActual() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      print('Error al obtener ubicación: $e');
      return null;
    }
  }

  // Iniciar rastreo continuo de ubicación
  Future<void> iniciarRastreo(String usuarioId) async {
    if (_enviandoUbicacion) return;
    _enviandoUbicacion = true;

    try {
      // Verificar permisos y servicio
      final tienePermiso = await solicitarPermisos();
      final servicioHabilitado = await verificarServicioUbicacion();

      if (!tienePermiso || !servicioHabilitado) {
        throw Exception('Permisos o servicio de ubicación no disponibles');
      }

      // Escuchar cambios de posición
      Geolocator.getPositionStream().listen((Position position) {
        _actualizarUbicacion(usuarioId, position);
      });
    } catch (e) {
      print('Error al iniciar rastreo: $e');
      _enviandoUbicacion = false;
    }
  }

  // Actualizar ubicación en Supabase
  Future<void> _actualizarUbicacion(String usuarioId, Position position) async {
    try {
      await supabase.from('ubicaciones_corredores').upsert(
        {
          'usuario_id': usuarioId,
          'latitud': position.latitude,
          'longitud': position.longitude,
          'velocidad': position.speed,
          'timestamp': DateTime.now().toIso8601String(),
        },
        onConflict: 'usuario_id',
      );
    } catch (e) {
      print('Error al actualizar ubicación: $e');
    }
  }

  // Obtener ubicaciones de todos los corredores
  Future<List<Map<String, dynamic>>> obtenerCorredores() async {
    try {
      final datos = await supabase
          .from('ubicaciones_corredores')
          .select('usuario_id, latitud, longitud, velocidad, timestamp')
          .gt('timestamp', DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String());

      return List<Map<String, dynamic>>.from(datos);
    } catch (e) {
      print('Error al obtener ubicaciones: $e');
      return [];
    }
  }

  // Detener rastreo
  void detenerRastreo() {
    _enviandoUbicacion = false;
  }

  // Generar link de geolocalización
  String generarLinkGeolocalizacion(double latitud, double longitud) {
    return 'https://www.openstreetmap.org/?mlat=$latitud&mlon=$longitud&zoom=15';
  }
}
