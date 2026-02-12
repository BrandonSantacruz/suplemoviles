import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PanelSuperAdmin extends StatefulWidget {
  const PanelSuperAdmin({super.key});

  @override
  State<PanelSuperAdmin> createState() => _PanelSuperAdminState();
}

class _PanelSuperAdminState extends State<PanelSuperAdmin> {
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _corredores = [];
  List<Map<String, dynamic>> _ubicacionesCorredores = [];
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String _rolCrear = 'corredor';

  @override
  void initState() {
    super.initState();
    print('DEBUG PANEL: Panel Superadmin inicializado');
    _cargarAdmins();
    _cargarCorredores();
    _iniciarActualizacionUbicaciones();
    print('DEBUG PANEL: Inicialización completada');
  }

  Future<void> _cargarAdmins() async {
    try {
      final datos = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('rol', 'admin');
      print('DEBUG: Admins cargados: ${datos.length}');
      if (mounted) {
        setState(() {
          _admins = List<Map<String, dynamic>>.from(datos);
        });
      }
    } catch (e) {
      print('DEBUG ERROR: Error al cargar admins: $e');
    }
  }

  Future<void> _cargarCorredores() async {
    try {
      final datos = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('rol', 'corredor');
      print('DEBUG: Corredores cargados: ${datos.length}');
      if (mounted) {
        setState(() {
          _corredores = List<Map<String, dynamic>>.from(datos);
        });
      }
    } catch (e) {
      print('DEBUG ERROR: Error al cargar corredores: $e');
    }
  }

  void _iniciarActualizacionUbicaciones() {
    Future.microtask(() => _cargarUbicacionesEnTiempoReal());
  }

  Future<void> _cargarUbicacionesEnTiempoReal() async {
    while (mounted) {
      try {
        final datos = await Supabase.instance.client
            .from('ubicaciones_corredores')
            .select()
            .gt('timestamp', DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String());
        if (mounted) {
          setState(() {
            _ubicacionesCorredores = List<Map<String, dynamic>>.from(datos);
          });
        }
      } catch (e) {
        print('DEBUG ERROR: Error al cargar ubicaciones: $e');
      }
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearUsuario() async {
    try {
      if (emailCtrl.text.isEmpty || passCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todos los campos')),
        );
        return;
      }

      final respuesta = await Supabase.instance.client.auth.signUp(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
        data: {
          'rol': _rolCrear,
        },
      );
      final usuario = respuesta.user;

      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el usuario')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_rolCrear == 'admin' ? 'Administrador' : _rolCrear == 'superadmin' ? 'Superadmin' : 'Corredor'} creado con éxito')),
      );

      emailCtrl.clear();
      passCtrl.clear();
      _cargarAdmins();
      _cargarCorredores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _eliminarUsuario(String usuarioId) async {
    try {
      await Supabase.instance.client.from('usuarios').delete().eq('id', usuarioId);
      await Supabase.instance.client.auth.admin.deleteUser(usuarioId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado')),
      );
      _cargarAdmins();
      _cargarCorredores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Future<void> _cambiarRol(String usuarioId, String nuevoRol) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'rol': nuevoRol})
          .eq('id', usuarioId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rol cambiado a $nuevoRol')),
      );
      _cargarAdmins();
      _cargarCorredores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar rol: $e')),
      );
    }
  }

  Future<void> _cambiarEstadoUsuario(String usuarioId, bool activo) async {
    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'activo': activo})
          .eq('id', usuarioId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(activo ? 'Usuario activado' : 'Usuario desactivado')),
      );
      _cargarAdmins();
      _cargarCorredores();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: const Text('Panel Superadmin'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade600,
        onPressed: _mostrarDialogoCrearUsuario,
        tooltip: 'Agregar nuevo perfil',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _ubicacionesCorredores.isEmpty
                ? FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(-0.278233, -78.496129),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                    ],
                  )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(_ubicacionesCorredores.first['latitud'] as double, _ubicacionesCorredores.first['longitud'] as double),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: _ubicacionesCorredores.map((corredor) {
                          final latitud = corredor['latitud'] as double;
                          final longitud = corredor['longitud'] as double;
                          return Marker(
                            point: LatLng(latitud, longitud),
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blueGrey.shade800,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Corredores en línea: ${_ubicacionesCorredores.length}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Corredores:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 80,
                      child: _corredores.isEmpty
                          ? const Center(child: Text('No hay corredores', style: TextStyle(color: Colors.white70, fontSize: 12)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _corredores.length,
                              itemBuilder: (context, index) {
                                final corredor = _corredores[index];
                                final activo = corredor['activo'] as bool? ?? true;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.directions_run, color: activo ? Colors.green : Colors.red, size: 18),
                                  title: Text(corredor['email'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  subtitle: Text(activo ? 'Activo' : 'Inactivo', style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 10)),
                                  trailing: PopupMenuButton<String>(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                      const PopupMenuItem(value: 'cambiar_rol', child: Text('Cambiar a Admin')),
                                      if (activo)
                                        const PopupMenuItem(value: 'desactivar', child: Text('Desactivar'))
                                      else
                                        const PopupMenuItem(value: 'activar', child: Text('Activar')),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'eliminar') {
                                        _eliminarUsuario(corredor['id']);
                                      } else if (value == 'cambiar_rol') {
                                        _cambiarRol(corredor['id'], 'admin');
                                      } else if (value == 'desactivar') {
                                        _cambiarEstadoUsuario(corredor['id'], false);
                                      } else if (value == 'activar') {
                                        _cambiarEstadoUsuario(corredor['id'], true);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Administradores:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(
                      height: 60,
                      child: _admins.isEmpty
                          ? const Center(child: Text('No hay administradores', style: TextStyle(color: Colors.white70, fontSize: 12)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _admins.length,
                              itemBuilder: (context, index) {
                                final admin = _admins[index];
                                final activo = admin['activo'] as bool? ?? true;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(Icons.admin_panel_settings, color: activo ? Colors.blue : Colors.red, size: 18),
                                  title: Text(admin['email'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  subtitle: Text(activo ? 'Activo' : 'Inactivo', style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 10)),
                                  trailing: PopupMenuButton<String>(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                      const PopupMenuItem(value: 'cambiar_rol', child: Text('Cambiar a Corredor')),
                                      if (activo)
                                        const PopupMenuItem(value: 'desactivar', child: Text('Desactivar'))
                                      else
                                        const PopupMenuItem(value: 'activar', child: Text('Activar')),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'eliminar') {
                                        _eliminarUsuario(admin['id']);
                                      } else if (value == 'cambiar_rol') {
                                        _cambiarRol(admin['id'], 'corredor');
                                      } else if (value == 'desactivar') {
                                        _cambiarEstadoUsuario(admin['id'], false);
                                      } else if (value == 'activar') {
                                        _cambiarEstadoUsuario(admin['id'], true);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCrearUsuario() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.blueGrey.shade800,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Crear Nuevo Perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.blueGrey.shade900,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.blueGrey.shade900,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _rolCrear,
                  dropdownColor: Colors.blueGrey.shade900,
                  items: [
                    const DropdownMenuItem(
                      value: 'corredor',
                      child: Text('Corredor', style: TextStyle(color: Colors.white)),
                    ),
                    const DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrador', style: TextStyle(color: Colors.white)),
                    ),
                    const DropdownMenuItem(
                      value: 'superadmin',
                      child: Text('Superadmin', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                  onChanged: (valor) => setState(() => _rolCrear = valor!),
                  decoration: InputDecoration(
                    labelText: 'Selecciona un rol',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.blueGrey.shade900,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _crearUsuario();
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Crear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
