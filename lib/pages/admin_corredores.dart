import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PanelAdministracionCorredores extends StatefulWidget {
  const PanelAdministracionCorredores({super.key});

  @override
  State<PanelAdministracionCorredores> createState() =>
      _PanelAdministracionCorredoresState();
}

class _PanelAdministracionCorredoresState
    extends State<PanelAdministracionCorredores> {

  List<Map<String, dynamic>> _corredores = [];
  List<Map<String, dynamic>> _ubicaciones = [];
  Map<String, dynamic>? _corredorSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarCorredores();
    _escucharUbicacionesRealtime();
  }

  Future<void> _cargarCorredores() async {
    final datos = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('rol', 'corredor');

    setState(() {
      _corredores = List<Map<String, dynamic>>.from(datos);
    });
  }

  void _escucharUbicacionesRealtime() {
    Supabase.instance.client
        .from('ubicaciones_corredores')
        .stream(primaryKey: ['id'])
        .listen((data) {
      setState(() {
        _ubicaciones = data;
      });
    });
  }

  Future<void> _eliminarCorredor(String usuarioId) async {
    try {
      // 🔥 Llamada a Edge Function
      await Supabase.instance.client.functions.invoke(
        'delete-user',
        body: {'userId': usuarioId},
      );

      await _cargarCorredores();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Usuario eliminado completamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Admin')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _corredores.length,
              itemBuilder: (context, index) {
                final usuario = _corredores[index];
                return ListTile(
                  title: Text(usuario['email']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _eliminarCorredor(usuario['id']),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Expanded(child: _mapa()),
        ],
      ),
    );
  }

  Widget _mapa() {
    if (_ubicaciones.isEmpty) {
      return const Center(child: Text('Sin ubicaciones en vivo'));
    }

    final markers = _ubicaciones.map((u) {
      return Marker(
        point: LatLng(u['latitud'], u['longitud']),
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on,
            color: Colors.red, size: 40),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter:
            LatLng(_ubicaciones.first['latitud'], _ubicaciones.first['longitud']),
        initialZoom: 14,
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
          subdomains: const ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}
