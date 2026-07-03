import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' as pc;
import 's400_data_parser.dart';

class SessionKeys {
  final Uint8List devKey;
  final Uint8List appKey;
  final Uint8List devIv;
  final Uint8List appIv;
  SessionKeys(this.devKey, this.appKey, this.devIv, this.appIv);
}

class AsyncQueue<T> {
  final _controller = StreamController<T>();
  late final StreamIterator<T> _iterator;

  AsyncQueue() {
    _iterator = StreamIterator<T>(_controller.stream);
  }

  void add(T item) {
    _controller.add(item);
  }

  Future<T> next(Duration timeout) async {
    final hasNext = await _iterator.moveNext().timeout(timeout);
    if (hasNext) {
      return _iterator.current;
    }
    throw TimeoutException('Queue next timeout');
  }

  void dispose() {
    _iterator.cancel();
    _controller.close();
  }
}

class S400GattAuthService {
  final BluetoothDevice device;
  final String bleKeyHex;
  final Function(String) onLog;
  final Function(Map<String, dynamic>) onData;
  
  static const String SERVICE_UUID = "0000fe95-0000-1000-8000-00805f9b34fb";
  static const String UPNP_UUID = "00000010-0000-1000-8000-00805f9b34fb";
  static const String AVDTP_UUID = "00000019-0000-1000-8000-00805f9b34fb";
  static const String CMTP_UUID = "0000001b-0000-1000-8000-00805f9b34fb";
  
  static final Uint8List CMD_LOGIN = Uint8List.fromList([0x24, 0x00, 0x00, 0x00]);
  static final Uint8List CMD_SEND_KEY = Uint8List.fromList([0x00, 0x00, 0x00, 0x0b, 0x01, 0x00]);
  static final Uint8List CMD_SEND_INFO = Uint8List.fromList([0x00, 0x00, 0x00, 0x0a, 0x02, 0x00]);
  
  static final Uint8List RCV_RDY = Uint8List.fromList([0x00, 0x00, 0x01, 0x01]);
  static final Uint8List RCV_OK = Uint8List.fromList([0x00, 0x00, 0x01, 0x00]);
  static final Uint8List CFM_LOGIN_OK = Uint8List.fromList([0x21, 0x00, 0x00, 0x00]);
  
  BluetoothCharacteristic? _upnpChar;
  BluetoothCharacteristic? _avdtpChar;
  BluetoothCharacteristic? _cmtpChar;
  
  final _avdtpQueue = AsyncQueue<List<int>>();
  final _upnpQueue = AsyncQueue<List<int>>();
  
  SessionKeys? _sessionKeys;
  bool _isAuthenticated = false;
  
  StreamSubscription? _upnpSub;
  StreamSubscription? _avdtpSub;
  StreamSubscription? _cmtpSub;

  S400GattAuthService({
    required this.device,
    required this.bleKeyHex,
    required this.onLog,
    required this.onData,
  });
  
  Future<void> authenticate() async {
    try {
      onLog('INFO: Iniciando auth GATT S400...');
      final services = await device.discoverServices();
      BluetoothService? xiaomiService;
      for (var s in services) {
        final uuidStr = s.uuid.toString().toLowerCase();
        if (uuidStr.contains('fe95') || uuidStr == SERVICE_UUID) {
          xiaomiService = s;
          break;
        }
      }
      
      if (xiaomiService == null) {
        final found = services.map((s) => s.uuid.toString().length > 8 ? s.uuid.toString().substring(4, 8) : s.uuid.toString()).join(', ');
        throw Exception('No se encontro el servicio 0xFE95. Encontrados: $found');
      }
      
      for (var c in xiaomiService.characteristics) {
        final uuidStr = c.uuid.toString().toLowerCase();
        if (uuidStr.contains('0010') || uuidStr == UPNP_UUID) _upnpChar = c;
        if (uuidStr.contains('0019') || uuidStr == AVDTP_UUID) _avdtpChar = c;
        if (uuidStr.contains('001b') || uuidStr == CMTP_UUID) _cmtpChar = c;
      }
      
      if (_upnpChar == null || _avdtpChar == null || _cmtpChar == null) {
        final foundC = xiaomiService.characteristics.map((c) => c.uuid.toString().length > 8 ? c.uuid.toString().substring(4, 8) : c.uuid.toString()).join(', ');
        throw Exception('Faltan caracteristicas auth. Encontradas: $foundC');
      }
      
      _upnpSub = _upnpChar!.onValueReceived.listen((val) {
        if (val.isNotEmpty) _upnpQueue.add(val);
      });
      _avdtpSub = _avdtpChar!.onValueReceived.listen((val) {
        if (val.isNotEmpty) _avdtpQueue.add(val);
      });
      _cmtpSub = _cmtpChar!.onValueReceived.listen((val) {
        if (val.isNotEmpty) _handleCmtp(val);
      });
      
      await _upnpChar!.setNotifyValue(true);
      await _avdtpChar!.setNotifyValue(true);
      await _cmtpChar!.setNotifyValue(true);
      
      final appRand = _generateRandomBytes(16);
      
      await _write(_upnpChar!, CMD_LOGIN);
      await _write(_avdtpChar!, CMD_SEND_KEY);
      
      final rdy = await _expect(_avdtpQueue, RCV_RDY, const Duration(seconds: 10));
      
      await _writeParcel(_avdtpChar!, appRand);
      final ok = await _expect(_avdtpQueue, RCV_OK, const Duration(seconds: 5));
      
      final devRand = await _recvMultiframe(_avdtpQueue, const Duration(seconds: 5));
      final remoteInfo = await _recvMultiframe(_avdtpQueue, const Duration(seconds: 5));
      
      Uint8List token = _hexToBytes(bleKeyHex);
      
      onLog('CRYPTO-DEBUG: Token len=${token.length}, hex=${token.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      onLog('CRYPTO-DEBUG: appRand len=${appRand.length}, hex=${appRand.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      onLog('CRYPTO-DEBUG: devRand len=${devRand.length}, hex=${devRand.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      onLog('CRYPTO-DEBUG: remoteInfo len=${remoteInfo.length}, hex=${remoteInfo.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      
      // Intentar primero con token original
      _sessionKeys = await _deriveLoginKeys(token, appRand, devRand);
      final expectedRemote = await _hmacSha256(_sessionKeys!.devKey, Uint8List.fromList([...devRand, ...appRand]));
      
      onLog('CRYPTO-DEBUG: expectedRemote len=${expectedRemote.length}, hex=${expectedRemote.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
      
      if (!_listEquals(remoteInfo, expectedRemote)) {
        // Fallback a 12 bytes si el token original es 16 (algunas básculas usan solo 12 bytes de bindkey)
        if (token.length >= 12) {
          token = token.sublist(0, 12);
          _sessionKeys = await _deriveLoginKeys(token, appRand, devRand);
          final expectedRemote2 = await _hmacSha256(_sessionKeys!.devKey, Uint8List.fromList([...devRand, ...appRand]));
          if (!_listEquals(remoteInfo, expectedRemote2)) {
             throw Exception('HMAC mismatch. Token invalido o rotado.');
          }
        } else {
           throw Exception('HMAC mismatch con token de ${token.length} bytes.');
        }
      }
      
      final ourInfo = await _hmacSha256(_sessionKeys!.appKey, Uint8List.fromList([...appRand, ...devRand]));
      
      await _write(_avdtpChar!, CMD_SEND_INFO);
      final rdy2 = await _wait(_avdtpQueue, const Duration(seconds: 5));
      if (!_listEquals(rdy2, RCV_RDY)) throw Exception('Se esperaba RCV_RDY para SEND_INFO');
      
      await _writeParcel(_avdtpChar!, ourInfo);
      final ok2 = await _wait(_avdtpQueue, const Duration(seconds: 5));
      if (!_listEquals(ok2, RCV_OK)) throw Exception('Se esperaba RCV_OK para SEND_INFO');
      
      final loginResult = await _wait(_upnpQueue, const Duration(seconds: 5));
      if (!_listEquals(loginResult, CFM_LOGIN_OK)) {
        throw Exception('Login fallido, result: $loginResult');
      }
      
      _isAuthenticated = true;
      onLog('INFO: Autenticacion GATT exitosa! Esperando datos...');
      
    } catch (e) {
      onLog('ERROR: Auth GATT: $e');
      dispose();
      rethrow;
    }
  }
  
  bool _cmtpReceiving = false;
  int _cmtpExpectedFrames = 0;
  int _cmtpReceivedFrames = 0;
  final BytesBuilder _cmtpBuffer = BytesBuilder();

  void _handleCmtp(List<int> rawList) async {
    if (!_isAuthenticated || _sessionKeys == null) return;
    if (rawList.length < 4) return;

    if (rawList.length >= 6 && rawList[0] == 0 && rawList[1] == 0 && rawList[2] == 0) {
      _cmtpExpectedFrames = rawList[4] | (rawList[5] << 8);
      _cmtpReceiving = true;
      _cmtpReceivedFrames = 0;
      _cmtpBuffer.clear();
      await _write(_cmtpChar!, RCV_RDY);
      return;
    }

    if (_cmtpReceiving) {
      if (rawList.length >= 2) {
        _cmtpBuffer.add(rawList.sublist(2));
      }
      _cmtpReceivedFrames++;
      if (_cmtpReceivedFrames >= _cmtpExpectedFrames) {
        _cmtpReceiving = false;
        await _write(_cmtpChar!, RCV_OK);
        _processCmtpPayload(_cmtpBuffer.toBytes());
      }
      return;
    }
    
    _processCmtpPayload(Uint8List.fromList(rawList));
  }

  void _processCmtpPayload(Uint8List raw) {
    if (raw.length < 6) return;
    try {
      final iter = raw.sublist(0, 2);
      final ctAndMac = raw.sublist(2);
      if (ctAndMac.length < 4) return;
      
      final nonce = Uint8List.fromList([..._sessionKeys!.devIv, 0, 0, 0, 0, iter[0], iter[1], 0, 0]);
      
      final decrypted = _decryptCcm(ctAndMac, _sessionKeys!.devKey, nonce);
      final payload = S400DataParser.parsePayload(decrypted);
      
      if (payload != null) {
        onData(payload);
      }
    } catch(e) {
      onLog('ERROR descifrando CMTP: $e');
    }
  }
  
  Uint8List _decryptCcm(Uint8List ctAndMac, Uint8List key, Uint8List nonce) {
    final ccm = pc.CCMBlockCipher(pc.AESEngine());
    final params = pc.AEADParameters(
      pc.KeyParameter(key),
      32, 
      nonce,
      Uint8List(0),
    );
    ccm.init(false, params);
    return ccm.process(ctAndMac);
  }

  Future<SessionKeys> _deriveLoginKeys(Uint8List token, Uint8List appRand, Uint8List devRand) async {
    final salt = Uint8List.fromList([...appRand, ...devRand]);
    onLog('CRYPTO-DEBUG: salt len=${salt.length}, hex=${salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
    
    final hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 64);
    final secretKey = SecretKey(token);
    final derivedKey = await hkdf.deriveKey(
      secretKey: secretKey,
      nonce: salt,
      info: utf8.encode('mible-login-info'),
    );
    final bytes = await derivedKey.extractBytes();
    
    final devKey = Uint8List.fromList(bytes.sublist(0, 16));
    final appKey = Uint8List.fromList(bytes.sublist(16, 32));
    final devIv = Uint8List.fromList(bytes.sublist(32, 36));
    final appIv = Uint8List.fromList(bytes.sublist(36, 40));
    
    onLog('CRYPTO-DEBUG: devKey hex=${devKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
    onLog('CRYPTO-DEBUG: appKey hex=${appKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
    onLog('CRYPTO-DEBUG: devIv hex=${devIv.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
    onLog('CRYPTO-DEBUG: appIv hex=${appIv.map((b) => b.toRadixString(16).padLeft(2, '0')).join('')}');
    
    return SessionKeys(devKey, appKey, devIv, appIv);
  }

  Future<Uint8List> _hmacSha256(Uint8List key, Uint8List data) async {
    final hmac = Hmac(Sha256());
    final mac = await hmac.calculateMac(data, secretKey: SecretKey(key));
    return Uint8List.fromList(mac.bytes);
  }
  
  Future<List<int>> _wait(AsyncQueue<List<int>> q, Duration timeout) async {
    return await q.next(timeout);
  }

  Future<List<int>> _expect(AsyncQueue<List<int>> q, Uint8List expected, Duration timeout) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      final remaining = timeout - DateTime.now().difference(start);
      if (remaining.isNegative) break;
      try {
        final val = await q.next(remaining);
        if (_listEquals(val, expected)) return val;
        onLog('INFO: Ignorando paquete no esperado: $val');
      } catch (e) {
        break;
      }
    }
    throw Exception('Se esperaba $expected pero se acabo el tiempo');
  }

  Future<void> _write(BluetoothCharacteristic char, Uint8List data) async {
    final uuidStr = char.uuid.toString();
    final shortUuid = uuidStr.length > 8 ? uuidStr.substring(4, 8) : uuidStr;
    onLog('-> $shortUuid ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
    await char.write(data, withoutResponse: true);
  }
  
  Future<void> _writeParcel(BluetoothCharacteristic char, Uint8List data) async {
    int chunkSize = 18;
    for (int i = 0; i < data.length; i += chunkSize) {
      int end = i + chunkSize;
      if (end > data.length) end = data.length;
      final chunk = data.sublist(i, end);
      int n = (i ~/ chunkSize) + 1;
      final framed = Uint8List.fromList([n & 0xFF, (n >> 8) & 0xFF, ...chunk]);
      await _write(char, framed);
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<Uint8List> _recvMultiframe(AsyncQueue<List<int>> q, Duration timeout) async {
    final start = DateTime.now();
    List<int> first;
    while (true) {
      final remaining = timeout - DateTime.now().difference(start);
      if (remaining.isNegative) throw Exception('Timeout waiting for multiframe start');
      first = await _wait(q, remaining);
      if (first.length >= 6 && first[0] == 0 && first[1] == 0 && first[2] == 0) {
        break;
      } else {
        onLog('INFO: Ignorando primer frame no esperado: $first');
      }
    }
    final expected = first[4] | (first[5] << 8);
    await _write(_avdtpChar!, RCV_RDY);
    final buf = BytesBuilder();
    for (int i = 0; i < expected; i++) {
      final frame = await _wait(q, timeout);
      buf.add(frame.sublist(2));
    }
    await _write(_avdtpChar!, RCV_OK);
    return buf.toBytes();
  }

  Uint8List _generateRandomBytes(int length) {
    final rand = Random.secure();
    final data = Uint8List(length);
    for (int i = 0; i < length; i++) {
      data[i] = rand.nextInt(256);
    }
    return data;
  }
  
  Uint8List _hexToBytes(String hexStr) {
    final clean = hexStr.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final result = Uint8List(clean.length ~/ 2);
    for (int i = 0; i < clean.length; i += 2) {
      result[i ~/ 2] = int.parse(clean.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void dispose() {
    _upnpSub?.cancel();
    _avdtpSub?.cancel();
    _cmtpSub?.cancel();
    _avdtpQueue.dispose();
    _upnpQueue.dispose();
  }
}
