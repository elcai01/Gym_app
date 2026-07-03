import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ble_log_entry.dart';

class ScaleLoggerService extends ChangeNotifier {
  final List<BleLogEntry> _logs = [];

  List<BleLogEntry> get logs => List.unmodifiable(_logs);

  void log(String type, String message, {String? uuid, List<int>? data}) {
    final entry = BleLogEntry(
      type: type,
      message: message,
      uuid: uuid,
      data: data,
    );
    _logs.insert(0, entry); // Insertar al inicio para ver los más recientes arriba
    print(entry.toString());
    notifyListeners();
  }

  void logInfo(String message) => log('INFO', message);
  void logError(String message) => log('ERROR', message);
  void logConnect(String message) => log('CONNECT', message);
  void logDisconnect(String message) => log('DISCONNECT', message);

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<String?> exportLogsToJson() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/scale_ble_logs_${DateTime.now().millisecondsSinceEpoch}.json');
      
      final jsonList = _logs.map((e) => e.toJson()).toList();
      final jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);
      
      await file.writeAsString(jsonString);
      logInfo('Logs exportados a: ${file.path}');
      return file.path;
    } catch (e) {
      logError('Error exportando logs: $e');
      return null;
    }
  }
}
