import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://epsixchtvnemohydlpaf.supabase.co',
    anonKey: 'sb_publishable__9DlE5RQ6V6pGSUjNweHBA_PwXUBRIS',
  );

  runApp(const MiAplicacion());
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      primaryColor: const Color(0xFF0EA5E9),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0EA5E9),
        secondary: Color(0xFF10B981),
        surface: Color(0xFF0F172A),
        error: Color(0xFFF87171),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFFF1F5F9)),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BolsaStreet',
      theme: tema,
      home: VerificarAutenticacion(),
    );
  }
}