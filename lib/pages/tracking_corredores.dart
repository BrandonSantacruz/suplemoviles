import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ubicacion_service.dart';

class PantallaCorredorTracking extends StatefulWidget {
  const PantallaCorredorTracking({super.key});

  @override
  State<PantallaCorredorTracking> createState() =>
      _PantallaCorredorTrackingState();
}

class _PantallaCorredorTrackingState extends State<PantallaCorredorTracking> {
  final ubicacionService = UbicacionService();
  final MapController _mapController = MapController();
  late String _usuarioId;
  LatLng? _miUbicacion;
  Stream<Position>? _posicionStream;

  @override
  void initState() {
    super.initState();
    _usuarioId = Supabase.instance.client.auth.currentUser!.id;
    _inicializarRastreo();
    _iniciarEscuchaUbicacion();
  }

  Future<void> _inicializarRastreo() async {
    try {
      await ubicacionService.iniciarRastreo(_usuarioId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _iniciarEscuchaUbicacion() async {
    final tienePermiso = await ubicacionService.solicitarPermisos();
    final servicioHabilitado = await ubicacionService.verificarServicioUbicacion();
    if (!tienePermiso || !servicioHabilitado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activa los permisos y el GPS para usar el mapa.')),
        );
      }
      return;
    }
    _posicionStream = Geolocator.getPositionStream();
    _posicionStream!.listen((pos) {
      if (mounted) {
        setState(() {
          _miUbicacion = LatLng(pos.latitude, pos.longitude);
        });
      }
    });
  }

  @override
  void dispose() {
    ubicacionService.detenerRastreo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener ubicación propia
    // ...existing code...

    // Si no hay ubicación, mostrar mensaje
    if (_miUbicacion == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('BolsaStreet - Tracking'),
        ),
        body: const Center(
          child: Text('No se pudo obtener tu ubicación. Activa GPS y permisos.'),
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
            Text('BolsaStreet - Tracking',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Mandar ubicación'),
                onPressed: _mandarUbicacion,
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _miUbicacion ?? LatLng(-0.278233, -78.496129),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
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
                            Icon(Icons.person_pin_circle, color: Colors.blue, size: 48),
                            const Text('Tú', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                  ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación enviada al administrador')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar ubicación: $e')),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
