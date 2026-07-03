import 'dart:convert';
import 'dart:typed_data';

class S400DataParser {
  /// Parsea el plaintext CMTP descifrado y devuelve el estado de la báscula.
  static Map<String, dynamic>? parsePayload(Uint8List pt) {
    // Buscar el delimitador 0xA0
    int idx = pt.indexOf(0xA0);
    if (idx < 0) return null;

    // Decodificar ASCII, saltando el 0xA0
    String s = ascii.decode(pt.sublist(idx + 1), allowInvalid: true);
    s = s.replaceAll('\x00', '').trim();
    
    List<String> parts = s.split(',');

    // Formato Live: "weight_x10,stable_flag"
    if (parts.length == 2) {
      double? w = double.tryParse(parts[0]);
      return {
        'type': 'live',
        'weight_kg': w != null ? w / 10.0 : null,
        'stable': parts[1] == '1',
      };
    }
    
    // Formato Final: "0,0,profile,weight_x10,stable,2,unix_ts,0..0,imp_x10,imp_low_x10"
    if (parts.length >= 8) {
      double? w = double.tryParse(parts[3]);
      double? imp = double.tryParse(parts[parts.length - 2]);
      
      return {
        'type': 'final',
        'weight_kg': w != null ? w / 10.0 : null,
        'stable': parts[4] == '1',
        'impedance_ohm': imp != null ? imp / 10.0 : null,
      };
    }
    
    return null;
  }
}
