import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'scale_logger_service.dart';
import '../utils/scale_packet_parser.dart';

class BleConnectionService {
  final ScaleLoggerService _logger;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<StreamSubscription> _characteristicSubscriptions = [];

  BluetoothDevice? get connectedDevice => _connectedDevice;

  BleConnectionService(this._logger);

  Future<void> connect(BluetoothDevice device) async {
    if (kIsWeb) return; // BLE no disponible en web
    _logger.logConnect('Intentando conectar a ${device.platformName} [${device.remoteId}]...');
    _connectedDevice = device;

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.connected) {
        _logger.logConnect('Conectado exitosamente a ${device.remoteId}');
        _discoverServices();
      } else if (state == BluetoothConnectionState.disconnected) {
        _logger.logDisconnect('Desconectado de ${device.remoteId}');
        _clearSubscriptions();
      }
    });

    try {
      await device.connect(
        license: License.nonprofit,
        autoConnect: false,
        mtu: 512,
      );
    } catch (e) {
      _logger.logError('Error al conectar: $e');
    }
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      _logger.logDisconnect('Desconectando manualmente de ${_connectedDevice!.remoteId}...');
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;
    
    _logger.logInfo('Descubriendo servicios de ${_connectedDevice!.remoteId}...');
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      _logger.logInfo('¡Se encontraron ${services.length} servicios!');

      for (BluetoothService service in services) {
        _logger.logInfo('Servicio encontrado: ${service.uuid}');
        for (BluetoothCharacteristic c in service.characteristics) {
          _logger.logInfo('  - Característica: ${c.uuid}');
          _logger.logInfo('    Propiedades: read(${c.properties.read}), write(${c.properties.write}), notify(${c.properties.notify}), indicate(${c.properties.indicate})');
          
          if (c.properties.notify || c.properties.indicate) {
            await _subscribeToCharacteristic(c);
          }
        }
      }
    } catch (e) {
      _logger.logError('Error descubriendo servicios: $e');
    }
  }

  Future<void> _subscribeToCharacteristic(BluetoothCharacteristic c) async {
    try {
      if (!c.isNotifying) {
        await c.setNotifyValue(true);
        _logger.logInfo('Suscrito a notificaciones en ${c.uuid}');
      }
      
      final sub = c.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          _logger.log('NOTIFY', 'Dato recibido', uuid: c.uuid.toString(), data: value);
          ScalePacketParser.analyzePacket(c.uuid.toString(), value);
        }
      });
      _characteristicSubscriptions.add(sub);
    } catch (e) {
      _logger.logError('Error al suscribirse a ${c.uuid}: $e');
    }
  }

  Future<void> writeToCharacteristic(BluetoothCharacteristic c, List<int> value) async {
    try {
      _logger.log('WRITE', 'Enviando comando', uuid: c.uuid.toString(), data: value);
      await c.write(value, withoutResponse: !c.properties.write);
      _logger.logInfo('Comando enviado a ${c.uuid}');
    } catch (e) {
      _logger.logError('Error al escribir en ${c.uuid}: $e');
    }
  }

  void _clearSubscriptions() {
    for (var sub in _characteristicSubscriptions) {
      sub.cancel();
    }
    _characteristicSubscriptions.clear();
  }
}
