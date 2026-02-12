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

class _PantallaCorredorTrackingState
    extends State<PantallaCorredorTracking> {
  final backgroundLocationService = BackgroundLocationService();
  final MapController _mapController = MapController();

  late String _usuarioId;
  LatLng? _miUbicacion;
  Stream<Position>? _posicionStream;

  @override
  void initState() {
    super.initState();
    _usuarioId = Supabase.instance.client.auth.currentUser!.id;
    _inicializarRastreoFondo();
    _iniciarEscuchaUbicacion();
  }

  Future<void> _inicializarRastreoFondo() async {
    try {
      await backgroundLocationService.iniciarRastreoFondo(_usuarioId);
    } catch (_) {}
  }

  void _iniciarEscuchaUbicacion() async {
    LocationPermission permiso = await Geolocator.requestPermission();

    if (permiso == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _posicionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings);

    _posicionStream!.listen((Position pos) {
      if (!mounted) return;

      setState(() {
        _miUbicacion = LatLng(pos.latitude, pos.longitude);
      });

      _mandarUbicacion(); // 🔥 Ahora envía automático
    });
  }

  @override
  void dispose() {
    backgroundLocationService.detenerRastreoFondo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_miUbicacion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Corredor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _miUbicacion!,
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
              Marker(
                point: _miUbicacion!,
                width: 40,
                height: 40,
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.blue, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _mandarUbicacion() async {
    if (_miUbicacion == null) return;

    await Supabase.instance.client
        .from('ubicaciones_corredores')
        .upsert({
      'usuario_id': _usuarioId,
      'latitud': _miUbicacion!.latitude,
      'longitud': _miUbicacion!.longitude,
      'velocidad': 0,
      'timestamp': DateTime.now().toIso8601String(),
    }, onConflict: 'usuario_id');
  }

  Future<void> _cerrarSesion() async {
    await backgroundLocationService.detenerRastreoFondo();
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/');
  }
}
