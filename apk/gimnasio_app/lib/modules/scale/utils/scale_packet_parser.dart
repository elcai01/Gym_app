import 'hex_utils.dart';
import '../models/scale_measurement.dart';
import 'mi_beacon_decryptor.dart';

/// Parser de paquetes BLE para la Xiaomi S400 (yunmai.scales.ms104).
///
/// Soporta dos vías:
///   1. [analyzePacket]  — recibe notificaciones de características GATT (logs de diagnóstico)
///   2. [parseAdvertisement] — recibe el service data 0xFE95 del advertisement (modo producción)
class ScalePacketParser {
  // UUID del servicio MiBeacon de Xiaomi
  static const String kMiBeaconServiceUuid = 'fe95';

  /// Analiza un paquete GATT y lo imprime en consola para diagnóstico.
  static void analyzePacket(String uuid, List<int> bytes) {
    print('════════════════════════════════');
    print('PAQUETE BLE — UUID: $uuid');
    print('HEX: ${HexUtils.toHex(bytes)}');
    print('DEC: ${HexUtils.toDec(bytes)}');
    print('LEN: ${bytes.length} bytes');
    print('════════════════════════════════');
  }

  /// Intenta descifrar y parsear el service data del advertisement 0xFE95.
  ///
  /// [serviceData] — los bytes del service data con UUID 0xFE95.
  /// [bleKeyHex]   — "6fff22e360b78cc705849f94c999c14a"
  /// [macAddress]  — "04:AE:47:65:F2:C3"
  ///
  /// Retorna un [ScaleMeasurement] si se pudo interpretar, o null.
  static ScaleMeasurement? parseAdvertisement({
    required List<int> serviceData,
    required String bleKeyHex,
    required String macAddress,
  }) {
    if (bleKeyHex.isEmpty || macAddress.isEmpty) return null;

    final m = MiBeaconDecryptor.decrypt(
      serviceData: serviceData,
      bleKeyHex: bleKeyHex,
      macAddress: macAddress,
    );
    if (m == null) return null;

    return ScaleMeasurement(
      weight: m.peso,
      impedance: m.impedancia?.toInt(),
      stabilized: m.estabilizado,
      isFinal: m.estabilizado,
    );
  }

  /// Método de compatibilidad — retorna null hasta que tengamos datos reales de GATT.
  static ScaleMeasurement? parseMeasurement(List<int> bytes) => null;
}
