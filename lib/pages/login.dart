import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'registro.dart';
import 'tracking_corredores.dart' hide Text, TextButton;
import 'admin_corredores.dart';

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
      final respuesta = await Supabase.instance.client
          .from('usuarios')
          .select('rol')
          .eq('id', usuario!.id)
          .single();

      final rol = respuesta['rol'];

      if (rol == 'corredor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PantallaCorredorTracking()));
      } else if (rol == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PanelAdministracionCorredores()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login fallido: $e')));
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
