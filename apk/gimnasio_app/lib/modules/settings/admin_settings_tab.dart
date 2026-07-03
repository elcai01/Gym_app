import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gimnasio_app/main.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Claves de SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────
class AppSettingsKeys {
  static const String scaleMac    = 'setting_scale_mac';
  static const String scaleKey    = 'setting_scale_ble_key';
  static const String backendApiUrl = 'setting_backend_api_url';

  static const String defaultScaleMac    = '';
  static const String defaultScaleKey    = '';
  static const String defaultBackendApiUrl = 'https://api.gymstylelifeco.com';
}

// ─────────────────────────────────────────────────────────────────────────────
// Servicio de lectura rápida de la URL de la báscula (para usar en ScaleRepo)
// ─────────────────────────────────────────────────────────────────────────────
class AppSettings {
  static Future<String> getScaleMac() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppSettingsKeys.scaleMac) ?? AppSettingsKeys.defaultScaleMac;
  }

  static Future<String> getScaleKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppSettingsKeys.scaleKey) ?? AppSettingsKeys.defaultScaleKey;
  }

  static Future<String> getBackendApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppSettingsKeys.backendApiUrl) ??
        AppSettingsKeys.defaultBackendApiUrl;
  }

  static Future<void> saveScaleMac(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.scaleMac, mac.trim().toUpperCase());
    _syncConfigToBackend('scale_mac', mac.trim().toUpperCase());
  }

  static Future<void> saveScaleKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.scaleKey, key.trim());
    _syncConfigToBackend('scale_key', key.trim());
  }

  static Future<void> _syncConfigToBackend(String clave, String valor) async {
    try {
      final backendUrl = await getBackendApiUrl();
      if (backendUrl.isNotEmpty) {
        final uri = Uri.parse('$backendUrl/configuracion/');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'clave': clave, 'valor': valor}),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {}
  }

  static Future<void> fetchConfigFromBackend() async {
    try {
      final backendUrl = await getBackendApiUrl();
      if (backendUrl.isNotEmpty) {
        // Fetch MAC
        var uri = Uri.parse('$backendUrl/configuracion/scale_mac');
        var res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['valor'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppSettingsKeys.scaleMac, data['valor']);
          }
        }
        
        // Fetch Key
        uri = Uri.parse('$backendUrl/configuracion/scale_key');
        res = await http.get(uri).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['valor'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppSettingsKeys.scaleKey, data['valor']);
          }
        }
      }
    } catch (_) {}
  }

  static Future<void> saveBackendApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppSettingsKeys.backendApiUrl, url.trim());
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal — solo visible para ADMIN
// ─────────────────────────────────────────────────────────────────────────────
class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _scaleMacCtrl  = TextEditingController();
  final _scaleKeyCtrl  = TextEditingController();
  final _backendCtrl   = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;

  _TestState _testBackend = _TestState.idle;
  String _testBackendMsg  = '';

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _scaleMacCtrl.dispose();
    _scaleKeyCtrl.dispose();
    _backendCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarConfiguracion() async {
    final mac        = await AppSettings.getScaleMac();
    final key        = await AppSettings.getScaleKey();
    final backendUrl = await AppSettings.getBackendApiUrl();
    if (mounted) {
      setState(() {
        _scaleMacCtrl.text  = mac;
        _scaleKeyCtrl.text  = key;
        _backendCtrl.text   = backendUrl;
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    final mac        = _scaleMacCtrl.text.trim();
    final key        = _scaleKeyCtrl.text.trim();
    final backendUrl = _backendCtrl.text.trim();

    if (backendUrl.isEmpty) {
      _mostrarSnack('La URL del backend no puede estar vacía.', error: true);
      return;
    }

    // Validar formato MAC
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    if (mac.isNotEmpty && !macRegex.hasMatch(mac)) {
      _mostrarSnack('El formato del MAC debe ser AA:BB:CC:DD:EE:FF', error: true);
      return;
    }

    setState(() => _guardando = true);
    await AppSettings.saveScaleMac(mac);
    await AppSettings.saveScaleKey(key);
    await AppSettings.saveBackendApiUrl(backendUrl);
    if (mounted) {
      setState(() => _guardando = false);
      _mostrarSnack('✅ Configuración guardada correctamente.');
    }
  }

  Future<void> _probarConexion({required bool esBackend}) async {
    final url = _backendCtrl.text.trim();
    if (url.isEmpty) {
      _mostrarSnack('Ingresa la URL del backend primero.', error: true);
      return;
    }

    setState(() {
      _testBackend = _TestState.loading;
      _testBackendMsg = '';
    });

    try {
      final resp = await http.get(Uri.parse('$url/')).timeout(const Duration(seconds: 6));
      final ok = resp.statusCode >= 200 && resp.statusCode < 400;
      if (mounted) {
        setState(() {
          _testBackend = ok ? _TestState.ok : _TestState.error;
          _testBackendMsg = ok
              ? 'Conexión exitosa (${resp.statusCode})'
              : 'Respuesta inesperada: ${resp.statusCode}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _testBackend = _TestState.error;
          _testBackendMsg = 'No se pudo conectar. Verifica la URL y la red.';
        });
      }
    }
  }

  void _resetearDefecto({required bool esBackend}) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Restaurar valor por defecto', style: TextStyle(color: Colors.white)),
        content: Text(
          'Se restaurará la URL del backend a:\n${AppSettingsKeys.defaultBackendApiUrl}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmar == true && mounted) {
      setState(() {
        _backendCtrl.text = AppSettingsKeys.defaultBackendApiUrl;
        _testBackend = _TestState.idle;
        _testBackendMsg = '';
      });
    }
  }

  void _mostrarSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    return SingleChildScrollView(
      padding: AppResponsive.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Encabezado ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.settings, color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Configuración del Sistema',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Solo visible para administradores',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Tarjeta: Backend API ───────────────────────────────
              _buildCard(
                icon: Icons.cloud_outlined,
                titulo: 'URL del Backend principal',
                descripcion:
                    'Dirección del servidor FastAPI al que se conecta la app. '
                    'Cambia esto solo si el dominio del servidor cambió.',
                ctrl: _backendCtrl,
                testState: _testBackend,
                testMsg: _testBackendMsg,
                onTest: () => _probarConexion(esBackend: true),
                onReset: () => _resetearDefecto(esBackend: true),
                hint: 'https://api.gymstylelifeco.com',
              ),

              const SizedBox(height: 20),

              // ── Tarjeta: Báscula BLE ─────────────────────────────────────
              _buildScaleCard(),

              const SizedBox(height: 32),

              // ── Botón guardar ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Guardando...' : 'Guardar Configuración'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(0, 54),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Nota informativa ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.textSoft, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Los cambios se aplican de inmediato en la app. '
                        'No es necesario reiniciar. La configuración se guarda '
                        'localmente en este dispositivo.',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tarjeta especial para la báscula (2 campos: MAC + BLE Key) ──────────
  Widget _buildScaleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado
          Row(
            children: [
              const Icon(Icons.monitor_weight_outlined, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Báscula Xiaomi S400 — Configuración BLE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.textSoft.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Una sola vez', style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa los datos que obtienes al ejecutar el token_extractor.exe con tu cuenta Xiaomi. '
            'Solo se configura una vez y no cambia a menos que resetees la báscula.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),

          // Campo MAC
          const Text(
            'MAC Address',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _scaleMacCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', letterSpacing: 1.2),
            decoration: const InputDecoration(
              hintText: 'AA:BB:CC:DD:EE:FF',
              hintStyle: TextStyle(color: AppColors.textSoft, fontSize: 13),
              prefixIcon: Icon(Icons.bluetooth, color: AppColors.gold, size: 18),
            ),
            keyboardType: TextInputType.text,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
          ),

          const SizedBox(height: 16),

          // Campo Token
          const Text(
            'Token (24 caracteres hexadecimales)',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _scaleKeyCtrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13, letterSpacing: 1),
            decoration: const InputDecoration(
              hintText: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              hintStyle: TextStyle(color: AppColors.textSoft, fontSize: 13),
              prefixIcon: Icon(Icons.key_outlined, color: AppColors.gold, size: 18),
            ),
            obscureText: false,
            autocorrect: false,
            keyboardType: TextInputType.text,
          ),

          const SizedBox(height: 18),

          // Ayuda visual
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.tips_and_updates_outlined, color: AppColors.gold, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¿Cómo obtenerlos?\n'
                    '1. Descarga token_extractor.exe de GitHub (Xiaomi Cloud Tokens Extractor)\n'
                    '2. Ejecútalo e inicia sesión con tu cuenta Xiaomi\n'
                    '3. Busca "Body Composition Scale S400" en la lista\n'
                    '4. Busca el valor "TOKEN" (24 caracteres hexadecimales) y pégalo aquí. ¡OJO! No uses el "BLE KEY" o "BIND KEY" (32 caracteres), para la conexión en vivo necesitamos el TOKEN de 24 caracteres.',
                    style: TextStyle(color: AppColors.gold, fontSize: 12, height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String titulo,
    required String descripcion,
    required TextEditingController ctrl,
    required _TestState testState,
    required String testMsg,
    required VoidCallback onTest,
    required VoidCallback onReset,
    required String hint,
    bool opcional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (opcional)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.textSoft.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Opcional',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            style: const TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),

          // Campo de texto
          TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSoft, fontSize: 13),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () => ctrl.clear(),
                color: AppColors.textSoft,
                tooltip: 'Limpiar',
              ),
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            onChanged: (_) => setState(() {
              // Resetea el estado de test si el usuario edita
            }),
          ),

          const SizedBox(height: 12),

          // Fila de acciones
          Row(
            children: [
              // Botón probar
              OutlinedButton.icon(
                onPressed: testState == _TestState.loading ? null : onTest,
                icon: testState == _TestState.loading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                      )
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: const Text('Probar'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              // Botón restaurar
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restaurar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSoft,
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),

          // Resultado del test
          if (testMsg.isNotEmpty) ...[
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: testState == _TestState.ok
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: testState == _TestState.ok
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.danger.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    testState == _TestState.ok ? Icons.check_circle_outline : Icons.error_outline,
                    color: testState == _TestState.ok ? AppColors.success : AppColors.danger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      testMsg,
                      style: TextStyle(
                        color: testState == _TestState.ok ? AppColors.success : AppColors.danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _TestState { idle, loading, ok, error }
