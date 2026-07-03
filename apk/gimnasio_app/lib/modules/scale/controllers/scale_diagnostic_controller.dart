import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/scale_reading.dart';
import '../models/scale_measurement.dart';
import '../services/scale_logger_service.dart';
import '../services/ble_scanner_service.dart';
import '../services/ble_connection_service.dart';
import '../services/scale_repository.dart';
import '../../settings/admin_settings_tab.dart';
import '../utils/scale_packet_parser.dart';
import '../utils/body_composition_calculator.dart';
import '../services/s400_gatt_auth_service.dart';

/// Controlador principal del módulo de báscula.
/// Orquesta el escaneo BLE, la conexión, el logging y la persistencia en el backend.
class ScaleDiagnosticController extends ChangeNotifier {
  late final ScaleLoggerService logger;
  late final BleScannerService scanner;
  late final BleConnectionService connection;
  late final ScaleRepository _repository;
  S400GattAuthService? _s400AuthService;

  // ─── Estado BLE ───────────────────────────────────────────────────────────

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  final List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);

  BluetoothDevice? get connectedDevice => connection.connectedDevice;

  // ─── Estado del cliente seleccionado ─────────────────────────────────────

  Map<String, dynamic>? _cliente;
  Map<String, dynamic>? get cliente => _cliente;

  // ─── Estado del historial ─────────────────────────────────────────────────

  List<ScaleReading> _historial = [];
  List<ScaleReading> get historial => List.unmodifiable(_historial);

  bool _cargandoHistorial = false;
  bool get cargandoHistorial => _cargandoHistorial;

  String? _errorHistorial;
  String? get errorHistorial => _errorHistorial;

  // ─── Estado de guardado ───────────────────────────────────────────────────

  bool _guardando = false;
  bool get guardando => _guardando;

  String? _mensajeGuardado;
  String? get mensajeGuardado => _mensajeGuardado;

  // ─── Estado de Lectura en Tiempo Real ─────────────────────────────────────

  ScaleMeasurement? _lecturaActual;
  ScaleMeasurement? get lecturaActual => _lecturaActual;
  
  String? _authError;
  String? get authError => _authError;
  
  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  void limpiarLecturaActual() {
    _lecturaActual = null;
    notifyListeners();
  }

  // ─── Constructor ─────────────────────────────────────────────────────────

  ScaleDiagnosticController({
    required String baseUrl,
    Map<String, dynamic>? cliente,
  }) {
    logger = ScaleLoggerService();
    scanner = BleScannerService(logger);
    connection = BleConnectionService(logger);
    _repository = ScaleRepository(baseUrl: baseUrl);
    _cliente = cliente;

    if (cliente != null) {
      cargarHistorial();
      _inicializarClientePreseleccionado();
    }
  }

  Future<void> _inicializarClientePreseleccionado() async {
    if (_cliente == null) return;
    final cedula = _cliente!['documento']?.toString();
    if (cedula != null) {
      try {
        final estatura = await _repository.obtenerUltimaEstatura(cedula);
        _cliente!['estatura'] = estatura;
      } catch (_) {}
    }
  }

  // ─── Escaneo BLE ─────────────────────────────────────────────────────────

  Future<void> startScan() async {
    // Primero, descargar configuración global
    try {
      await AppSettings.fetchConfigFromBackend();
    } catch (_) {}

    final isBluetoothOn = await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    if (!isBluetoothOn) {
      logger.logInfo('Bluetooth apagado. Solicitando encender...');
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {}
      return;
    }

    logger.logInfo('Solicitando permisos BLE...');
    final permissionsGranted = await scanner.requestPermissions();

    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    final macAddress = await AppSettings.getScaleMac();
    final bleKeyHex = await AppSettings.getScaleKey();

    await scanner.startScan(onResult: (result) {
      final index = _scanResults.indexWhere(
        (r) => r.device.remoteId == result.device.remoteId,
      );
      if (index >= 0) {
        _scanResults[index] = result;
      } else {
        _scanResults.add(result);
      }

      // Procesar pasivamente anuncios de la báscula configurada
      if (macAddress.isNotEmpty && bleKeyHex.isNotEmpty) {
        final macHex = macAddress.replaceAll(':', '').toUpperCase();
        final deviceMacHex = result.device.remoteId.toString().replaceAll(':', '').toUpperCase();
        
        if (deviceMacHex == macHex) {
          for (final entry in result.advertisementData.serviceData.entries) {
            if (entry.key.toString().toLowerCase().contains('fe95')) {
              logger.logInfo('Báscula S400 detectada! Datos RAW: ${entry.value.map((e) => e.toRadixString(16).padLeft(2, '0')).join("")}');
              final parsed = ScalePacketParser.parseAdvertisement(
                serviceData: entry.value,
                bleKeyHex: bleKeyHex,
                macAddress: macAddress,
              );
              if (parsed != null) {
                logger.logInfo('Datos descifrados (S400): $parsed');
                _lecturaActual = parsed;
                notifyListeners();

                // Si estabilizado y hay cliente, guardar automáticamente
                if (parsed.stabilized && cliente != null && !_guardando) {
                  logger.logInfo('Peso estabilizado. Guardando...');
                  guardarPesaje(
                    peso: parsed.weight ?? 0.0,
                    impedancia: parsed.impedance?.toDouble(),
                  );
                }
              }
            }
          }
        }
      }

      notifyListeners();
    });

  }

  Future<void> stopScan() async {
    await scanner.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Future<void> configurarMacBascula(String mac) async {
    await AppSettings.saveScaleMac(mac);
    logger.logInfo('Nueva MAC de báscula configurada automáticamente: $mac');
    await stopScan();
    await startScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    _authError = null;
    _isAuthenticating = true;
    notifyListeners();
    
    try {
      await connection.connect(device);
      
      final bleKeyHex = await AppSettings.getScaleKey();
      if (bleKeyHex.isNotEmpty) {
        _s400AuthService?.dispose();
        _s400AuthService = S400GattAuthService(
          device: device,
          bleKeyHex: bleKeyHex,
          onLog: (msg) {
            if (msg.contains('ERROR')) {
              logger.logError(msg);
            } else {
              logger.logInfo(msg);
            }
          },
          onData: _procesarDatosS400,
        );
        await _s400AuthService!.authenticate();
      } else {
        _authError = 'Falta configurar el BLE Key en modo Admin';
        logger.logInfo('WARN: $_authError');
      }
    } catch (e) {
      _authError = e.toString();
      logger.logError('Error Auth S400: $e');
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  void _procesarDatosS400(Map<String, dynamic> data) {
    logger.logInfo('S400 CMTP: $data');
    
    final esFinal = data['type'] == 'final';
    final weight = data['weight_kg'] as double?;
    final impedance = data['impedance_ohm'] as double?;
    final stable = data['stable'] == true;
    
    if (weight != null) {
      _lecturaActual = ScaleMeasurement(
        weight: weight,
        impedance: impedance?.toInt(),
        stabilized: stable,
        isFinal: esFinal,
        date: DateTime.now(),
      );
      notifyListeners();
      if (cliente != null && !_guardando && esFinal) {
        logger.logInfo('Peso Final detectado. Guardando...');
        guardarPesaje(
          peso: weight,
          impedancia: impedance,
        );
      }
    }
  }

  Future<void> disconnect() async {
    _s400AuthService?.dispose();
    _s400AuthService = null;
    await connection.disconnect();
    notifyListeners();
  }

  // ─── Búsqueda de cliente (Admin) ──────────────────────────────────────────
  
  bool _buscandoCliente = false;
  bool get buscandoCliente => _buscandoCliente;

  String? _errorCliente;
  String? get errorCliente => _errorCliente;

  Future<void> buscarYSeleccionarCliente(String cedula) async {
    _buscandoCliente = true;
    _errorCliente = null;
    notifyListeners();

    try {
      final clienteEncontrado = await _repository.buscarClientePorCedula(cedula);
      if (clienteEncontrado != null) {
        _cliente = clienteEncontrado;
        // Intentar obtener la última estatura para cálculos BIA
        final estatura = await _repository.obtenerUltimaEstatura(cedula);
        _cliente!['estatura'] = estatura;
        await cargarHistorial();
      } else {
        _errorCliente = 'Cliente no encontrado';
        _cliente = null;
        _historial = [];
      }
    } catch (e) {
      _errorCliente = 'Error: ${e.toString()}';
      _cliente = null;
      _historial = [];
    } finally {
      _buscandoCliente = false;
      notifyListeners();
    }
  }

  void limpiarCliente() {
    _cliente = null;
    _historial = [];
    _errorCliente = null;
    notifyListeners();
  }

  // ─── Historial de pesajes ─────────────────────────────────────────────────

  Future<void> cargarHistorial() async {
    if (_cliente == null) return;
    final clienteId = _cliente!['id'] as int?;
    if (clienteId == null) return;

    _cargandoHistorial = true;
    _errorHistorial = null;
    notifyListeners();

    try {
      _historial = await _repository.obtenerHistorial(clienteId);
    } catch (e) {
      _errorHistorial = e.toString();
    } finally {
      _cargandoHistorial = false;
      notifyListeners();
    }
  }

  // ─── Guardar pesaje ───────────────────────────────────────────────────────

  /// Guarda el [peso] y los datos BIA opcionales en el backend para el cliente actual.
  Future<void> guardarPesaje({
    required double peso,
    double? impedancia,
    double? imc,
    double? porcentajeGrasa,
    double? porcentajeMuscular,
    double? porcentajeOseo,
    double? porcentajeLiquidos,
  }) async {
    if (_cliente == null) return;
    final clienteId = _cliente!['id'] as int?;
    if (clienteId == null) return;

    _guardando = true;
    _mensajeGuardado = null;
    notifyListeners();

    try {
      double? finalImc = imc;
      double? finalGrasa = porcentajeGrasa;
      double? finalMusculo = porcentajeMuscular;
      double? finalOseo = porcentajeOseo;
      double? finalLiquidos = porcentajeLiquidos;

      // Si tenemos impedancia pero faltan datos de composición, estimarlos
      if (impedancia != null && (finalGrasa == null || finalMusculo == null)) {
        final estaturaVal = _cliente?['estatura'] != null
            ? double.tryParse(_cliente!['estatura'].toString())
            : null;
        final estaturaCm = estaturaVal ?? (_cliente?['genero']?.toString().toUpperCase().contains('FEM') == true ? 160.0 : 170.0);
        
        final dobStr = _cliente?['fecha_nacimiento']?.toString();
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
        final esMasculino = _cliente?['genero']?.toString().toUpperCase().contains('FEM') != true;

        final calc = BodyCompositionCalculator.calcular(
          peso: peso,
          impedancia: impedancia,
          estaturaCm: estaturaCm,
          edad: edad,
          esMasculino: esMasculino,
        );

        finalImc ??= calc.imc;
        finalGrasa ??= calc.fatPercentage;
        finalMusculo ??= calc.musclePercentage;
        finalOseo ??= calc.bonePercentage;
        finalLiquidos ??= calc.waterPercentage;
      }

      final nuevo = ScaleReading(
        clienteId: clienteId,
        fechaPesaje: DateTime.now(),
        peso: peso,
        impedancia: impedancia,
        imc: finalImc,
        porcentajeGrasa: finalGrasa,
        porcentajeMuscular: finalMusculo,
        porcentajeOseo: finalOseo,
        porcentajeLiquidos: finalLiquidos,
      );

      final guardado = await _repository.guardarPesaje(nuevo);
      _historial.insert(0, guardado); // Insertar al inicio (más reciente primero)
      _mensajeGuardado = '✅ Pesaje guardado correctamente';
    } catch (e) {
      _mensajeGuardado = '❌ Error: ${e.toString()}';
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  // ─── Eliminar pesaje ──────────────────────────────────────────────────────

  Future<void> eliminarPesaje(int id) async {
    try {
      await _repository.eliminarPesaje(id);
      _historial.removeWhere((p) => p.id == id);
      notifyListeners();
    } catch (e) {
      _mensajeGuardado = '❌ Error al eliminar: ${e.toString()}';
      notifyListeners();
    }
  }

  // ─── Utilidades ──────────────────────────────────────────────────────────

  Future<void> exportLogs() async {
    await logger.exportLogsToJson();
  }
}
