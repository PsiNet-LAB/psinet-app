import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../vistas/vista_publica.dart';
import '../vistas/interfaz_privada.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha los cambios del token JWT en tiempo real
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // 1. Estado de carga mientras se verifica el token criptográfico local
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Extracción de la sesión actual
        final session = snapshot.data?.session;

        // 3. Bifurcación arquitectónica basada en autenticación
        if (session != null) {
          // Sesión activa: Acceso a la interfaz científica e interna
          return const InterfazPrivadaInvestigador();
        } else {
          // Sin sesión: Enrutamiento al portal público
          return const VistaPublica();
        }
      },
    );
  }
}
