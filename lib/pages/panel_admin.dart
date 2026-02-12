import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class PanelAdmin extends StatefulWidget {
  const PanelAdmin({super.key});

  @override
  State<PanelAdmin> createState() => _PanelAdminState();
}

class _PanelAdminState extends State<PanelAdmin> {
  List<LatLng> _ubicaciones = [];

  @override
  void initState() {
    super.initState();
    obtenerUbicaciones();
  }

  Future<void> obtenerUbicaciones() async {
    final datos = await Supabase.instance.client
        .from('ubicaciones')
        .select('lat, lng');

    setState(() {
      _ubicaciones = datos
          .map<LatLng>((p) => LatLng(p['lat'] as double, p['lng'] as double))
          .toList();
    });
  }

  double calcularArea(List<LatLng> puntos) {
    double area = 0;
    for (int i = 0; i < puntos.length; i++) {
      final j = (i + 1) % puntos.length;
      area += puntos[i].latitude * puntos[j].longitude;
      area -= puntos[j].latitude * puntos[i].longitude;
    }
    return (area.abs() / 2) * 111000 * 111000;
  }
  Future<void> trazarTerreno() async {
    if (_ubicaciones.length < 3) return;

    final area = calcularArea(_ubicaciones);
    try {
      final conteo = await Supabase.instance.client
          .from('terrenos_trazados')
          .select('id')
          .count(CountOption.exact);

      final total = conteo.count ?? 0;
      final nuevoNombre = 'Terreno ${total + 1}';

      await Supabase.instance.client.from('terrenos_trazados').insert({
        'nombre': nuevoNombre,
        'puntos': jsonEncode(
          _ubicaciones.map((e) => {'lat': e.latitude, 'lng': e.longitude}).toList(),
        ),
        'area': area,
        'fecha': DateTime.now().toIso8601String(),
      });

      await Supabase.instance.client
          .from('ubicaciones')
          .delete()
          .not('id', 'is', null);

      setState(() {
        _ubicaciones.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Terreno trazado como "$nuevoNombre". Revise los terrenos guardados.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al trazar el terreno. Inténtalo de nuevo.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }


  Future<void> _cerrarSesion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Panel Administrador', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Cerrar sesión',
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _ubicaciones.isNotEmpty
                    ? _ubicaciones.first
                    : const LatLng(-0.278233, -78.496129),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: _ubicaciones
                      .map((e) => Marker(
                            point: e,
                            width: 30,
                            height: 30,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 30),
                          ))
                      .toList(),
                ),
                if (_ubicaciones.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _ubicaciones,
                        color: Colors.green.withOpacity(0.3),
                        borderStrokeWidth: 3,
                        borderColor: Colors.greenAccent,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _ubicaciones.length >= 3 ? trazarTerreno : null,
              icon: const Icon(Icons.edit_location_alt_outlined, color: Colors.white),
              label: const Text(
                'Trazar Terreno',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
