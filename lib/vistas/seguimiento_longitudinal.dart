import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SeguimientoLongitudinal extends StatefulWidget {
  final String escalaId; // ID del constructo a visualizar (ej. PANAS)
  final String nombreEscala;

  const SeguimientoLongitudinal({
    super.key,
    required this.escalaId,
    required this.nombreEscala,
  });

  @override
  State<SeguimientoLongitudinal> createState() =>
      _SeguimientoLongitudinalState();
}

class _SeguimientoLongitudinalState extends State<SeguimientoLongitudinal> {
  final _supabase = Supabase.instance.client;
  bool _estaCargando = true;
  List<FlSpot> _coordenadas = [];
  List<DateTime> _fechasX = [];

  // Paleta Institucional (Tonos Pastel / Pantone)
  final Color _colorLinea = const Color(0xFF4A6572); // Pantone Slate
  final Color _colorFondoGrafico = const Color(0xFFF4F6F8);
  final Color _colorRellenoCurva = const Color(
    0xFF8DA3A6,
  ).withOpacity(0.3); // Sage Pastel
  final Color _colorCuadricula = Colors.black12;

  @override
  void initState() {
    super.initState();
    _extraerSerieTemporal();
  }

  Future<void> _extraerSerieTemporal() async {
    try {
      final usuarioActual = _supabase.auth.currentUser;
      if (usuarioActual == null) return;

      // Consulta longitudinal: Extrae las mediciones ordenadas cronológicamente
      final respuesta = await _supabase
          .from('evaluaciones_longitudinales')
          .select('fecha_toma, datos_modelo')
          .eq('miembro_id', usuarioActual.id)
          .eq('escala_id', widget.escalaId)
          .order('fecha_toma', ascending: true);

      final List<dynamic> datos = respuesta;
      List<FlSpot> coordenadasTemporales = [];
      List<DateTime> fechasExtraidas = [];

      // Parseo de la matriz de datos hacia el plano cartesiano
      for (int i = 0; i < datos.length; i++) {
        final fila = datos[i];
        final fecha = DateTime.parse(fila['fecha_toma']).toLocal();

        // Extracción del estimador latente (Asumiendo que el JSON guarda la puntuación global bajo esa clave)
        // Nota: Esta métrica provendrá del algoritmo de inversión de puntajes.
        final puntuacionGlobal =
            (fila['datos_modelo']['puntuacion_global'] as num).toDouble();

        coordenadasTemporales.add(FlSpot(i.toDouble(), puntuacionGlobal));
        fechasExtraidas.add(fecha);
      }

      if (mounted) {
        setState(() {
          _coordenadas = coordenadasTemporales;
          _fechasX = fechasExtraidas;
          _estaCargando = false;
        });
      }
    } catch (error) {
      debugPrint('Error en la extracción de la serie temporal: $error');
      if (mounted) setState(() => _estaCargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Trayectoria: ${widget.nombreEscala}'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0.5,
      ),
      body: _estaCargando
          ? const Center(child: CircularProgressIndicator())
          : _coordenadas.isEmpty
          ? _construirEstadoVacio()
          : _construirPanelGrafico(),
    );
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Matriz de datos insuficiente.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Se requiere al menos una medición para iniciar el trazado.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _construirPanelGrafico() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Evolución Intra-sujeto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estimación de la variable latente a lo largo de las mediciones registradas.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // Contenedor del Gráfico
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                right: 16,
                left: 6,
                top: 24,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                color: _colorFondoGrafico,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: LineChart(_configurarMatrizGrafica()),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _configurarMatrizGrafica() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: _colorCuadricula, strokeWidth: 1),
        getDrawingVerticalLine: (value) =>
            FlLine(color: _colorCuadricula, strokeWidth: 1, dashArray: [5, 5]),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final indice = value.toInt();
              if (indice >= 0 && indice < _fechasX.length) {
                // Formateo de la etiqueta del eje X
                final textoFecha = DateFormat(
                  'dd MMM',
                ).format(_fechasX[indice]);
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    textoFecha,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          // CORRECCIÓN 1: 'width' en lugar de 'strokeWidth'
          bottom: BorderSide(color: _colorLinea.withOpacity(0.5), width: 2.0),
          left: BorderSide(color: _colorLinea.withOpacity(0.5), width: 2.0),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _coordenadas,
          isCurved: true,
          color: _colorLinea,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _colorLinea,
                ),
          ),
          belowBarData: BarAreaData(show: true, color: _colorRellenoCurva),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          // CORRECCIÓN 2: Implementación de 'getTooltipColor'
          getTooltipColor: (LineBarSpot touchedSpot) => _colorLinea,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              return LineTooltipItem(
                'Puntuación: ${touchedSpot.y.toStringAsFixed(1)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
