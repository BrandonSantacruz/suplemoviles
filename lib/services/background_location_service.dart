import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BackgroundLocationService {
  static final BackgroundLocationService _instance = 
      BackgroundLocationService._internal();
  
  factory BackgroundLocationService() {
    return _instance;
  }
  
  BackgroundLocationService._internal();
  
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isRunning = false;
  final supabase = Supabase.instance.client;

  /// Inicia el rastreo de ubicación en segundo plano
  Future<void> iniciarRastreoFondo(String usuarioId) async {
    if (_isRunning) return;
    
    _isRunning = true;
    print('🔴 Iniciando rastreo de fondo para: $usuarioId');
    
    try {
      // Configurar permisos para siempre (background)
      LocationPermission permiso = await Geolocator.requestPermission();
      
      if (permiso == LocationPermission.deniedForever) {
        print('❌ Permisos negados permanentemente');
        return;
      }
      
      if (permiso != LocationPermission.whileInUse && 
          permiso != LocationPermission.always) {
        print('❌ Permisos insuficientes');
        return;
      }
      
      // Verificar servicio de ubicación
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        print('❌ Servicio de ubicación no habilitado');
        return;
      }
      
      // Configurar opciones de precisión alta y actualización frecuente
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
        timeLimit: Duration(seconds: 5), // O cada 5 segundos
      );
      
      // Escuchar cambios de posición continuamente
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _enviarUbicacionAlServidor(usuarioId, position);
        },
        onError: (error) {
          print('❌ Error en stream de ubicación: $error');
        },
      );
      
      print('✅ Rastreo de fondo iniciado correctamente');
      
    } catch (e) {
      print('❌ Error al iniciar rastreo de fondo: $e');
      _isRunning = false;
    }
  }

  /// Envía la ubicación al servidor
  Future<void> _enviarUbicacionAlServidor(
    String usuarioId, 
    Position position
  ) async {
    try {
      print('📍 Actualizando ubicación: ${position.latitude}, ${position.longitude}');
      
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
      
      print('✅ Ubicación actualizada en BD');
      
    } catch (e) {
      print('❌ Error al enviar ubicación: $e');
    }
  }

  /// Detiene el rastreo de fondo
  Future<void> detenerRastreoFondo() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
    }
    _isRunning = false;
    print('🛑 Rastreo de fondo detenido');
  }

  /// Obtiene el estado actual del rastreo
  bool get estaRastreando => _isRunning;
}
