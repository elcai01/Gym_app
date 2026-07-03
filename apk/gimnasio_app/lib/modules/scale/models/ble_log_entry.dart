class BleLogEntry {
  final DateTime timestamp;
  final String type; // e.g., 'INFO', 'ERROR', 'NOTIFY', 'WRITE', 'READ', 'CONNECT'
  final String? uuid;
  final List<int>? data;
  final String message;

  BleLogEntry({
    required this.type,
    required this.message,
    this.uuid,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'uuid': uuid,
      'message': message,
      'data_hex': data != null ? _toHex(data!) : null,
      'data_dec': data,
    };
  }

  String _toHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
  }

  @override
  String toString() {
    final hexData = data != null ? ' HEX: ${_toHex(data!)}' : '';
    final uuidStr = uuid != null ? ' [$uuid]' : '';
    return '[${timestamp.toIso8601String()}] [$type]$uuidStr $message$hexData';
  }
}
