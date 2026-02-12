import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/background_location_service.dart';

class PantallaCorredorTracking extends StatefulWidget {
  const PantallaCorredorTracking({super.key});

  @override
  State<PantallaCorredorTracking> createState() =>
      _PantallaCorredorTrackingState();
}

class _PantallaCorredorTrackingState extends State<PantallaCorredorTracking> {
  final backgroundLocationService = BackgroundLocationService();
  final MapController _mapController = MapController();
  late String _usuarioId;
  LatLng? _miUbicacion;
  Stream<Position>? _posicionStream;

  @override
  void initState() {
    super.initState();
    _usuarioId = Supabase.instance.client.auth.currentUser!.id;
    print('DEBUG: Usuario ID: $_usuarioId');
    _inicializarRastreoFondo();
    _iniciarEscuchaUbicacion();
  }

  Future<void> _inicializarRastreoFondo() async {
    try {
      print('DEBUG: Iniciando rastreo de fondo para usuario: $_usuarioId');
      await backgroundLocationService.iniciarRastreoFondo(_usuarioId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Rastreo iniciado - Ubicación en tiempo real activada')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _iniciarEscuchaUbicacion() async {
    try {
      // Solicitar permiso una sola vez
      LocationPermission permiso = await Geolocator.requestPermission();
      
      if (permiso == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Permisos de ubicación negados permanentemente. Actívalos en configuración.')),
          );
        }
        return;
      }
      
      if (permiso != LocationPermission.whileInUse && 
          permiso != LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Permisos insuficientes para la ubicación')),
          );
        }
        return;
      }
      
      // Verificar que el servicio está habilitado
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Activa el GPS en tu teléfono')),
          );
        }
        return;
      }
      
      // Escuchar cambios de posición en tiempo real
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar cada 10 metros
        timeLimit: Duration(seconds: 5), // O cada 5 segundos
      );
      
      _posicionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      );
      
      _posicionStream!.listen((Position pos) {
        if (mounted) {
          setState(() {
            _miUbicacion = LatLng(pos.latitude, pos.longitude);
          });
          print('DEBUG: Ubicación actualizada: ${pos.latitude}, ${pos.longitude}');
        }
      });
      
      print('DEBUG: Escucha de ubicación iniciada');
    } catch (e) {
      print('DEBUG ERROR: $e');
    }
  }

  @override
  void dispose() {
    backgroundLocationService.detenerRastreoFondo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay ubicación, mostrar mensaje
    if (_miUbicacion == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blueGrey.shade800,
          title: const Row(
            children: [
              Icon(Icons.directions_run, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('BolsaStreet - Tracking', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        backgroundColor: Colors.blueGrey.shade900,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_searching, size: 80, color: Colors.amberAccent),
              const SizedBox(height: 20),
              const Text(
                'Obteniendo tu ubicación...',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.amberAccent),
              const SizedBox(height: 20),
              const Text(
                'Asegúrate que:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ GPS está activado', style: TextStyle(color: Colors.green, fontSize: 12)),
                    Text('✅ Permisos de ubicación concedidos', style: TextStyle(color: Colors.green, fontSize: 12)),
                    Text('✅ Internet activo', style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: const Row(
          children: [
            Icon(Icons.directions_run, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('BolsaStreet - Tracking', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de ubicación
          Container(
            color: Colors.blueGrey.shade800,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tu ubicación actual',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${_miUbicacion!.latitude.toStringAsFixed(5)}, ${_miUbicacion!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Mapa
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _miUbicacion ?? const LatLng(-0.278233, -78.496129),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    if (_miUbicacion != null)
                      Marker(
                        point: _miUbicacion!,
                        width: 50,
                        height: 50,
                        child: Column(
                          children: [
                            const Icon(Icons.person_pin_circle, color: Colors.blue, size: 48),
                            const Text('TÚ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Botones de acción
          Container(
            color: Colors.blueGrey.shade800,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Confirmar Ubicación'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _mandarUbicacion,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '📡 Ubicación se actualiza automáticamente cada 5 segundos',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mandarUbicacion() async {
    if (_miUbicacion == null) return;
    try {
      print('DEBUG: Enviando ubicación: ${_miUbicacion!.latitude}, ${_miUbicacion!.longitude}');
      await Supabase.instance.client.from('ubicaciones_corredores').upsert(
        {
          'usuario_id': _usuarioId,
          'latitud': _miUbicacion!.latitude,
          'longitud': _miUbicacion!.longitude,
          'velocidad': 0.0,
          'timestamp': DateTime.now().toIso8601String(),
        },
        onConflict: 'usuario_id',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Ubicación confirmada y enviada al administrador')),
        );
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al enviar ubicación: $e')),
        );
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await backgroundLocationService.detenerRastreoFondo();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
