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
  // ...existing code...
  List<Map<String, dynamic>> _ubicacionesCorredores = [];
  Map<String, dynamic>? _corredorSeleccionado;
  bool _cargando = true;
  // String _rolUsuario = 'corredor'; // Eliminada porque no se usa

  @override
  void initState() {
    super.initState();
    _cargarRolUsuario();
    _cargarCorredores();
    // ...existing code...
    _cargarUbicacionesEnTiempoReal();
  }

  Future<void> _cargarRolUsuario() async {
    // Variable _rolUsuario eliminada, función vacía
    // Si necesitas el rol, usa la lógica directamente en otro método
    return;
  }

  Future<void> _cargarCorredores() async {
    try {
      final datos = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('rol', 'corredor');
      setState(() {
        _corredores = List<Map<String, dynamic>>.from(datos);
        _cargando = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar corredores: $e')),
      );
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _cargarUbicacionesEnTiempoReal() async {
    while (mounted) {
      try {
        final datos = await Supabase.instance.client
            .from('ubicaciones_corredores')
            .select()
            .gt('timestamp', DateTime.now()
                .subtract(const Duration(minutes: 5))
                .toIso8601String());
        setState(() {
          _ubicacionesCorredores = List<Map<String, dynamic>>.from(datos);
        });
      } catch (e) {
        print('Error al cargar ubicaciones: $e');
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _desactivarCorredor(String usuarioId) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'activo': false})
          .eq('id', usuarioId);

      await _cargarCorredores();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Corredor desactivado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  Future<void> _eliminarCorredor(String usuarioId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Está seguro que desea eliminar este corredor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await Supabase.instance.client.auth.admin.deleteUser(usuarioId);
        await _cargarCorredores();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Corredor eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int tabCount = 2;
    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.blueGrey.shade800,
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('Administración de Corredores',
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
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Gestionar Corredores'),
              const Tab(text: 'Tracking en Vivo'),
            ],
            labelColor: Colors.amberAccent,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Gestionar Corredores
            _cargando
                ? const Center(child: CircularProgressIndicator())
                : _construirListaUsuarios(_corredores, 'corredor'),
            // Tab 2: Tracking en Vivo (selección de corredor)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Selecciona corredor'),
                    value: _corredorSeleccionado?['usuario_id'],
                    items: _ubicacionesCorredores.map((c) {
                      final corredor = _corredores.firstWhere(
                        (corr) => corr['id'] == c['usuario_id'],
                        orElse: () => <String, dynamic>{},
                      );
                      final correo = (corredor.isNotEmpty && corredor['email'] != null)
                          ? corredor['email']
                          : c['usuario_id'].toString().substring(0, 8);
                      return DropdownMenuItem<String>(
                        value: c['usuario_id'].toString(),
                        child: Text(correo),
                      );
                    }).toList(),
                    onChanged: (id) {
                      setState(() {
                        _corredorSeleccionado = _ubicacionesCorredores.firstWhere((c) => c['usuario_id'] == id);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _construirMapaCorredorSeleccionado(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirListaUsuarios(List<Map<String, dynamic>> usuarios, String rol) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final activo = usuario['activo'] as bool? ?? true;
        return Card(
          color: Colors.blueGrey.shade800,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              rol == 'corredor' ? Icons.person : (rol == 'admin' ? Icons.admin_panel_settings : Icons.star),
              color: activo ? Colors.green : Colors.red,
            ),
            title: Text(
              usuario['email'] as String,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              activo ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: activo ? Colors.green : Colors.red,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'desactivar') {
                  await _desactivarCorredor(usuario['id']);
                } else if (value == 'eliminar') {
                  await _eliminarCorredor(usuario['id']);
                }
              },
              itemBuilder: (context) => [
                if (activo)
                  PopupMenuItem(
                    value: 'desactivar',
                    child: Row(
                      children: const [
                        Icon(Icons.block, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Desactivar'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: const [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirMapaCorredorSeleccionado() {
    if (_corredorSeleccionado == null) {
      return const Center(child: Text('Selecciona un corredor para ver su ubicación'));
    }
    final latitud = _corredorSeleccionado!['latitud'] as double;
    final longitud = _corredorSeleccionado!['longitud'] as double;
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(latitud, longitud),
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
              point: LatLng(latitud, longitud),
              width: 40,
              height: 40,
              child: Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
