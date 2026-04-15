import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class MotorEvaluacionPsicometrica extends StatefulWidget {
  final Map<String, dynamic> parametrosEscala;
  final String escalaId;

  const MotorEvaluacionPsicometrica({
    super.key,
    required this.parametrosEscala,
    required this.escalaId,
  });

  @override
  State<MotorEvaluacionPsicometrica> createState() =>
      _MotorEvaluacionPsicometricaState();
}

class _MotorEvaluacionPsicometricaState
    extends State<MotorEvaluacionPsicometrica> {
  // Diccionario para almacenar las respuestas en tiempo real: { "IT_01": 4, "IT_02": 2 }
  final Map<String, int> _respuestas = {};

  // Variable de estado para controlar el botón durante el envío
  bool _enviandoDatos = false;

  // Paleta de colores sobria y moderna (Tonos Pantone/Pastel)
  final Color _colorFondo = const Color(0xFFF7F9FA);
  final Color _colorAcento = const Color(
    0xFF7B9095,
  ); // Pantone Slate/Sage pastel
  final Color _colorTextoPrimario = const Color(0xFF2C3E50);

  @override
  Widget build(BuildContext context) {
    // Extracción segura de la estructura desde el JSON
    final metadatos = widget.parametrosEscala['metadatos_escala'];
    final formato = widget.parametrosEscala['formato_respuesta'];
    final opciones = List<Map<String, dynamic>>.from(formato['opciones']);
    final reactivos = List<Map<String, dynamic>>.from(
      widget.parametrosEscala['reactivos'],
    );

    return Scaffold(
      backgroundColor: _colorFondo,
      appBar: AppBar(
        title: const Text('Evaluación en Curso'),
        backgroundColor: Colors.white,
        foregroundColor: _colorTextoPrimario,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Cabecera con Instrucciones Generales
          Container(
            padding: const EdgeInsets.all(20.0),
            color: Colors.white,
            width: double.infinity,
            child: Text(
              metadatos['instrucciones_generales'],
              style: TextStyle(
                fontSize: 15,
                color: _colorTextoPrimario.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          // Lista Dinámica de Reactivos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              itemCount: reactivos.length,
              itemBuilder: (context, index) {
                final reactivo = reactivos[index];
                final itemId = reactivo['item_id'];

                return _construirTarjetaReactivo(reactivo, itemId, opciones);
              },
            ),
          ),
        ],
      ),
      // Botón flotante para finalizar la evaluación
      floatingActionButton: FloatingActionButton.extended(
        onPressed: (_respuestas.length == reactivos.length && !_enviandoDatos)
            ? _procesarResultados
            : null, // Se deshabilita si faltan respuestas
        backgroundColor: _respuestas.length == reactivos.length
            ? _colorAcento
            : Colors.grey[300],
        icon: _enviandoDatos
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.analytics_outlined),
        label: Text(
          _enviandoDatos ? 'Procesando Matriz...' : 'Guardar y Analizar',
        ),
      ),
    );
  }

  // Constructor visual de cada ítem con escala Likert
  Widget _construirTarjetaReactivo(
    Map<String, dynamic> reactivo,
    String itemId,
    List<Map<String, dynamic>> opciones,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto del ítem
            Text(
              "${reactivo['orden_presentacion']}. ${reactivo['texto']}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _colorTextoPrimario,
              ),
            ),
            const SizedBox(height: 16),

            // Opciones de respuesta (Botones tipo Segmented Control / Burbujas)
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.center,
              children: opciones.map((opcion) {
                final valor = opcion['valor_numerico'] as int;
                final estaSeleccionado = _respuestas[itemId] == valor;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _respuestas[itemId] = valor;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: estaSeleccionado ? _colorAcento : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: estaSeleccionado
                            ? _colorAcento
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      valor
                          .toString(), // Se muestra el número (o se puede cambiar por opcion['etiqueta'])
                      style: TextStyle(
                        fontWeight: estaSeleccionado
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: estaSeleccionado
                            ? Colors.white
                            : _colorTextoPrimario,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Leyenda dinámica de la opción seleccionada
            if (_respuestas.containsKey(itemId))
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Center(
                  child: Text(
                    opciones.firstWhere(
                      (o) => o['valor_numerico'] == _respuestas[itemId],
                    )['etiqueta'],
                    style: TextStyle(
                      fontSize: 12,
                      color: _colorAcento,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Función para empaquetar los datos hacia la base de datos
  Future<void> _procesarResultados() async {
    setState(() => _enviandoDatos = true);

    try {
      final formato = widget.parametrosEscala['formato_respuesta'];
      final reactivos = List<Map<String, dynamic>>.from(
        widget.parametrosEscala['reactivos'],
      );
      final opciones = List<Map<String, dynamic>>.from(formato['opciones']);

      // 1. Cálculo de la constante geométrica de inversión
      // Formula: Valor Máximo + Valor Mínimo
      final valoresNumericos = opciones
          .map((o) => o['valor_numerico'] as int)
          .toList();
      final int valMaximo = valoresNumericos.reduce(math.max);
      final int valMinimo = valoresNumericos.reduce(math.min);
      final int constanteInversion = valMaximo + valMinimo;

      Map<String, int> puntajesProcesados = {};
      Map<String, int> sumatoriaDimensiones = {};
      int puntuacionGlobal = 0;

      // 2. Iteración matricial: Inversión y agrupación latente
      for (var reactivo in reactivos) {
        final String itemId = reactivo['item_id'];
        final String dimensionId = reactivo['dimension_id'];
        final String direccion = reactivo['direccion_puntuacion'];

        // Extracción del valor crudo registrado por el usuario
        final int puntajeCrudo = _respuestas[itemId]!;
        int puntajeFinal = puntajeCrudo;

        // Inversión algorítmica si el ítem es inverso
        if (direccion == 'inversa') {
          puntajeFinal = constanteInversion - puntajeCrudo;
        }

        puntajesProcesados[itemId] = puntajeFinal;

        // Agrupación por modelo de medición (Dimensiones)
        sumatoriaDimensiones[dimensionId] =
            (sumatoriaDimensiones[dimensionId] ?? 0) + puntajeFinal;
        puntuacionGlobal += puntajeFinal;
      }

      // 3. Estructuración del JSON (Payload)
      final datosModelo = {
        'puntajes_procesados': puntajesProcesados,
        'sumatoria_dimensiones': sumatoriaDimensiones,
        'puntuacion_global': puntuacionGlobal,
      };

      // 4. Transmisión segura a PostgreSQL (Supabase)
      final usuarioActual = Supabase.instance.client.auth.currentUser;
      if (usuarioActual == null) {
        throw Exception('No se detectó una firma criptográfica válida.');
      }

      await Supabase.instance.client.from('evaluaciones_longitudinales').insert({
        'miembro_id': usuarioActual.id,
        'escala_id': widget.escalaId,
        'respuestas_crudas': _respuestas,
        'datos_modelo': datosModelo,
        // La fecha de toma se genera automáticamente en la base de datos (DEFAULT NOW())
      });

      // 5. Cierre exitoso y retorno a la interfaz anterior
      if (mounted) {
        Navigator.of(context).pop(); // Cierra el motor de evaluación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Matriz de datos ingresada exitosamente al modelo longitudinal.',
            ),
            backgroundColor: Color(0xFF4A6572), // Pantone Slate
          ),
        );
      }
    } catch (error) {
      debugPrint('Error en el pipeline de recolección: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar datos: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoDatos = false);
    }
  }
}
