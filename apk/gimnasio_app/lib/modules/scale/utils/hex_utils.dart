class HexUtils {
  static String toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  static String toDec(List<int> bytes) {
    return bytes.map((b) => b.toString()).join(' ');
  }

  static List<int> fromHex(String hexStr) {
    hexStr = hexStr.replaceAll(' ', '').trim();
    if (hexStr.length % 2 != 0) return [];
    
    final bytes = <int>[];
    for (int i = 0; i < hexStr.length; i += 2) {
      final byteStr = hexStr.substring(i, i + 2);
      final byte = int.tryParse(byteStr, radix: 16);
      if (byte != null) bytes.add(byte);
    }
    return bytes;
  }
}
