import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'seguimiento_longitudinal.dart';

class InterfazPrivadaInvestigador extends StatefulWidget {
  const InterfazPrivadaInvestigador({super.key});

  @override
  State<InterfazPrivadaInvestigador> createState() =>
      _InterfazPrivadaInvestigadorState();
}

class _InterfazPrivadaInvestigadorState
    extends State<InterfazPrivadaInvestigador> {
  final _supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _perfilFuture;

  // Paleta Institucional (Tonos Pastel / Pantone)
  final Color _colorFondo = const Color(0xFFF4F6F8);
  final Color _colorPrimario = const Color(0xFF4A6572); // Pantone Slate
  final Color _colorAcento = const Color(0xFF8DA3A6); // Sage Pastel
  final Color _colorTexto = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _perfilFuture = _obtenerPerfilInstitucional();
  }

  // Función asíncrona para descargar los datos del miembro autenticado
  Future<Map<String, dynamic>> _obtenerPerfilInstitucional() async {
    final usuarioActual = _supabase.auth.currentUser;
    if (usuarioActual == null) throw Exception('Sesión no encontrada');

    // La política RLS en PostgreSQL garantiza que solo pueda leer su propio registro
    final respuesta = await _supabase
        .from('miembros')
        .select('lab_id, nombre_completo, rol_institucional')
        .eq('id', usuarioActual.id)
        .single();

    return respuesta;
  }

  // Función para destruir el token de sesión
  Future<void> _cerrarSesion() async {
    await _supabase.auth.signOut();
    // El AuthGate detectará la destrucción del token y redirigirá automáticamente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text('PsiNet LAB - Hub Científico'),
        backgroundColor: Colors.white,
        foregroundColor: _colorTexto,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión Cifrada',
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          // 1. Estado de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: _colorPrimario),
            );
          }

          // 2. Manejo de errores (ej. Perfil no creado en BD)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al recuperar la identidad institucional.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          // 3. Extracción de datos validados
          final datosPerfil = snapshot.data!;
          final labId = datosPerfil['lab_id'] ?? 'Pendiente';
          final nombre = datosPerfil['nombre_completo'] ?? 'Investigador';
          final rol = datosPerfil['rol_institucional'] ?? 'Miembro';

          // 4. Renderizado del Panel
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _perfilFuture = _obtenerPerfilInstitucional();
              });
            },
            color: _colorPrimario,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _construirTarjetaIdentidad(nombre, rol, labId),
                const SizedBox(height: 32),

                Text(
                  'Módulos Analíticos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colorTexto,
                  ),
                ),
                const SizedBox(height: 16),

                _construirModuloAccion(
                  icono: Icons.timeline,
                  titulo: 'Seguimiento Longitudinal',
                  subtitulo:
                      'Visualización de trayectorias psicométricas intra-sujeto',
                  alPresionar: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SeguimientoLongitudinal(
                          // En un flujo real, aquí se seleccionaría la escala previamente.
                          // Usamos UUID simulado para la conexión arquitectónica inicial.
                          escalaId: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
                          nombreEscala: 'PANAS',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _construirModuloAccion(
                  icono: Icons.enhanced_encryption_outlined,
                  titulo: 'Comunicaciones Internas',
                  subtitulo: 'Canal de mensajería con cifrado asimétrico local',
                  alPresionar: () {
                    debugPrint('Abriendo canal seguro...');
                  },
                ),
                const SizedBox(height: 12),

                _construirModuloAccion(
                  icono: Icons.assignment_ind_outlined,
                  titulo: 'Auto-Evaluación de Control',
                  subtitulo: 'Registrar nueva medición para el perfil base',
                  alPresionar: () {
                    debugPrint('Abriendo catálogo interno...');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget personalizado para la Ficha del Miembro
  Widget _construirTarjetaIdentidad(String nombre, String rol, String labId) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _colorAcento.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _colorPrimario.withOpacity(0.1),
                child: Icon(Icons.science, color: _colorPrimario, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _colorTexto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rol,
                      style: TextStyle(
                        fontSize: 14,
                        color: _colorTexto.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Identificador Institucional:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _colorFondo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labId,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para las opciones del panel
  Widget _construirModuloAccion({
    required IconData icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback alPresionar,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: alPresionar,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _colorAcento.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: _colorPrimario),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
