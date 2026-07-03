import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../controllers/scale_diagnostic_controller.dart';
import '../models/scale_reading.dart';
import '../models/scale_measurement.dart';
import '../utils/hex_utils.dart';
import 'package:gimnasio_app/modules/scale/utils/body_composition_calculator.dart';
import 'body_composition_report_screen.dart' as body_comp;

class ScaleDebugScreen extends StatefulWidget {
  /// Cliente seleccionado actualmente en el panel de administración.
  /// Si es null, la pantalla opera solo en modo diagnóstico BLE.
  final Map<String, dynamic>? cliente;

  /// URL base del API del backend.
  final String baseUrl;

  /// Indica si el usuario actual es administrador (para permitir búsqueda por cédula).
  final bool isAdmin;

  const ScaleDebugScreen({
    Key? key,
    required this.baseUrl,
    this.cliente,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  State<ScaleDebugScreen> createState() => _ScaleDebugScreenState();
}

class _ScaleDebugScreenState extends State<ScaleDebugScreen>
    with SingleTickerProviderStateMixin {
  late final ScaleDiagnosticController _controller;
  late final TabController _tabController;
  final TextEditingController _hexCommandController = TextEditingController();
  final TextEditingController _cedulaSearchCtrl = TextEditingController();

  // Controladores del formulario de pesaje manual
  final TextEditingController _pesoCtrl = TextEditingController();
  final TextEditingController _impedanciaCtrl = TextEditingController();
  final TextEditingController _imcCtrl = TextEditingController();
  final TextEditingController _grasaCtrl = TextEditingController();
  final TextEditingController _musculoCtrl = TextEditingController();
  final TextEditingController _oseoCtrl = TextEditingController();
  final TextEditingController _aguaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = ScaleDiagnosticController(
      baseUrl: widget.baseUrl,
      cliente: widget.cliente,
    );
    _controller.addListener(_onStateChanged);
    _controller.logger.addListener(_onStateChanged);

    // Iniciar escaneo pasivo automáticamente al abrir la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.disconnect();
      _controller.startScan();
    });
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_onStateChanged);
    _controller.logger.removeListener(_onStateChanged);
    _controller.stopScan();
    _controller.disconnect();
    _hexCommandController.dispose();
    _cedulaSearchCtrl.dispose();
    _pesoCtrl.dispose();
    _impedanciaCtrl.dispose();
    _imcCtrl.dispose();
    _grasaCtrl.dispose();
    _musculoCtrl.dispose();
    _oseoCtrl.dispose();
    _aguaCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cliente = _controller.cliente;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          'Báscula S400',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            onPressed: () => _controller.logger.clearLogs(),
            tooltip: 'Limpiar Logs',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt, color: Colors.white70),
            onPressed: () => _controller.exportLogs(),
            tooltip: 'Exportar JSON',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD4AF37),
          labelColor: const Color(0xFFD4AF37),
          unselectedLabelColor: Colors.white54,
          tabs: [
            const Tab(icon: Icon(Icons.bluetooth_searching), text: 'BLE'),
            Tab(
              icon: const Icon(Icons.history),
              text: cliente != null ? 'Historial' : 'Historial',
            ),
            const Tab(icon: Icon(Icons.monitor_weight), text: 'Guardar'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_controller.cliente == null) _buildAdminClientSelector(),
          if (_controller.errorCliente != null)
            _buildMensajeBanner('❌ ${_controller.errorCliente!}'),
          _buildClienteBanner(),
          _buildLiveScaleReadingCard(),
          if (_controller.mensajeGuardado != null)
            _buildMensajeBanner(_controller.mensajeGuardado!),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabBle(),
                _buildTabHistorial(),
                _buildTabGuardar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BANNER DE CLIENTE Y BÚSQUEDA
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAdminClientSelector() {
    return Container(
      color: const Color(0xFF161B22),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cedulaSearchCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Cédula del cliente...',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: Color(0xFF0D1117),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  _controller.buscarYSeleccionarCliente(val.trim());
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _controller.buscandoCliente
                ? null
                : () {
                    final cedula = _cedulaSearchCtrl.text.trim();
                    if (cedula.isNotEmpty) {
                      _controller.buscarYSeleccionarCliente(cedula);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: _controller.buscandoCliente
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteBanner() {
    final cliente = _controller.cliente;
    if (cliente == null) {
      return Container(
        width: double.infinity,
        color: Colors.orange.shade900.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sin cliente seleccionado — modo diagnóstico BLE',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final nombre = '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'.trim();
    final doc = cliente['documento'] ?? '';

    return Container(
      width: double.infinity,
      color: const Color(0xFF1C2A1C),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.person_pin, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Cédula: $doc',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  _cedulaSearchCtrl.clear();
                  _controller.limpiarCliente();
                },
                icon: const Icon(Icons.clear, color: Colors.white70, size: 20),
                tooltip: 'Limpiar cliente',
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: _controller.cargarHistorial,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refrescar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A3A2A),
                  foregroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _verReporteDetallado(ScaleMeasurement lectura) {
    if (_controller.cliente != null) {
      _mostrarReporte(lectura, _controller.cliente!);
    } else {
      _mostrarDialogoDatos(lectura);
    }
  }

  void _mostrarDialogoDatos(ScaleMeasurement lectura) {
    final formKey = GlobalKey<FormState>();
    final estaturaCtrl = TextEditingController(text: '170');
    final edadCtrl = TextEditingController(text: '25');
    String genero = 'M';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Datos para el cálculo', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: estaturaCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Estatura (cm)', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              TextFormField(
                controller: edadCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Edad', labelStyle: TextStyle(color: Colors.white70)),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: genero,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Género', labelStyle: TextStyle(color: Colors.white70)),
                items: const [
                  DropdownMenuItem(value: 'M', child: Text('Masculino', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'F', child: Text('Femenino', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => genero = v ?? 'M',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                final result = BodyCompositionCalculator.calcular(
                  peso: lectura.weight ?? 0.0,
                  estaturaCm: double.tryParse(estaturaCtrl.text) ?? 170.0,
                  edad: int.tryParse(edadCtrl.text) ?? 25,
                  esMasculino: genero == 'M',
                  impedancia: lectura.impedance?.toDouble() ?? 0.0,
                );
                
                ScaleReading? previous;
                final h = _controller.historial;
                if (h.length > 1) {
                  previous = h[1];
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => body_comp.BodyCompositionReportScreen(
                      result: result,
                      previousReading: previous,
                    ),
                  ),
                );
              }
            },
            child: const Text('Ver Reporte'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarReporte(ScaleMeasurement lectura, Map<String, dynamic> clienteData) async {
    final estatura = double.tryParse(clienteData['estatura']?.toString() ?? '170.0') ?? 170.0;
    final genero = clienteData['genero']?.toString() ?? 'M';
    final esMasculino = genero.toUpperCase().startsWith('M');
    
    int edad = 25;
    final fnac = clienteData['fecha_nacimiento']?.toString();
    if (fnac != null && fnac.isNotEmpty) {
      try {
        final dt = DateTime.parse(fnac);
        edad = DateTime.now().year - dt.year;
      } catch(_) {}
    }

    final result = BodyCompositionCalculator.calcular(
      peso: lectura.weight ?? 0.0,
      estaturaCm: estatura,
      edad: edad,
      esMasculino: esMasculino,
      impedancia: lectura.impedance?.toDouble() ?? 0.0,
    );

    // Esperar a que guardarPesaje termine (si está en curso)
    // para que el historial esté actualizado antes de mostrar el reporte
    int waitAttempts = 0;
    while (_controller.guardando && waitAttempts < 20) {
      await Future.delayed(const Duration(milliseconds: 300));
      waitAttempts++;
    }

    // Recargar historial fresco del backend para asegurar datos actualizados
    await _controller.cargarHistorial();

    ScaleReading? previous;
    final h = _controller.historial;
    if (h.length > 1) {
      // El primer elemento es el que acabamos de guardar, el segundo es el anterior
      previous = h[1];
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => body_comp.BodyCompositionReportScreen(
          result: result,
          previousReading: previous,
        ),
      ),
    );
  }

  Widget _buildLiveScaleReadingCard() {
    final lectura = _controller.lecturaActual;
    if (lectura == null && _controller.connectedDevice == null) return const SizedBox.shrink();

    return Column(
      children: [
        if (_controller.authError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildMensajeBanner('❌ ${_controller.authError!}'),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_controller.connectedDevice != null && _controller.authError == null)
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScaleMeasurementScreen(
                          controller: _controller,
                          onNavigateToReport: (lecturaData) {
                            _verReporteDetallado(lecturaData);
                          },
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.monitor_weight),
            label: const Text('INICIAR MEDICIÓN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade800,
              disabledForegroundColor: Colors.grey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMensajeBanner(String mensaje) {
    final esError = mensaje.startsWith('❌');
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: esError
          ? Colors.red.shade900.withOpacity(0.4)
          : Colors.green.shade900.withOpacity(0.4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        mensaje,
        style: TextStyle(
          color: esError ? Colors.redAccent : Colors.greenAccent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 1: BLE DIAGNÓSTICO
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabBle() {
    if (kIsWeb) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bluetooth_disabled, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Bluetooth no disponible en Web',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              SizedBox(height: 12),
              Text(
                'La conexión directa a la báscula por Bluetooth no es compatible desde el navegador web en computadores.\n\nPara conectar la báscula automáticamente, utiliza la aplicación APK instalada en tu celular.\n\nEn computador puedes seguir consultando el "Historial" y registrando mediciones de forma manual en la pestaña "Guardar".',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        _buildConnectionPanel(),
        const Divider(color: Colors.white12),
        if (_controller.connectedDevice == null)
          Expanded(flex: 2, child: _buildScannerList())
        else
          _buildConnectedPanel(),
        const Divider(color: Colors.white12),
        // CONSOLA BLE SIEMPRE VISIBLE
        Container(
          color: const Color(0xFF1A1D2E),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.terminal, size: 14, color: Colors.white38),
              const SizedBox(width: 6),
              const Text(
                'CONSOLA BLE (Logs)',
                style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                label: const Text('Copiar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(80, 30),
                ),
                onPressed: () {
                  final text = _controller.logger.logs.join('\n');
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logs copiados al portapapeles', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                },
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFF0D1117),
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 20),
              itemCount: _controller.logger.logs.length,
              itemBuilder: (_, i) {
                final log = _controller.logger.logs[_controller.logger.logs.length - 1 - i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    log.toString(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: log.type == 'ERROR'
                          ? Colors.redAccent
                          : log.type == 'INFO'
                              ? Colors.greenAccent.withOpacity(0.7)
                              : Colors.white54,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed:
                _controller.isScanning || _controller.connectedDevice != null
                    ? null
                    : _controller.startScan,
            icon: _controller.isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(_controller.isScanning ? 'Escaneando...' : 'Escanear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F6FEB),
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _controller.connectedDevice != null
                ? _controller.disconnect
                : null,
            icon: const Icon(Icons.bluetooth_disabled),
            label: const Text('Desconectar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerList() {
    final List<String> knownScaleKeywords = ['SCALE', 'MIBFS', 'MIBCS', 'XIAOMI', 'S400', 'YUNMAI'];
    final results = _controller.scanResults.where((r) {
      final name = r.device.platformName.toUpperCase();
      return name.isNotEmpty && knownScaleKeywords.any((k) => name.contains(k));
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              _controller.isScanning
                  ? 'Buscando básculas Xiaomi cercanas...'
                  : 'No se encontraron básculas en el escaneo.\nPresiona Escanear para comenzar.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final r = results[index];
        final name = r.device.platformName;
        return Card(
          color: const Color(0xFF1C2133),
          child: ListTile(
            leading: Icon(
              Icons.monitor_weight_outlined,
              color: r.rssi > -60 ? Colors.greenAccent : Colors.orangeAccent,
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${r.device.remoteId} | RSSI: ${r.rssi} dBm',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
              trailing: ElevatedButton(
                onPressed: () async {
                  await _controller.configurarMacBascula(r.device.remoteId.toString());
                  await _controller.connectToDevice(r.device);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Báscula vinculada y autenticando: ${r.device.remoteId}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Conectar y Autenticar'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectedPanel() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Conectado: ${_controller.connectedDevice!.platformName.isNotEmpty ? _controller.connectedDevice!.platformName : _controller.connectedDevice!.remoteId}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hexCommandController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Comando HEX (ej. 01 02 FF)',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final hex = _hexCommandController.text;
                  if (hex.isEmpty) return;
                  final bytes = HexUtils.fromHex(hex);
                  if (bytes.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formato HEX inválido')),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Elegir característica para escribir pendiente en UI.'),
                    ),
                  );
                },
                child: const Text('Enviar'),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ──────────────────────────────────────────────────────────────────────────
  // TAB 2: HISTORIAL
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabHistorial() {
    if (_controller.cliente == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Selecciona un cliente en el panel\nprincipal para ver su historial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    if (_controller.cargandoHistorial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.errorHistorial != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _controller.errorHistorial!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _controller.cargarHistorial,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_controller.historial.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'Sin registros de pesaje aún.\nConéctate a la báscula para registrar el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _controller.historial.length,
      itemBuilder: (context, index) {
        final r = _controller.historial[index];
        return _buildHistorialCard(r);
      },
    );
  }

  Widget _buildHistorialCard(ScaleReading r) {
    final cliente = _controller.cliente;
    final genero = (cliente != null && cliente['genero'] != null)
        ? cliente['genero'].toString().toUpperCase()
        : 'MASCULINO';

    final hasBia = r.imc != null || r.porcentajeGrasa != null || r.porcentajeMuscular != null;

    return Card(
      color: const Color(0xFF1C2133),
      margin: const EdgeInsets.only(bottom: 10),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          collapsedIconColor: const Color(0xFFD4AF37),
          iconColor: const Color(0xFFD4AF37),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Color(0xFFD4AF37)),
                  const SizedBox(width: 6),
                  Text(
                    '${r.fechaPesaje.day.toString().padLeft(2, '0')}/'
                    '${r.fechaPesaje.month.toString().padLeft(2, '0')}/'
                    '${r.fechaPesaje.year}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (r.id != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmarEliminar(r.id!),
                  tooltip: 'Eliminar registro',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (r.peso != null) _chip('⚖️ Peso', '${r.peso!.toStringAsFixed(1)} kg'),
                if (r.imc != null) _chip('📊 IMC', r.imc!.toStringAsFixed(1)),
                if (r.porcentajeGrasa != null) _chip('🟡 Grasa', '${r.porcentajeGrasa!.toStringAsFixed(1)}%'),
              ],
            ),
          ),
          children: hasBia
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 8),
                        const Text(
                          'COMPOSICIÓN CORPORAL',
                          style: TextStyle(
                            color: Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRangeBars(r, genero),
                        if (r.porcentajeOseo != null || r.impedancia != null) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              if (r.porcentajeOseo != null) _chip('🦴 Óseo', '${r.porcentajeOseo!.toStringAsFixed(1)}%'),
                              if (r.impedancia != null) _chip('⚡ Impedancia', '${r.impedancia!.toStringAsFixed(0)} Ω'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _mostrarReporteCompleto(context, r),
                            icon: const Icon(Icons.analytics, color: Colors.black),
                            label: const Text('VER REPORTE DE COMPOSICIÓN', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildRangeBars(ScaleReading r, String genero) {
    final bool esMasculino = genero.contains('MASC') || genero.contains('M');
    
    return Column(
      children: [
        if (r.imc != null)
          MetricRangeBar(
            label: '📊 IMC (Índice de Masa Corporal)',
            value: r.imc!,
            unit: '',
            minVal: 15.0,
            maxVal: 35.0,
            thresholds: const [18.5, 25.0, 30.0],
            colors: const [Colors.orange, Colors.green, Colors.yellow, Colors.red],
            segmentLabels: const ['Bajo', 'Normal', 'Sobrepeso', 'Obesidad'],
          ),
        if (r.porcentajeGrasa != null)
          MetricRangeBar(
            label: '🟡 Porcentaje de Grasa Corporal',
            value: r.porcentajeGrasa!,
            unit: '%',
            minVal: 5.0,
            maxVal: 45.0,
            thresholds: esMasculino ? const [8.0, 20.0, 25.0] : const [21.0, 33.0, 39.0],
            colors: const [Colors.orange, Colors.green, Colors.yellow, Colors.red],
            segmentLabels: const ['Bajo', 'Saludable', 'Elevado', 'Alto'],
          ),
        if (r.porcentajeMuscular != null)
          MetricRangeBar(
            label: '💪 Porcentaje de Masa Muscular',
            value: r.porcentajeMuscular!,
            unit: '%',
            minVal: 15.0,
            maxVal: 55.0,
            thresholds: esMasculino ? const [33.0, 40.0] : const [24.0, 30.0],
            colors: const [Colors.red, Colors.green, Colors.blue],
            segmentLabels: const ['Bajo', 'Normal', 'Excelente'],
          ),
        if (r.porcentajeLiquidos != null)
          MetricRangeBar(
            label: '💧 Porcentaje de Agua Corporal',
            value: r.porcentajeLiquidos!,
            unit: '%',
            minVal: 35.0,
            maxVal: 75.0,
            thresholds: esMasculino ? const [50.0, 65.0] : const [45.0, 60.0],
            colors: const [Colors.red, Colors.green, Colors.blue],
            segmentLabels: const ['Bajo', 'Saludable', 'Excelente'],
          ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmarEliminar(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2133),
        title: const Text('Eliminar registro', style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro de pesaje?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _controller.eliminarPesaje(id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarReporteCompleto(BuildContext context, ScaleReading r) {
    final estaturaVal = _controller.cliente?['estatura'] != null
        ? double.tryParse(_controller.cliente!['estatura'].toString())
        : null;
    final estaturaCm = estaturaVal ?? (_controller.cliente?['genero']?.toString().toUpperCase().contains('FEM') == true ? 160.0 : 170.0);
    
    final dobStr = _controller.cliente?['fecha_nacimiento']?.toString();
    int edad = 25;
    if (dobStr != null) {
      try {
        final dob = DateTime.parse(dobStr);
        final now = DateTime.now();
        edad = now.year - dob.year;
        if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
          edad--;
        }
      } catch (_) {}
    }
    final esMasculino = _controller.cliente?['genero']?.toString().toUpperCase().contains('FEM') != true;

    final calc = BodyCompositionCalculator.calcular(
      peso: r.peso ?? 0.0,
      impedancia: r.impedancia?.toDouble() ?? 500.0,
      estaturaCm: estaturaCm,
      edad: edad,
      esMasculino: esMasculino,
    );

    // Buscar la lectura anterior a esta en el historial
    ScaleReading? previous;
    final h = _controller.historial;
    for (int i = 0; i < h.length; i++) {
      if (h[i].id == r.id && i + 1 < h.length) {
        previous = h[i + 1];
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => body_comp.BodyCompositionReportScreen(
          result: calc,
          previousReading: previous,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TAB 3: GUARDAR PESAJE MANUAL
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabGuardar() {
    final cliente = _controller.cliente;
    final sinCliente = cliente == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sinCliente)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade800),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Debes seleccionar un cliente en el panel principal para guardar un pesaje.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Datos del pesaje',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresa los valores medidos por la báscula. Solo el peso es obligatorio.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _inputField(_pesoCtrl, '⚖️  Peso (kg)', obligatorio: true, enabled: !sinCliente),
          _inputField(_impedanciaCtrl, '⚡  Impedancia (Ω)', enabled: !sinCliente),
          _inputField(_imcCtrl, '📊  IMC', enabled: !sinCliente),
          _inputField(_grasaCtrl, '🟡  % Grasa corporal', enabled: !sinCliente),
          _inputField(_musculoCtrl, '💪  % Masa muscular', enabled: !sinCliente),
          _inputField(_oseoCtrl, '🦴  % Masa ósea', enabled: !sinCliente),
          _inputField(_aguaCtrl, '💧  % Agua corporal', enabled: !sinCliente),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (sinCliente || _controller.guardando)
                  ? null
                  : _guardarPesajeManual,
              icon: _controller.guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _controller.guardando ? 'Guardando...' : 'Guardar Pesaje',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label, {
    bool obligatorio = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: obligatorio ? '$label *' : label,
          labelStyle: TextStyle(
            color: obligatorio ? const Color(0xFFD4AF37) : Colors.white54,
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFD4AF37)),
          ),
          disabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white12),
          ),
          filled: true,
          fillColor: const Color(0xFF1C2133),
          isDense: true,
        ),
      ),
    );
  }

  void _guardarPesajeManual() {
    final pesoText = _pesoCtrl.text.trim();
    if (pesoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El peso es obligatorio')),
      );
      return;
    }

    final peso = double.tryParse(pesoText);
    if (peso == null || peso <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un peso válido')),
      );
      return;
    }

    _controller.guardarPesaje(
      peso: peso,
      impedancia: double.tryParse(_impedanciaCtrl.text.trim()),
      imc: double.tryParse(_imcCtrl.text.trim()),
      porcentajeGrasa: double.tryParse(_grasaCtrl.text.trim()),
      porcentajeMuscular: double.tryParse(_musculoCtrl.text.trim()),
      porcentajeOseo: double.tryParse(_oseoCtrl.text.trim()),
      porcentajeLiquidos: double.tryParse(_aguaCtrl.text.trim()),
    );

    // Limpiar campos y saltar al historial al guardar
    _pesoCtrl.clear();
    _impedanciaCtrl.clear();
    _imcCtrl.clear();
    _grasaCtrl.clear();
    _musculoCtrl.clear();
    _oseoCtrl.clear();
    _aguaCtrl.clear();
    _tabController.animateTo(1);
  }
}

class MetricRangeBar extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double minVal;
  final double maxVal;
  final List<double> thresholds; // ej: [18.5, 25.0, 30.0]
  final List<Color> colors; // ej: [Colors.blue, Colors.green, Colors.orange, Colors.red]
  final List<String> segmentLabels; // ej: ['Bajo', 'Normal', 'Sobrepeso', 'Obesidad']

  const MetricRangeBar({
    Key? key,
    required this.label,
    required this.value,
    required this.unit,
    required this.minVal,
    required this.maxVal,
    required this.thresholds,
    required this.colors,
    required this.segmentLabels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double percent = ((value - minVal) / (maxVal - minVal)).clamp(0.0, 1.0);
    
    // Determinar segmento activo
    int activeSegment = 0;
    for (int i = 0; i < thresholds.length; i++) {
      if (value >= thresholds[i]) {
        activeSegment = i + 1;
      }
    }
    
    final activeColor = colors[activeSegment];
    final activeLabel = segmentLabels[activeSegment];

    // Calcular las proporciones de los segmentos
    final List<double> bounds = [minVal, ...thresholds, maxVal];
    final List<double> sizes = [];
    final double totalRange = maxVal - minVal;
    for (int i = 0; i < bounds.length - 1; i++) {
      double diff = bounds[i + 1] - bounds[i];
      sizes.add(diff / totalRange);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: activeColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      activeLabel.toUpperCase(),
                      style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${value.toStringAsFixed(1)}$unit',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: activeColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double barWidth = constraints.maxWidth;
              final double indicatorPosition = barWidth * percent;
              
              return Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  // Barra de fondo segmentada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      width: barWidth,
                      child: Row(
                        children: List.generate(sizes.length, (index) {
                          return Expanded(
                            flex: (sizes[index] * 1000).toInt(),
                            child: Container(
                              color: colors[index].withOpacity(0.35),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  // Indicador del valor actual
                  Positioned(
                    left: indicatorPosition - 5,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET DEL REPORTE COMPLETO (ESTILO PREMIUM XIAOMI HOME EN ESPAÑOL)
// ─────────────────────────────────────────────────────────────────────────────
class _ReporteCompletoWidget extends StatelessWidget {
  final BodyCompositionResult calc;
  final ScrollController scrollController;
  final String clienteNombre;
  final DateTime fecha;

  const _ReporteCompletoWidget({
    Key? key,
    required this.calc,
    required this.scrollController,
    required this.clienteNombre,
    required this.fecha,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColorMap = {
      'Bajo': Colors.orangeAccent,
      'Standard': Colors.greenAccent,
      'Normal': Colors.greenAccent,
      'Bueno': Colors.greenAccent,
      'Excelente': Colors.blueAccent,
      'Sobrepeso': Colors.yellowAccent,
      'Alto': Colors.orangeAccent,
      'Muy Alto': Colors.redAccent,
      'Obeso': Colors.redAccent,
    };

    Color getStatusColor(String status) {
      return statusColorMap[status] ?? Colors.white70;
    }

    // Traducción del tipo de cuerpo
    final String tipoCuerpoEsp = {
      'Lean': 'Delgado',
      'Underweight': 'Bajo Peso',
      'Slim & muscular': 'Delgado Muscular',
      'Slim': 'Delgado con Grasa',
      'Balanced': 'Equilibrado',
      'Balanced-muscular': 'Equilibrado Muscular',
      'Fit': 'Atlético / Fit',
      'Thick-set': 'Robusto / Fuerte',
      'Obese': 'Obeso',
      'Overweight': 'Sobrepeso',
      'Lack-exercise': 'Falta de Ejercicio',
    }[calc.bodyType] ?? calc.bodyType;

    // Traducción de clasificación del peso
    final String clasificacionPesoEsp = {
      'Bajo': 'Bajo Peso',
      'Standard': 'Peso Saludable',
      'Sobrepeso': 'Sobrepeso',
      'Obeso': 'Obesidad',
    }[calc.getStatusImc()] ?? calc.getStatusImc();

    return Container(
      color: const Color(0xFF0D1117),
      child: Column(
        children: [
          // Barra de arrastre superior
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Título de la pantalla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clienteNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Reporte de Peso — ${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12),

          // Contenido con scroll
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Cabecera con Peso Grande
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            calc.peso.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'kg',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        clasificacionPesoEsp.toUpperCase(),
                        style: TextStyle(
                          color: getStatusColor(calc.getStatusImc()),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Tarjeta de Puntuación Corporal
                _buildBodyScoreCard(calc, getStatusColor),
                const SizedBox(height: 16),

                // 3. Tarjeta de Composición Corporal con Silueta
                _buildBodyCompositionTopCard(calc),
                const SizedBox(height: 16),

                // 4. Cuadrícula de Métricas
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.35,
                  children: [
                    _buildMetricCard(
                      'Masa muscular',
                      '${calc.muscleMass.toStringAsFixed(1)} kg',
                      calc.getStatusMusculo(),
                      getStatusColor(calc.getStatusMusculo()),
                    ),
                    _buildMetricCard(
                      'Porcentaje muscular',
                      '${calc.musclePercentage.toStringAsFixed(1)} %',
                      calc.getStatusMusculo(),
                      getStatusColor(calc.getStatusMusculo()),
                    ),
                    _buildMetricCard(
                      'Agua corporal',
                      '${calc.waterPercentage.toStringAsFixed(1)} %',
                      calc.getStatusAgua(),
                      getStatusColor(calc.getStatusAgua()),
                    ),
                    _buildMetricCard(
                      'Porcentaje proteico',
                      '${calc.proteinPercentage.toStringAsFixed(1)} %',
                      calc.getStatusProteina(),
                      getStatusColor(calc.getStatusProteina()),
                    ),
                    _buildMetricCard(
                      'Porcentaje óseo',
                      '${calc.bonePercentage.toStringAsFixed(1)} %',
                      calc.getStatusOseo(),
                      getStatusColor(calc.getStatusOseo()),
                    ),
                    _buildMetricCard(
                      'Masa músc. esquelética',
                      '${calc.skeletalMuscleMass.toStringAsFixed(1)} kg',
                      calc.getStatusSkeletal(),
                      getStatusColor(calc.getStatusSkeletal()),
                    ),
                    _buildMetricCard(
                      'Nivel de grasa visceral',
                      '${calc.visceralFatRating}',
                      calc.getStatusVisceral(),
                      getStatusColor(calc.getStatusVisceral()),
                    ),
                    _buildMetricCard(
                      'Tasa metabólica basal',
                      '${calc.basalMetabolicRate} Kcal',
                      calc.visceralFatRating > 12 ? 'Alto' : 'Standard',
                      getStatusColor(calc.visceralFatRating > 12 ? 'Alto' : 'Standard'),
                    ),
                    _buildMetricCard(
                      'Relación cintura-cadera',
                      calc.waistToHipRatio.toStringAsFixed(2),
                      calc.getStatusWaistHip(),
                      getStatusColor(calc.getStatusWaistHip()),
                    ),
                    _buildMetricCard(
                      'Edad corporal',
                      '${calc.bodyAge} años',
                      calc.bodyAge <= calc.edad ? 'Excelente' : 'Alto',
                      getStatusColor(calc.bodyAge <= calc.edad ? 'Excelente' : 'Alto'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Card de una sola columna para Peso Libre de Grasa
                _buildMetricCardFullWidth(
                  'Peso libre de grasa',
                  '${calc.fatFreeBodyWeight.toStringAsFixed(1)} kg',
                  'Standard',
                  Colors.greenAccent,
                ),
                const SizedBox(height: 16),

                // 5. Matriz de Tipo de Cuerpo
                _buildBodyTypeMatrix(calc, tipoCuerpoEsp),
                const SizedBox(height: 16),

                // 6. Sugerencias de Control
                _buildWeightSuggestions(calc),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sub-widgets del reporte ──────────────────────────────────────────────

  Widget _buildBodyScoreCard(BodyCompositionResult calc, Color Function(String) getStatusColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PUNTUACIÓN CORPORAL',
                    style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${calc.bodyScore}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Puntos',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  calc.bodyScore >= 80
                      ? 'Excelente estado físico. Continúa manteniendo tus buenos hábitos de alimentación y entrenamiento.'
                      : calc.bodyScore >= 70
                          ? 'Buen estado corporal. Se recomienda controlar la ingesta calórica, reducir grasas saturadas y seguir entrenando.'
                          : 'Puntuación regular. Se aconseja aumentar el entrenamiento de fuerza y optimizar el plan nutricional para ver mejoras.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IMC (Índice masa corporal)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          calc.imc.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          calc.getStatusImc().toUpperCase(),
                          style: TextStyle(color: getStatusColor(calc.getStatusImc()), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.white12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Porcentaje de grasa', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${calc.fatPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          calc.getStatusGrasa().toUpperCase(),
                          style: TextStyle(color: getStatusColor(calc.getStatusGrasa()), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBodyCompositionTopCard(BodyCompositionResult calc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPOSICIÓN CORPORAL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Silueta
              Container(
                width: 110,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: BodySilhouettePainter(
                    waterPercent: calc.waterPercentage / 100.0,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Valores absolutos
              Expanded(
                child: Column(
                  children: [
                    _buildCompositionRow('Masa de agua', '${calc.bodyWaterMass.toStringAsFixed(1)} kg'),
                    _buildCompositionRow('Masa grasa', '${calc.fatMass.toStringAsFixed(1)} kg'),
                    _buildCompositionRow('Masa mineral ósea', '${calc.boneMineralContent.toStringAsFixed(1)} kg'),
                    _buildCompositionRow('Masa proteica', '${calc.proteinMass.toStringAsFixed(1)} kg'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompositionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const Divider(color: Colors.white12, height: 12),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value.split(' ')[0],
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 2),
              if (value.split(' ').length > 1)
                Text(
                  value.split(' ')[1],
                  style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardFullWidth(String label, String value, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeMatrix(BodyCompositionResult calc, String tipoCuerpoEsp) {
    // 3x3 Matriz de tipos corporales
    final List<List<String>> matrix = [
      ['Muscular', 'Atlético (Fit)', 'Obeso Musc.'],
      ['Equilibrado', 'Normal', 'Sobrepeso'],
      ['Delgado', 'Bajo Peso', 'Obeso Oculto'],
    ];

    // Determinar celda activa
    int rowIdx = 1;
    if (calc.fatPercentage < (calc.esMasculino ? 11.0 : 21.0)) {
      rowIdx = 0; // Grasa Baja (Fila superior)
    } else if (calc.fatPercentage > (calc.esMasculino ? 21.9 : 32.9)) {
      rowIdx = 2; // Grasa Alta (Fila inferior)
    }

    int colIdx = 1;
    if (calc.imc < 18.5) {
      colIdx = 0; // IMC Bajo (Izquierda)
    } else if (calc.imc >= 25.0) {
      colIdx = 2; // IMC Alto (Derecha)
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TIPO DE CUERPO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                ),
                child: Text(
                  tipoCuerpoEsp.toUpperCase(),
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            border: TableBorder.all(color: Colors.white.withOpacity(0.05), width: 1),
            children: List.generate(3, (r) {
              return TableRow(
                children: List.generate(3, (c) {
                  final isActive = (r == rowIdx && c == colIdx);
                  return Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFD4AF37) : Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      matrix[r][c],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white70,
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightSuggestions(BodyCompositionResult calc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2133),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUGERENCIAS DE CONTROL',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          _buildSuggestionItem(
            icon: Icons.monitor_weight_outlined,
            color: Colors.blue,
            title: 'Peso estándar ideal',
            value: '${calc.standardWeight.toStringAsFixed(1)} kg',
          ),
          _buildSuggestionItem(
            icon: Icons.swap_vert,
            color: calc.weightControl < 0 ? Colors.redAccent : Colors.greenAccent,
            title: 'Control de peso',
            value: calc.weightControl == 0
                ? 'Mantener'
                : '${calc.weightControl > 0 ? "+" : ""}${calc.weightControl.toStringAsFixed(1)} kg',
          ),
          _buildSuggestionItem(
            icon: Icons.local_fire_department_outlined,
            color: calc.fatControl < 0 ? Colors.redAccent : Colors.greenAccent,
            title: 'Control de grasa',
            value: calc.fatControl == 0
                ? 'Mantener'
                : '${calc.fatControl > 0 ? "+" : ""}${calc.fatControl.toStringAsFixed(1)} kg',
          ),
          _buildSuggestionItem(
            icon: Icons.fitness_center_outlined,
            color: Colors.orangeAccent,
            title: 'Control de músculo',
            value: calc.muscleControl == 'Keep it up' ? 'Mantener' : calc.muscleControl,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PINTOR DE LA SILUETA HUMANA CON EL EFECTO DE AGUA (LIQUID FILL)
// ─────────────────────────────────────────────────────────────────────────────
class BodySilhouettePainter extends CustomPainter {
  final double waterPercent; // 0.0 a 1.0

  BodySilhouettePainter({required this.waterPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final paintBody = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.fill;

    final paintWater = Paint()
      ..color = Colors.blue.shade600
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Cabeza
    final headCenter = Offset(w / 2, h * 0.08);
    final headRadius = h * 0.06;
    path.addOval(Rect.fromCircle(center: headCenter, radius: headRadius));

    // Cuello
    path.moveTo(w * 0.44, h * 0.14);
    path.lineTo(w * 0.56, h * 0.14);
    path.lineTo(w * 0.56, h * 0.18);
    path.lineTo(w * 0.44, h * 0.18);
    path.close();

    // Hombros y Tronco
    path.moveTo(w * 0.30, h * 0.22);
    path.quadraticBezierTo(w * 0.40, h * 0.18, w * 0.44, h * 0.18);
    path.lineTo(w * 0.56, h * 0.18);
    path.quadraticBezierTo(w * 0.60, h * 0.18, w * 0.70, h * 0.22);
    
    // Brazo derecho
    path.lineTo(w * 0.76, h * 0.45);
    path.quadraticBezierTo(w * 0.74, h * 0.48, w * 0.70, h * 0.45);
    path.lineTo(w * 0.64, h * 0.32);
    
    // Costado derecho y cadera
    path.lineTo(w * 0.62, h * 0.55);
    
    // Pierna derecha
    path.lineTo(w * 0.58, h * 0.90);
    path.quadraticBezierTo(w * 0.55, h * 0.95, w * 0.52, h * 0.95);
    path.lineTo(w * 0.51, h * 0.58);
    
    // Pierna izquierda
    path.lineTo(w * 0.48, h * 0.95);
    path.quadraticBezierTo(w * 0.45, h * 0.95, w * 0.42, h * 0.90);
    path.lineTo(w * 0.38, h * 0.55);
    
    // Costado izquierdo
    path.lineTo(w * 0.36, h * 0.32);
    path.lineTo(w * 0.30, h * 0.45);
    path.quadraticBezierTo(w * 0.26, h * 0.48, w * 0.24, h * 0.45);
    path.close();

    // Dibujar fondo gris de la silueta
    canvas.drawPath(path, paintBody);

    // Dibujar líquido azul recortado por la silueta
    canvas.save();
    canvas.clipPath(path);
    final waterHeight = h * waterPercent;
    final rect = Rect.fromLTRB(0, h - waterHeight, w, h);
    canvas.drawRect(rect, paintWater);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ──────────────────────────────────────────────────────────────────────────
// PANTALLA INMERSIVA DE MEDICIÓN (ESTILO ZEPP LIFE)
// ──────────────────────────────────────────────────────────────────────────

class ScaleMeasurementScreen extends StatefulWidget {
  final ScaleDiagnosticController controller;
  final Function(ScaleMeasurement) onNavigateToReport;

  const ScaleMeasurementScreen({
    Key? key,
    required this.controller,
    required this.onNavigateToReport,
  }) : super(key: key);

  @override
  State<ScaleMeasurementScreen> createState() => _ScaleMeasurementScreenState();
}

class _ScaleMeasurementScreenState extends State<ScaleMeasurementScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});

    final lectura = widget.controller.lecturaActual;
    if (lectura != null) {
      if (!lectura.isFinal || (lectura.weight ?? 0) <= 0) {
        _hasNavigated = false;
      } else if (lectura.isFinal && !_hasNavigated && (lectura.weight ?? 0) > 0) {
        _hasNavigated = true;
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && widget.controller.lecturaActual?.isFinal == true) {
             Navigator.pop(context); // Cierra esta pantalla inmersiva
             widget.onNavigateToReport(widget.controller.lecturaActual!);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lectura = widget.controller.lecturaActual;
    final weight = lectura?.weight ?? 0.0;
    final isStabilized = lectura?.stabilized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Column(
          children: [
            Text(
              isStabilized ? 'Medición completada' : 'Midiendo...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  weight > 0 ? weight.toStringAsFixed(1) : '--.-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'kg',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                  ),
                ),
                if (isStabilized) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                ]
              ],
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.monitor_weight_outlined,
                  size: 140,
                  color: isStabilized ? Colors.greenAccent.withOpacity(0.5) : Colors.blueGrey.shade800,
                ),
                if (!isStabilized)
                  const SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Por favor mantente quieto.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isStabilized
                  ? '¡Listo! Generando resultados...'
                  : 'No muevas tus pies hasta que termine la medición.\nAsegúrate de que tus pies mantengan contacto total con los electrodos.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

