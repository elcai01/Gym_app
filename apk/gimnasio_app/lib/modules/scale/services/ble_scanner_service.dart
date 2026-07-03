import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'scale_logger_service.dart';

class BleScannerService {
  final ScaleLoggerService _logger;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // Filtro simple para detectar la báscula por nombre en el futuro
  static const List<String> _knownScaleNames = ['MIBFS', 'MIBCS', 'XIAOMI', 'S400'];

  BleScannerService(this._logger);

  Future<bool> requestPermissions() async {
    // BLE no está disponible en plataformas web
    if (kIsWeb) {
      _logger.logError('Bluetooth no disponible en la versión web.');
      return false;
    }

    _logger.logInfo('Solicitando permisos BLE...');

    // Importamos Platform solo en rutas no-web usando kIsWeb ya como guard
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    if (isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final allGranted = statuses.values.every((status) => status.isGranted);
      if (!allGranted) {
        _logger.logError('Permisos de Bluetooth o Ubicación denegados en Android.');
        return false;
      }

      // Intentar encender el Bluetooth si está apagado
      if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
        _logger.logInfo('Bluetooth apagado. Solicitando encender...');
        try {
          await FlutterBluePlus.turnOn();
          // Esperamos un momento a que el adaptador termine de encender
          int retry = 0;
          while (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on && retry < 5) {
            await Future.delayed(const Duration(milliseconds: 500));
            retry++;
          }
        } catch (e) {
          _logger.logError('Error al intentar encender Bluetooth: $e');
        }
      }
    } else if (isIOS) {
      final status = await Permission.bluetooth.request();
      if (!status.isGranted) {
        _logger.logError('Permiso de Bluetooth denegado en iOS.');
        return false;
      }
    }

    _logger.logInfo('Permisos concedidos.');
    return true;
  }

  Future<void> startScan({required void Function(ScanResult) onResult}) async {
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) return;

    if (FlutterBluePlus.isScanningNow) {
      await stopScan();
    }

    _logger.logInfo('Iniciando escaneo BLE...');
    
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Filtrar aquellos que no tienen nombre para evitar basura, o dejarlo abierto para debug
        // Para diagnóstico, mejor ver todos, pero alertar si detectamos la báscula
        final name = r.device.platformName.toUpperCase();
        if (_knownScaleNames.any((knownName) => name.contains(knownName))) {
          _logger.logInfo('¡Posible báscula Xiaomi detectada!: ${r.device.platformName} [${r.device.remoteId}]');
        }
        
        onResult(r);
      }
    }, onError: (e) {
      _logger.logError('Error durante el escaneo: $e');
    });

    if (kIsWeb) return;
    await FlutterBluePlus.startScan(timeout: const Duration(hours: 12));
  }

  Future<void> stopScan() async {
    _logger.logInfo('Deteniendo escaneo BLE.');
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
  }
}
