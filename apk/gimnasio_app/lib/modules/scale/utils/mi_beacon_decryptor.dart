import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Decriptador de paquetes MiBeacon v5 para la Xiaomi S400 (yunmai.scales.ms104).
///
/// La báscula transmite datos cifrados con AES-128-CCM en el UUID de servicio 0xFE95.
/// El proceso:
///   1. Extraer cabecera MiBeacon (tipo dispositivo, contador, MAC)
///   2. Construir el nonce (12 bytes)
///   3. Descifrar con AES-CCM usando la BLE Key
///   4. Parsear los 4 bytes del payload → peso, ritmo cardíaco, impedancia
///
/// Referencia: https://github.com/Bluetooth-Devices/xiaomi-ble
class MiBeaconDecryptor {
  // ─── Conversiones de hex ──────────────────────────────────────────────────

  /// Convierte una cadena hex (32 chars) en un Uint8List de 16 bytes.
  static Uint8List hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Convierte "AA:BB:CC:DD:EE:FF" en bytes [AA, BB, CC, DD, EE, FF].
  static Uint8List macToBytes(String mac) {
    return Uint8List.fromList(
      mac.split(':').map((s) => int.parse(s, radix: 16)).toList(),
    );
  }

  // ─── Estructura MiBeacon v5 ───────────────────────────────────────────────
  //
  //  Offset  Length  Campo
  //  0       2       Frame Control (little-endian)
  //  2       2       Device Type   (little-endian)  → 0x0489 para S400
  //  4       1       Frame Counter
  //  5       6       MAC (orden normal, NO invertida)
  //  11      ...     Payload cifrado + MIC (4 bytes) + Random (3 bytes)
  //
  // Nonce (13 bytes):
  //   [0:1]  Device Type  (little-endian)
  //   [2]    Frame Counter
  //   [3:8]  MAC revertida (FF:EE:DD:CC:BB:AA)
  //   [9:12] 0x00000000
  //
  // ─────────────────────────────────────────────────────────────────────────

  /// Intenta descifrar el payload del servicio 0xFE95.
  /// Retorna un [S400Measurement] si el paquete es válido, o null si falla.
  static S400Measurement? decrypt({
    required List<int> serviceData,   // Bytes del service data 0xFE95
    required String bleKeyHex,        // "6fff22e360b78cc705849f94c999c14a"
    required String macAddress,       // "04:AE:47:65:F2:C3"
  }) {
    try {
      if (serviceData.length < 5) return null;

      // Parsear cabecera
      final frameControl = (serviceData[1] << 8) | serviceData[0];
      final isEncrypted  = (frameControl & 0x0008) != 0;
      final macPresent   = (frameControl & 0x0010) != 0;
      final capPresent   = (frameControl & 0x0020) != 0;

      final deviceType   = Uint8List.fromList([serviceData[2], serviceData[3]]);
      final frameCounter = serviceData[4];

      int payloadOffset = 5;
      if (macPresent) payloadOffset += 6;
      if (capPresent) payloadOffset += 1;

      if (serviceData.length < payloadOffset) return null;

      // Payload y MIC (últimos 4 bytes son el MIC, antes hay 3 bytes de random nonce)
      final payloadWithMic = serviceData.sublist(payloadOffset);

      // Construir nonce: deviceType(2) + counter(1) + macReversed(6) + padding(4)
      final macBytes = macToBytes(macAddress);
      final macReversed = Uint8List.fromList(macBytes.reversed.toList());
      final nonce = Uint8List(12);
      nonce[0] = deviceType[0];
      nonce[1] = deviceType[1];
      nonce[2] = frameCounter;
      for (var i = 0; i < 6; i++) nonce[3 + i] = macReversed[i];
      // [9:11] queda en 0x00

      final key = hexToBytes(bleKeyHex);

      Uint8List decrypted;
      if (isEncrypted) {
        decrypted = _decryptAesCcm(
          key: key,
          nonce: nonce,
          ciphertext: Uint8List.fromList(payloadWithMic),
        );
      } else {
        // Algunos paquetes ya vienen sin cifrar (ej: anuncio de peso sin BIA)
        decrypted = Uint8List.fromList(payloadWithMic);
      }

      if (decrypted.length < 4) return null;
      return _parseMeasurement(decrypted);
    } catch (e, stack) {
      print('Error al descifrar MiBeacon: $e');
      print(stack);
      return null;
    }
  }

  // ─── Descifrado AES-128-CCM ───────────────────────────────────────────────

  static Uint8List _decryptAesCcm({
    required Uint8List key,
    required Uint8List nonce,
    required Uint8List ciphertext,
  }) {
    // Separar MIC (últimos 4 bytes) del ciphertext real
    final mic  = ciphertext.sublist(ciphertext.length - 4);
    final data = ciphertext.sublist(0, ciphertext.length - 4);

    final cipher = CCMBlockCipher(AESEngine());
    final params = AEADParameters(
      KeyParameter(key),
      32,   // 4 bytes de tag = 32 bits
      nonce,
      Uint8List(0), // sin AAD
    );

    cipher.init(false, params); // false = decrypt
    final result = cipher.process(Uint8List.fromList([...data, ...mic]));
    return result;
  }

  // ─── Parser del payload descifrado ────────────────────────────────────────
  //
  //  Los 4 bytes se interpretan como un entero de 32 bits (little-endian):
  //  Bits  0-10  → Peso        (valor / 10 = kg)
  //  Bits 11-17  → Frec. card. (valor + 50 = bpm, si disponible)
  //  Bits 18-31  → Impedancia  (valor / 10 = ohm)
  //
  static S400Measurement _parseMeasurement(Uint8List data) {
    final packed = ByteData.sublistView(data).getUint32(0, Endian.little);

    final rawWeight     = packed & 0x7FF;
    final rawHeartRate  = (packed >> 11) & 0x7F;
    final rawImpedance  = packed >> 18;

    final weight     = rawWeight / 10.0;           // kg
    final heartRate  = rawHeartRate > 0 ? rawHeartRate + 50 : null; // bpm
    final impedance  = rawImpedance > 0 ? rawImpedance / 10.0 : null; // ohm

    return S400Measurement(
      peso: weight,
      impedancia: impedance,
      frecuenciaCardiaca: heartRate?.toDouble(),
      estabilizado: rawWeight > 0,
    );
  }
}

// ─── Modelo de medición ───────────────────────────────────────────────────

class S400Measurement {
  final double peso;          // kg
  final double? impedancia;   // ohm
  final double? frecuenciaCardiaca; // bpm
  final bool estabilizado;    // true = la báscula confirmó el peso

  const S400Measurement({
    required this.peso,
    required this.impedancia,
    required this.frecuenciaCardiaca,
    required this.estabilizado,
  });

  @override
  String toString() =>
      'Peso: ${peso.toStringAsFixed(1)} kg'
      '${impedancia != null ? " | Imp: ${impedancia!.toStringAsFixed(1)} Ω" : ""}'
      '${frecuenciaCardiaca != null ? " | FC: ${frecuenciaCardiaca!.toStringAsFixed(0)} bpm" : ""}';
}
