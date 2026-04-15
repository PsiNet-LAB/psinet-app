import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importamos el motor de evaluación que creamos previamente
import '../evaluaciones/motor_evaluacion.dart';
// Importamos el login para mantener el botón de acceso a miembros
import '../auth/login_miembros.dart';

class VistaPublica extends StatefulWidget {
  const VistaPublica({super.key});

  @override
  State<VistaPublica> createState() => _VistaPublicaState();
}

class _VistaPublicaState extends State<VistaPublica> {
  // Variable de estado para controlar la interfaz mientras se descarga el JSON
  bool _descargandoEscala = false;

  // =========================================================================
  // AQUÍ SE COLOCA LA FUNCIÓN DE DESCARGA Y ENRUTAMIENTO
  // =========================================================================
  Future<void> _iniciarEvaluacionPANAS(BuildContext context) async {
    setState(() => _descargandoEscala = true);

    try {
      // 1. Consulta estricta a la base de datos PostgreSQL
      final response = await Supabase.instance.client
          .from('catalogo_escalas')
          .select('parametros_items')
          .eq('acronimo', 'PANAS')
          .single();

      final parametrosJson =
          response['parametros_items'] as Map<String, dynamic>;

      // 2. Navegación inyectando el JSON al motor de renderizado
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MotorEvaluacionPsicometrica(
              parametrosEscala: parametrosJson,
              escalaId:
                  'a1b2c3d4-e5f6-7890-abcd-ef1234567890', // Inserte el parámetro faltante
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error de red al contactar con el clúster de bases de datos.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _descargandoEscala = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      appBar: AppBar(
        title: const Text('PsiNet LAB - Evaluaciones Abiertas'),
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginMiembros()),
              );
            },
            icon: const Icon(Icons.login),
            label: const Text('Acceso Institucional'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Instrumentos Disponibles',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta interactiva para la escala PANAS
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF7B9095),
                  child: Icon(Icons.psychology, color: Colors.white),
                ),
                title: const Text(
                  'Escala PANAS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Afecto Positivo y Negativo'),
                trailing: _descargandoEscala
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 16),
                // Conectamos el evento del tap con nuestra función asíncrona
                onTap: _descargandoEscala
                    ? null
                    : () => _iniciarEvaluacionPANAS(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
