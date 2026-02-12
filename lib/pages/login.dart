import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro.dart';
// import 'tracking_corredores.dart';
// import 'admin_corredores.dart';

class IniciarSesion extends StatefulWidget {
  @override
  State<IniciarSesion> createState() => _IniciarSesionState();
}

class _IniciarSesionState extends State<IniciarSesion> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool mostrarPassword = false;

  Future<void> _login() async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
      final usuario = Supabase.instance.client.auth.currentUser;
      if (usuario == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos.')),
        );
        return;
      }
      // Consultar si está activo
      final datos = await Supabase.instance.client
          .from('usuarios')
          .select('activo')
          .eq('id', usuario.id)
          .single();
      final activo = datos['activo'] as bool? ?? true;
      if (!activo) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu cuenta está inactiva. Comunícate con el superadmin.')),
        );
        return;
      }
      // Si está activo, navegar normalmente
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login fallido: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _verificarActivoAlIniciar();
  }

  Future<void> _verificarActivoAlIniciar() async {
    final usuario = Supabase.instance.client.auth.currentUser;
    if (usuario != null) {
      final datos = await Supabase.instance.client
          .from('usuarios')
          .select('activo')
          .eq('id', usuario.id)
          .single();
      final activo = datos['activo'] as bool? ?? true;
      if (!activo) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu cuenta está inactiva. Comunícate con el superadmin.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estiloInput = InputDecoration(
      filled: true,
      fillColor: Colors.blueGrey.shade900,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(color: Colors.white70),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: Colors.lightBlueAccent),
                const SizedBox(height: 20),
                Text(
                  'Iniciar Sesión',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: estiloInput.copyWith(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: !mostrarPassword,
                  decoration: estiloInput.copyWith(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                        mostrarPassword ? Icons.visibility : Icons.visibility_off, 
                        color: Colors.white54,
                      ),
                      onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  onPressed: _login,
                  label: const Text('Entrar', style: TextStyle(color: Colors.white)), 
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Registrarse()),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.lightBlueAccent),
                  label: const Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Colors.lightBlueAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
