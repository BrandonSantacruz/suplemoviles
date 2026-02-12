import 'dart:convert';
import 'package:http/http.dart' as http;
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
    final MapController _mapController = MapController();
  List<Map<String, dynamic>> _admins = [];
  List<Map<String, dynamic>> _corredores = [];
  List<Map<String, dynamic>> _ubicacionesCorredores = [];
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String _rolCrear = 'corredor';
  bool _yaHizoPanInicial = false;

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
    _cargarUbicacionesEnTiempoReal();
  }

  Future<void> _cargarUbicacionesEnTiempoReal() async {
    try {
      final datos = await Supabase.instance.client
          .from('ubicaciones_corredores')
          .select()
          .order('timestamp', ascending: false)
          .limit(100);
      
      print('DEBUG: Ubicaciones cargadas: ${datos.length}');
      if (mounted) {
        setState(() {
          _ubicacionesCorredores = List<Map<String, dynamic>>.from(datos);
        });
      }
      // Actualizar cada 3 segundos
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), _cargarUbicacionesEnTiempoReal);
      }
    } catch (e) {
      print('DEBUG ERROR: Error al cargar ubicaciones: $e');
      // Reintentar en 3 segundos
      if (mounted) {
        Future.delayed(const Duration(seconds: 3), _cargarUbicacionesEnTiempoReal);
      }
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
      // 1. Buscar el user_id de auth en la tabla usuarios
      final res = await Supabase.instance.client
          .from('usuarios')
          .select('id')
          .eq('id', usuarioId)
          .single();
      final userIdAuth = res['id'];
      if (userIdAuth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró el user_id de auth para este usuario.')),
        );
        return;
      }

      // 2. Eliminar de la tabla usuarios
      await Supabase.instance.client.from('usuarios').delete().eq('id', usuarioId);

      // 3. Llamar a la Edge Function para eliminar de Auth
      final response = await http.post(
        Uri.parse('https://TU-PROYECTO.functions.supabase.co/delete-user'), // Reemplaza TU-PROYECTO
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \\${Supabase.instance.client.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({'user_id': userIdAuth}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado completamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar de auth: \\${response.body}')),
        );
      }
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
        const SnackBar(content: Text('Rol cambiado con éxito')),
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
      setState(() {}); // Forzar refresco inmediato
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

  Future<void> _cerrarSesion(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pan automático solo la primera vez
    if (!_yaHizoPanInicial && _ubicacionesCorredores.isNotEmpty) {
      final lat = double.tryParse(_ubicacionesCorredores.first['latitud'].toString()) ?? -0.278233;
      final lng = double.tryParse(_ubicacionesCorredores.first['longitud'].toString()) ?? -78.496129;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(lat, lng), 15);
      });
      _yaHizoPanInicial = true;
    }
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey.shade800,
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('Panel Superadmin', style: TextStyle(color: Colors.white)),
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
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _ubicacionesCorredores.isNotEmpty
                    ? LatLng(
                        double.tryParse(_ubicacionesCorredores.first['latitud'].toString()) ?? -0.278233,
                        double.tryParse(_ubicacionesCorredores.first['longitud'].toString()) ?? -78.496129,
                      )
                    : const LatLng(-0.278233, -78.496129),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                ),
                if (_ubicacionesCorredores.isNotEmpty)
                  MarkerLayer(
                    markers: _ubicacionesCorredores.asMap().entries.map((entry) {
                      final i = entry.key;
                      final corredor = entry.value;
                      try {
                        final latitud = double.parse(corredor['latitud'].toString());
                        final longitud = double.parse(corredor['longitud'].toString());
                        final usuarioId = corredor['usuario_id']?.toString() ?? '';
                        final color = Colors.primaries[i % Colors.primaries.length];
                        return Marker(
                          point: LatLng(latitud, longitud),
                          width: 80,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                usuarioId.substring(0, usuarioId.length > 6 ? 6 : usuarioId.length),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        print('Error al procesar ubicación: $e');
                        return Marker(
                          point: const LatLng(-0.278233, -78.496129),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.error,
                            color: Colors.red,
                            size: 40,
                          ),
                        );
                      }
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
                    // Ubicaciones en tiempo real
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade900,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.amberAccent, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Corredores en línea: ${_ubicacionesCorredores.length}',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_ubicacionesCorredores.isEmpty)
                            const Center(
                              child: Text(
                                'Sin ubicaciones registradas',
                                style: TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            )
                          else
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _ubicacionesCorredores.length,
                                itemBuilder: (context, index) {
                                  final loc = _ubicacionesCorredores[index];
                                  final lat = double.tryParse(loc['latitud'].toString()) ?? 0;
                                  final lng = double.tryParse(loc['longitud'].toString()) ?? 0;
                                  final vel = double.tryParse(loc['velocidad'].toString()) ?? 0;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '📍 Lat: ${lat.toStringAsFixed(6)}',
                                          style: const TextStyle(color: Colors.lightBlue, fontSize: 10, fontFamily: 'monospace'),
                                        ),
                                        Text(
                                          '📍 Lng: ${lng.toStringAsFixed(6)}',
                                          style: const TextStyle(color: Colors.lightBlue, fontSize: 10, fontFamily: 'monospace'),
                                        ),
                                        Text(
                                          '⚡ Vel: ${vel.toStringAsFixed(2)} km/h',
                                          style: const TextStyle(color: Colors.yellow, fontSize: 9),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Corredores
                    const Text(
                      '👤 Corredores:',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 60,
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
                                  title: Text(corredor['email'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  subtitle: Text(activo ? 'Activo' : 'Inactivo', style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 9)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          activo ? Icons.toggle_on : Icons.toggle_off,
                                          color: activo ? Colors.green : Colors.red,
                                          size: 28,
                                        ),
                                        tooltip: activo ? 'Desactivar' : 'Activar',
                                        onPressed: () => _cambiarEstadoUsuario(corredor['id'], !activo),
                                      ),
                                      PopupMenuButton<String>(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                          const PopupMenuItem(value: 'cambiar_rol', child: Text('Cambiar a Admin')),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'eliminar') {
                                            _eliminarUsuario(corredor['id']);
                                          } else if (value == 'cambiar_rol') {
                                            _cambiarRol(corredor['id'], 'admin');
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Administradores
                    const Text(
                      '👨‍💼 Administradores:',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 50,
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
                                  title: Text(admin['email'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                                  subtitle: Text(activo ? 'Activo' : 'Inactivo', style: TextStyle(color: activo ? Colors.green : Colors.red, fontSize: 9)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          activo ? Icons.toggle_on : Icons.toggle_off,
                                          color: activo ? Colors.green : Colors.red,
                                          size: 28,
                                        ),
                                        tooltip: activo ? 'Desactivar' : 'Activar',
                                        onPressed: () => _cambiarEstadoUsuario(admin['id'], !activo),
                                      ),
                                      PopupMenuButton<String>(
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                                          const PopupMenuItem(value: 'cambiar_rol', child: Text('Cambiar a Corredor')),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'eliminar') {
                                            _eliminarUsuario(admin['id']);
                                          } else if (value == 'cambiar_rol') {
                                            _cambiarRol(admin['id'], 'corredor');
                                          }
                                        },
                                      ),
                                    ],
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
