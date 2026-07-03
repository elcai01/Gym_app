import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gimnasio_app/utils/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const GymStyleLifeApp());
}

class GymStyleLifeApp extends StatelessWidget {
  const GymStyleLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Style Life',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldSoft,
          surface: AppColors.card,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 10,
          shadowColor: Colors.black.withOpacity(0.22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.input,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          labelStyle: const TextStyle(
            color: AppColors.textSoft,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.goldSoft,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(color: AppColors.textSoft),
          prefixIconColor: AppColors.gold,
          suffixIconColor: AppColors.textSoft,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.25),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.gold;
            return AppColors.textSoft;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.gold.withOpacity(0.35);
            }
            return AppColors.border;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class AppColors {
  static const Color background = Color(0xFF0B0B0C);
  static const Color card = Color(0xFF151517);
  static const Color input = Color(0xFF1D1D21);
  static const Color border = Color(0xFF2B2B31);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldSoft = Color(0xFFF0D77A);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color text = Color(0xFFF8F8F8);
  static const Color textSoft = Color(0xFFB8B8BE);
}

class ApiConfig {
  static const String baseUrl = 'https://api.gymstylelifeco.com';
}

class UserSession {
  final int id;
  final String nombre;
  final String username;
  final String rol;
  final int? clienteId;
  final bool activo;

  UserSession({
    required this.id,
    required this.nombre,
    required this.username,
    required this.rol,
    required this.clienteId,
    required this.activo,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      username: json['username'] ?? '',
      rol: (json['rol'] ?? '').toString().toUpperCase(),
      clienteId: json['cliente_id'],
      activo: json['activo'] ?? false,
    );
  }
}


class AppUi {
  static const List<String> tiposDocumento = [
    'CC',
    'TI',
    'CE',
    'PASAPORTE',
    'NIT',
  ];

  static const List<String> estadosCliente = ['ACTIVO', 'INACTIVO'];

  static const List<String> opcionesGenero = [
    'Masculino',
    'Femenino',
    'Prefiero no decirlo',
    'Otro',
  ];

  static TextInputType decimalKeyboard() {
    return const TextInputType.numberWithOptions(decimal: true);
  }

  static Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSoft,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}


class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

class AppResponsive {
  static const double mobileBreakpoint = 720;
  static const double desktopBreakpoint = 1100;
  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 980;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 28, vertical: 22);
    }
    if (width >= mobileBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 22, vertical: 18);
    }
    return const EdgeInsets.all(16);
  }

  static Widget body({
    required BuildContext context,
    required Widget child,
    double maxWidth = maxContentWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: pagePadding(context),
          child: child,
        ),
      ),
    );
  }

  static Widget tabBody(BuildContext context, Widget child, {double? maxWidth}) {
    return body(
      context: context,
      maxWidth: maxWidth ?? maxContentWidth,
      child: child,
    );
  }

  static double fieldWidth(BuildContext context, {int columns = 2}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      const spacing = 12.0;
      return (maxFormWidth - (spacing * (columns - 1))) / columns;
    }
    if (width >= mobileBreakpoint) {
      return 320;
    }
    return double.infinity;
  }

  static Widget formWrap(BuildContext context, List<Widget> children) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: fieldWidth(context),
              child: child,
            ),
          )
          .toList(),
    );
  }

  static Widget formWrap3(BuildContext context, List<Widget> children) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map(
            (child) => SizedBox(
              width: isDesktop(context) ? 300 : fieldWidth(context),
              child: child,
            ),
          )
          .toList(),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.fitness_center,
              size: 40,
              color: AppColors.gold,
            ),
          );
        },
      ),
    );
  }
}


class NetworkExerciseMedia extends StatelessWidget {
  final String url;
  final double height;

  const NetworkExerciseMedia({
    super.key,
    required this.url,
    this.height = 190,
  });

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _placeholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const CircularProgressIndicator(color: AppColors.gold),
          );
        },
        errorBuilder: (_, __, ___) => _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.fitness_center, size: 42, color: AppColors.gold),
          SizedBox(height: 8),
          Text(
            'Sin imagen disponible',
            style: TextStyle(color: AppColors.textSoft),
          ),
        ],
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _claveController = TextEditingController();

  String _mensaje = '';
  bool _ocultarClave = true;
  bool _cargando = false;

  Future<void> iniciarSesion() async {
    final usuario = _usuarioController.text.trim();
    final clave = _claveController.text.trim();

    if (usuario.isEmpty || clave.isEmpty) {
      setState(() => _mensaje = 'Debes ingresar usuario y contraseña.');
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final resp = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': usuario, 'password': clave}),
      );

      final data =
          resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final session = UserSession.fromJson(data);

        if (!mounted) return;

        if (session.rol == 'ADMIN') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => AdminHomePage(session: session)),
          );
        } else if (session.rol == 'CLIENTE') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ClientHomePage(session: session)),
          );
        } else {
          setState(() => _mensaje = 'Rol no soportado: ${session.rol}');
        }
      } else {
        setState(() {
          _mensaje = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : 'No se pudo iniciar sesión.';
        });
      }
    } catch (e) {
      setState(() => _mensaje = 'Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esDesktop = AppResponsive.isDesktop(context);

    final formulario = Card(
      child: Padding(
        padding: EdgeInsets.all(esDesktop ? 28 : 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!esDesktop) ...[
              const AppLogo(size: 120),
              const SizedBox(height: 16),
            ],
            Text(
              'Gym Style Life',
              style: TextStyle(
                fontSize: esDesktop ? 34 : 30,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ingreso por base de datos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSoft,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _usuarioController,
              style: const TextStyle(color: AppColors.text),
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _claveController,
              obscureText: _ocultarClave,
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _ocultarClave = !_ocultarClave);
                  },
                  icon: Icon(
                    _ocultarClave ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.gold,
                  ),
                ),
              ),
              onSubmitted: (_) => _cargando ? null : iniciarSesion(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _cargando ? null : iniciarSesion,
                icon: _cargando
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_cargando ? 'Ingresando...' : 'Entrar'),
              ),
            ),
            if (_mensaje.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _mensaje,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF050505), Color(0xFF111111), Color(0xFF1A1405)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: esDesktop ? 1150 : 430),
                child: esDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  AppLogo(size: 150),
                                  SizedBox(height: 24),
                                  Text(
                                    'Administra tu gimnasio desde celular o navegador',
                                    style: TextStyle(
                                      fontSize: 38,
                                      height: 1.15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'La misma app ahora también queda lista para verse mucho mejor en pantallas grandes, con formularios más cómodos, navegación más limpia y mejor experiencia en escritorio.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: AppColors.textSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 430,
                            child: formulario,
                          ),
                        ],
                      )
                    : formulario,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminHomePage extends StatefulWidget {
  final UserSession session;

  const AdminHomePage({super.key, required this.session});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _tabIndex = 0;

  final TextEditingController _cedulaController = TextEditingController();
  bool _cargando = false;
  String _mensaje = '';
  Map<String, dynamic>? _cliente;
  List<dynamic> _membresias = [];
  List<dynamic> _usuarios = [];
  List<Map<String, dynamic>> _alertasMensualidades = [];
  bool _cargandoAlertasMensualidades = false;

  static const Map<int, int> planesDuracion = {
    1: 1,
    2: 7,
    3: 15,
    4: 30,
    5: 90,
  };

  static const Map<int, String> planesNombre = {
    1: 'DIARIO',
    2: 'SEMANAL',
    3: 'QUINCENAL',
    4: 'MENSUAL',
    5: 'TRIMESTRAL',
  };

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
    cargarAlertasMensualidades();
  }

  Future<void> cargarUsuarios() async {
    try {
      final resp = await ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/usuarios'));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        if (mounted) {
          setState(() => _usuarios = data);
        }
      }
    } catch (_) {}
  }

  Future<void> buscarClientePorCedula() async {
    final cedula = _cedulaController.text.trim();

    if (cedula.isEmpty) {
      setState(() {
        _mensaje = 'Debes ingresar una cédula.';
        _cliente = null;
        _membresias = [];
      });
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = '';
      _cliente = null;
      _membresias = [];
    });

    try {
      final clienteResp = await ApiClient.get(
        Uri.parse('${ApiConfig.baseUrl}/clientes/por-cedula/$cedula'),
      );

      if (clienteResp.statusCode == 404) {
        setState(() {
          _mensaje = 'No se encontró un cliente con esa cédula.';
          _cargando = false;
        });
        return;
      }

      if (clienteResp.statusCode != 200) {
        setState(() {
          _mensaje = 'No se pudo consultar la API de clientes.';
          _cargando = false;
        });
        return;
      }

      final Map<String, dynamic> clienteEncontrado =
          Map<String, dynamic>.from(jsonDecode(clienteResp.body));

      final membresiasResp =
          await ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/membresias/'));

      List<dynamic> membresiasCliente = [];
      if (membresiasResp.statusCode == 200) {
        final List<dynamic> todas = jsonDecode(membresiasResp.body);
        membresiasCliente = todas
            .where((m) => m['cliente_id'] == clienteEncontrado['id'])
            .toList();
        membresiasCliente
            .sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      }

      setState(() {
        _cliente = clienteEncontrado;
        _membresias = membresiasCliente;
        _mensaje = '';
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Map<String, dynamic>? obtenerMembresiaPrincipal() {
    if (_membresias.isEmpty) return null;
    final activas = _membresias
        .where((m) => (m['estado'] ?? '').toString().toUpperCase() == 'ACTIVA')
        .toList();
    if (activas.isNotEmpty) {
      activas.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      return Map<String, dynamic>.from(activas.first);
    }
    return Map<String, dynamic>.from(_membresias.first);
  }

  String obtenerEstadoMembresiaTexto(Map<String, dynamic>? membresia) {
    if (membresia == null) return 'SIN MEMBRESÍA';
    final estado = (membresia['estado'] ?? '').toString().toUpperCase();
    final fechaFin = (membresia['fecha_fin'] ?? '').toString();
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);

    DateTime? fechaFinDate;
    try {
      fechaFinDate = DateTime.parse(fechaFin);
    } catch (_) {
      fechaFinDate = null;
    }

    if (estado == 'CANCELADA') return 'CANCELADA';
    if (estado == 'VENCIDA') return 'VENCIDA';

    if (fechaFinDate != null) {
      final finSoloFecha =
          DateTime(fechaFinDate.year, fechaFinDate.month, fechaFinDate.day);
      if (finSoloFecha.isBefore(hoySoloFecha)) return 'VENCIDA';
    }

    if (estado == 'ACTIVA') return 'ACTIVA';
    return estado.isEmpty ? 'SIN ESTADO' : estado;
  }

  int? obtenerDiasRestantes(Map<String, dynamic>? membresia) {
    if (membresia == null) return null;
    try {
      final fechaFin =
          DateTime.parse((membresia['fecha_fin'] ?? '').toString());
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
      return fin.difference(hoy).inDays;
    } catch (_) {
      return null;
    }
  }

  Color obtenerColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVA':
        return AppColors.success;
      case 'VENCIDA':
      case 'CANCELADA':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String formatearPlan(int? planId) {
    if (planId == null) return 'SIN PLAN';
    return planesNombre[planId] ?? 'PLAN $planId';
  }

  String formatDate(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$anio-$mes-$dia';
  }

  String calcularFechaFin(String fechaInicio, int duracionDias) {
    final fecha = DateTime.parse(fechaInicio);
    final nueva = fecha.add(Duration(days: duracionDias));
    return formatDate(nueva);
  }

  String calcularNuevaFechaFinPorPago({
    required String fechaFinActual,
    required int duracionDias,
  }) {
    final hoy = DateTime.now();
    final hoySolo = DateTime(hoy.year, hoy.month, hoy.day);

    DateTime base;
    try {
      final finActual = DateTime.parse(fechaFinActual);
      final finSolo = DateTime(finActual.year, finActual.month, finActual.day);
      base = finSolo.isBefore(hoySolo) ? hoySolo : finSolo;
    } catch (_) {
      base = hoySolo;
    }

    final nuevaFecha = base.add(Duration(days: duracionDias));
    return formatDate(nuevaFecha);
  }


  DateTime _soloFecha(DateTime fecha) => DateTime(fecha.year, fecha.month, fecha.day);

  int? _parseEntero(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  DateTime? _parseFecha(dynamic valor) {
    if (valor == null) return null;
    try {
      return DateTime.parse(valor.toString());
    } catch (_) {
      return null;
    }
  }

  String _armarNombreCliente(Map<String, dynamic> cliente) {
    final nombres = (cliente['nombres'] ?? '').toString().trim();
    final apellidos = (cliente['apellidos'] ?? '').toString().trim();
    final nombreCompleto = '$nombres $apellidos'.trim();
    return nombreCompleto.isEmpty ? 'Cliente sin nombre' : nombreCompleto;
  }

  String _limpiarNumeroWhatsapp(Map<String, dynamic> cliente) {
    final whatsapp = (cliente['whatsapp'] ?? cliente['telefono'] ?? '').toString();
    return whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _crearMensajeWhatsAppMensualidad({
    required Map<String, dynamic> cliente,
    required Map<String, dynamic> membresia,
    required bool vencida,
    required int diasRestantes,
  }) {
    final nombre = _armarNombreCliente(cliente);
    final plan = formatearPlan(_parseEntero(membresia['plan_id']));
    final fechaFin = (membresia['fecha_fin'] ?? '').toString();

    if (vencida) {
      return 'Hola $nombre, te escribimos de Gym Style Life. Tu membresía $plan ya se encuentra vencida desde $fechaFin. Te invitamos a realizar el pago para renovarla y seguir entrenando con nosotros.';
    }

    if (diasRestantes == 0) {
      return 'Hola $nombre, te escribimos de Gym Style Life. Tu membresía $plan vence hoy ($fechaFin). Te invitamos a realizar tu pago para renovarla a tiempo.';
    }

    return 'Hola $nombre, te escribimos de Gym Style Life. Tu membresía $plan vence en $diasRestantes día${diasRestantes == 1 ? '' : 's'} (fecha: $fechaFin). Te recordamos realizar tu pago para evitar que se venza.';
  }

  Future<void> abrirWhatsAppCliente({
    required Map<String, dynamic> cliente,
    String? mensaje,
  }) async {
    final numero = _limpiarNumeroWhatsapp(cliente);

    if (numero.isEmpty) {
      mostrarMensaje('Este cliente no tiene número registrado.', esError: true);
      return;
    }

    final texto = Uri.encodeComponent(
      mensaje ??
          'Hola ${_armarNombreCliente(cliente)}, te escribimos de Gym Style Life.',
    );

    final uri = Uri.parse('https://wa.me/57$numero?text=$texto');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      mostrarMensaje('No se pudo abrir WhatsApp.', esError: true);
    }
  }

  Future<void> confirmarPagoMembresia({
    required Map<String, dynamic> cliente,
    required Map<String, dynamic> membresia,
    bool recargarBusquedaActual = true,
  }) async {
    final int planId = (_parseEntero(membresia['plan_id'])) ?? 4;
    final int duracion = planesDuracion[planId] ?? 30;
    final String fechaFinActual = (membresia['fecha_fin'] ?? '').toString();
    final String nuevaFechaFin = calcularNuevaFechaFinPorPago(
      fechaFinActual: fechaFinActual,
      duracionDias: duracion,
    );

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirmar pago',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cliente: ${_armarNombreCliente(cliente)}',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                Text(
                  'Plan actual: ${formatearPlan(planId)}',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                Text(
                  'Fecha fin actual: $fechaFinActual',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Si confirmas que YA PAGÓ, se renovará automáticamente.\n\nNueva fecha fin: $nuevaFechaFin',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                        label: const Text('No'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check),
                        label: const Text('Sí, ya pagó'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmado != true) return;

    try {
      final resp = await ApiClient.put(
        Uri.parse('${ApiConfig.baseUrl}/membresias/${membresia['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'estado': 'ACTIVA',
          'fecha_fin': nuevaFechaFin,
          'observaciones':
              'Pago confirmado desde APK por ${widget.session.username}',
        }),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        mostrarMensaje('Pago confirmado y membresía actualizada.');
        await cargarAlertasMensualidades();
        if (recargarBusquedaActual && _cliente != null) {
          final idClienteActual = _parseEntero(_cliente!['id']);
          final idClientePago = _parseEntero(cliente['id']);
          if (idClienteActual != null && idClienteActual == idClientePago) {
            await recargarClienteActual();
          }
        }
      } else {
        mostrarMensaje(
          body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo actualizar la membresía.',
          esError: true,
        );
      }
    } catch (e) {
      mostrarMensaje('Error actualizando pago: $e', esError: true);
    }
  }


  Future<void> eliminarClienteCompletoDesdeMensualidades({
    required Map<String, dynamic> cliente,
  }) async {
    final cedula = (cliente['documento'] ?? '').toString().trim();
    final nombre = _armarNombreCliente(cliente);

    if (cedula.isEmpty) {
      mostrarMensaje('No se encontró la cédula del cliente.', esError: true);
      return;
    }

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Eliminar cliente',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cliente: $nombre',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                Text(
                  'Cédula: $cedula',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: const Text(
                    'Esta acción eliminará completamente al cliente, su usuario, membresías, pagos, asistencias, medidas y rutinas. No se puede deshacer.',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, false),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmado != true) return;

    try {
      final resp = await ApiClient.delete(
        Uri.parse('${ApiConfig.baseUrl}/clientes/por-cedula/$cedula/eliminar-completo'),
        headers: {'accept': 'application/json'},
      );

      dynamic body;
      if (resp.body.isNotEmpty) {
        try {
          body = jsonDecode(resp.body);
        } catch (_) {
          body = resp.body;
        }
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        mostrarMensaje('Cliente eliminado definitivamente.');
        await cargarAlertasMensualidades();

        final clienteActualCedula = (_cliente?['documento'] ?? '').toString().trim();
        if (clienteActualCedula == cedula && mounted) {
          setState(() {
            _cliente = null;
            _membresias = [];
            _mensaje = '';
          });
        }
      } else {
        String detalle = 'No se pudo eliminar el cliente.';
        if (body is Map && body['detail'] != null) {
          detalle = body['detail'].toString();
        } else if (body is String && body.trim().isNotEmpty) {
          detalle = body.trim();
        }
        mostrarMensaje(detalle, esError: true);
      }
    } catch (e) {
      mostrarMensaje('Error eliminando cliente: $e', esError: true);
    }
  }

  Future<void> cargarAlertasMensualidades() async {
    if (!mounted) return;

    setState(() {
      _cargandoAlertasMensualidades = true;
    });

    try {
      final clientesResp =
          await ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/clientes/'));
      final membresiasResp =
          await ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/membresias/'));

      if (clientesResp.statusCode != 200 || membresiasResp.statusCode != 200) {
        if (mounted) {
          setState(() {
            _cargandoAlertasMensualidades = false;
          });
        }
        return;
      }

      final List<dynamic> clientesData = jsonDecode(clientesResp.body);
      final List<dynamic> membresiasData = jsonDecode(membresiasResp.body);

      final Map<int, Map<String, dynamic>> clientesPorId = {};
      for (final c in clientesData) {
        if (c is Map<String, dynamic>) {
          final id = _parseEntero(c['id']);
          if (id != null) {
            clientesPorId[id] = c;
          }
        } else if (c is Map) {
          final mapa = Map<String, dynamic>.from(c);
          final id = _parseEntero(mapa['id']);
          if (id != null) {
            clientesPorId[id] = mapa;
          }
        }
      }

      final hoy = _soloFecha(DateTime.now());
      final List<Map<String, dynamic>> alertas = [];

      for (final m in membresiasData) {
        final membresia = m is Map<String, dynamic>
            ? m
            : (m is Map ? Map<String, dynamic>.from(m) : null);

        if (membresia == null) continue;

        final clienteId = _parseEntero(membresia['cliente_id']);
        if (clienteId == null) continue;

        final cliente = clientesPorId[clienteId];
        if (cliente == null) continue;

        final fechaFin = _parseFecha(membresia['fecha_fin']);
        if (fechaFin == null) continue;

        final estado = (membresia['estado'] ?? '').toString().toUpperCase();
        if (estado == 'CANCELADA') continue;

        final diasRestantes = _soloFecha(fechaFin).difference(hoy).inDays;
        final bool vencida = estado == 'VENCIDA' || diasRestantes < 0;
        final bool porVencer = !vencida && diasRestantes <= 3;

        if (!vencida && !porVencer) continue;

        alertas.add({
          'cliente': cliente,
          'membresia': membresia,
          'dias_restantes': diasRestantes,
          'vencida': vencida,
          'titulo_estado': vencida
              ? 'Vencida'
              : (diasRestantes == 0 ? 'Vence hoy' : 'Por vencer'),
        });
      }

      alertas.sort((a, b) {
        final av = (a['vencida'] == true) ? 0 : 1;
        final bv = (b['vencida'] == true) ? 0 : 1;
        if (av != bv) return av.compareTo(bv);
        return ((a['dias_restantes'] as int?) ?? 9999)
            .compareTo((b['dias_restantes'] as int?) ?? 9999);
      });

      if (mounted) {
        setState(() {
          _alertasMensualidades = alertas;
          _cargandoAlertasMensualidades = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoAlertasMensualidades = false;
        });
      }
    }
  }

  String _textoDiasAlerta(int diasRestantes, bool vencida) {
    if (vencida) {
      final diasVencida = diasRestantes.abs();
      return diasVencida == 0
          ? 'Venció hoy'
          : 'Vencida hace $diasVencida día${diasVencida == 1 ? '' : 's'}';
    }

    if (diasRestantes == 0) return 'Vence hoy';
    return 'Vence en $diasRestantes día${diasRestantes == 1 ? '' : 's'}';
  }

  Widget mensualidadesTab() {
    final vencidas =
        _alertasMensualidades.where((e) => e['vencida'] == true).length;
    final porVencer = _alertasMensualidades.length - vencidas;

    return RefreshIndicator(
      onRefresh: cargarAlertasMensualidades,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.gold),
                      SizedBox(width: 8),
                      Text(
                        'Mensualidades',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Aquí ves clientes con membresías vencidas o a punto de vencer. Desde esta pestaña puedes avisar por WhatsApp o registrar el pago de una vez.',
                    style: TextStyle(color: AppColors.textSoft),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _resumenChip(
                        icon: Icons.cancel,
                        texto: 'Vencidas: $vencidas',
                        color: AppColors.danger,
                      ),
                      _resumenChip(
                        icon: Icons.schedule,
                        texto: 'Por vencer: $porVencer',
                        color: AppColors.warning,
                      ),
                      _resumenChip(
                        icon: Icons.list_alt,
                        texto: 'Total: ${_alertasMensualidades.length}',
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _cargandoAlertasMensualidades
                          ? null
                          : cargarAlertasMensualidades,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_cargandoAlertasMensualidades)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            )
          else if (_alertasMensualidades.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: const [
                    Icon(Icons.verified, color: AppColors.success, size: 42),
                    SizedBox(height: 10),
                    Text(
                      'No hay mensualidades vencidas ni próximas a vencer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._alertasMensualidades.map((item) {
              final cliente = Map<String, dynamic>.from(item['cliente']);
              final membresia = Map<String, dynamic>.from(item['membresia']);
              final diasRestantes = (item['dias_restantes'] as int?) ?? 0;
              final vencida = item['vencida'] == true;
              final estadoTexto = _textoDiasAlerta(diasRestantes, vencida);
              final colorEstado =
                  vencida ? AppColors.danger : AppColors.warning;
              final numero = _limpiarNumeroWhatsapp(cliente);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorEstado.withOpacity(0.15),
                            child: Icon(
                              vencida ? Icons.error : Icons.notifications_active,
                              color: colorEstado,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _armarNombreCliente(cliente),
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Cédula: ${cliente['documento'] ?? ''}',
                                  style: const TextStyle(
                                    color: AppColors.textSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorEstado,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item['titulo_estado'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      infoTile(
                        icon: Icons.fitness_center,
                        titulo: 'Plan',
                        valor: formatearPlan(_parseEntero(membresia['plan_id'])),
                      ),
                      infoTile(
                        icon: Icons.event_busy,
                        titulo: 'Fecha fin',
                        valor: '${membresia['fecha_fin'] ?? ''}',
                      ),
                      infoTile(
                        icon: Icons.timelapse,
                        titulo: 'Estado',
                        valor: estadoTexto,
                      ),
                      infoTile(
                        icon: Icons.phone,
                        titulo: 'WhatsApp',
                        valor: numero.isEmpty ? 'No registrado' : numero,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: numero.isEmpty
                                ? null
                                : () => abrirWhatsAppCliente(
                                      cliente: cliente,
                                      mensaje:
                                          _crearMensajeWhatsAppMensualidad(
                                        cliente: cliente,
                                        membresia: membresia,
                                        vencida: vencida,
                                        diasRestantes: diasRestantes,
                                      ),
                                    ),
                            icon: const Icon(Icons.message),
                            label: const Text('Avisar por WhatsApp'),
                          ),
                          FilledButton.icon(
                            onPressed: () => confirmarPagoMembresia(
                              cliente: cliente,
                              membresia: membresia,
                              recargarBusquedaActual: true,
                            ),
                            icon: const Icon(Icons.attach_money),
                            label: const Text('Marcar pago'),
                          ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: vencida
                                ? () => eliminarClienteCompletoDesdeMensualidades(
                                      cliente: cliente,
                                    )
                                : null,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _resumenChip({
    required IconData icon,
    required String texto,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void cerrarSesion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void mostrarMensaje(String texto, {bool esError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: esError ? AppColors.danger : AppColors.gold,
      ),
    );
  }

  Future<void> recargarClienteActual() async {
    if (_cliente == null) return;
    _cedulaController.text = (_cliente!['documento'] ?? '').toString();
    await buscarClientePorCedula();
    await cargarUsuarios();
  }

  Future<void> abrirWhatsApp() async {
    if (_cliente == null) return;
    await abrirWhatsAppCliente(cliente: _cliente!);
  }

  bool clienteYaTieneUsuario() {
    if (_cliente == null) return false;
    final idCliente = _cliente!['id'];
    return _usuarios.any((u) => u['cliente_id'] == idCliente);
  }

  Future<void> abrirModalCrearUsuarioCliente() async {
    if (_cliente == null) {
      mostrarMensaje('Primero debes buscar un cliente.', esError: true);
      return;
    }

    if (clienteYaTieneUsuario()) {
      mostrarMensaje('Este cliente ya tiene usuario creado.', esError: true);
      return;
    }

    final passwordController = TextEditingController();

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Crear usuario cliente',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cliente: ${_cliente!['nombres']} ${_cliente!['apellidos']}',
                  style: const TextStyle(color: AppColors.textSoft),
                ),
                const SizedBox(height: 8),
                Text(
                  'Usuario automático: ${_cliente!['documento']}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppColors.text),
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Crear usuario'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmado != true) return;

    final username = (_cliente!['documento'] ?? '').toString().trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      mostrarMensaje('Debes escribir la contraseña.', esError: true);
      return;
    }

    try {
      final resp = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cliente_id': _cliente!['id'],
          'username': username,
          'password': password,
        }),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        mostrarMensaje('Usuario cliente creado correctamente.');
        await cargarUsuarios();
      } else {
        mostrarMensaje(
          body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo crear el usuario cliente.',
          esError: true,
        );
      }
    } catch (e) {
      mostrarMensaje('Error creando usuario cliente: $e', esError: true);
    }
  }

  Future<void> abrirNuevoIngreso() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const NuevoIngresoPage()),
    );

    if (creado == true) {
      mostrarMensaje('Nuevo ingreso registrado correctamente.');
      await cargarUsuarios();
      if (_cedulaController.text.trim().isNotEmpty) {
        await buscarClientePorCedula();
      }
    }
  }

  Future<void> abrirModalPago() async {
    final cliente = _cliente;
    final membresia = obtenerMembresiaPrincipal();

    if (cliente == null) {
      mostrarMensaje('Primero debes buscar un cliente.', esError: true);
      return;
    }

    if (membresia == null) {
      mostrarMensaje('El cliente no tiene membresía registrada.',
          esError: true);
      return;
    }

    await confirmarPagoMembresia(
      cliente: cliente,
      membresia: membresia,
      recargarBusquedaActual: true,
    );
  }

  Future<void> abrirModalMembresia() async {
    final cliente = _cliente;

    if (cliente == null) {
      mostrarMensaje('Primero debes buscar un cliente.', esError: true);
      return;
    }

    int? planSeleccionado;
    final fechaController = TextEditingController(
      text: DateTime.now().toIso8601String().split('T').first,
    );

    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.card,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String fechaFinCalculada = '';
            if (planSeleccionado != null && fechaController.text.isNotEmpty) {
              fechaFinCalculada = calcularFechaFin(
                fechaController.text,
                planesDuracion[planSeleccionado]!,
              );
            }

            Widget botonPlan(int id, String nombre) {
              final activo = planSeleccionado == id;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          activo ? AppColors.gold : AppColors.input,
                      foregroundColor: activo ? Colors.black : AppColors.text,
                      side: BorderSide(
                        color: activo ? AppColors.gold : AppColors.border,
                      ),
                    ),
                    onPressed: () {
                      setModalState(() => planSeleccionado = id);
                    },
                    child: Text(nombre, textAlign: TextAlign.center),
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nueva membresía',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cliente: ${cliente['nombres']} ${cliente['apellidos']}',
                      style: const TextStyle(color: AppColors.textSoft),
                    ),
                    Text(
                      'Cédula: ${cliente['documento']}',
                      style: const TextStyle(color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Selecciona el plan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [botonPlan(1, 'Diario'), botonPlan(2, 'Semanal')],
                    ),
                    Row(
                      children: [
                        botonPlan(3, 'Quincenal'),
                        botonPlan(4, 'Mensual'),
                      ],
                    ),
                    Row(
                      children: [
                        botonPlan(5, 'Trimestral'),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fechaController,
                      readOnly: true,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Fecha inicio',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      onTap: () async {
                        DateTime initialDate;
                        try {
                          initialDate = fechaController.text.trim().isNotEmpty
                              ? DateTime.parse(fechaController.text.trim())
                              : DateTime.now();
                        } catch (_) {
                          initialDate = DateTime.now();
                        }

                        final picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: AppColors.gold,
                                  onPrimary: Colors.black,
                                  surface: AppColors.card,
                                  onSurface: AppColors.text,
                                ),
                                dialogTheme: const DialogThemeData(
                                  backgroundColor: AppColors.card,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked != null) {
                          fechaController.text =
                              picked.toIso8601String().split('T').first;
                          setModalState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (planSeleccionado != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.input,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Plan: ${planesNombre[planSeleccionado]}\nFecha fin calculada: $fechaFinCalculada',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.card_membership),
                        label: const Text('Crear membresía'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmado != true) return;

    if (planSeleccionado == null) {
      mostrarMensaje('Debes seleccionar un plan.', esError: true);
      return;
    }

    final fechaInicio = fechaController.text.trim();
    if (fechaInicio.isEmpty) {
      mostrarMensaje('Debes ingresar la fecha de inicio.', esError: true);
      return;
    }

    final fechaFin = calcularFechaFin(
      fechaInicio,
      planesDuracion[planSeleccionado]!,
    );

    try {
      final activas = _membresias
          .where((m) => (m['estado'] ?? '').toString().toUpperCase() == 'ACTIVA')
          .toList();

      for (final membresia in activas) {
        await ApiClient.put(
          Uri.parse('${ApiConfig.baseUrl}/membresias/${membresia['id']}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'estado': 'CANCELADA',
            'observaciones':
                'Cancelada automáticamente desde APK por ${widget.session.username}',
          }),
        );
      }

      final payload = {
        'cliente_id': cliente['id'],
        'plan_id': planSeleccionado,
        'fecha_inicio': fechaInicio,
        'fecha_fin': fechaFin,
        'estado': 'ACTIVA',
        'observaciones':
            'Membresía creada desde APK por ${widget.session.username}',
      };

      final resp = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/membresias/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : null;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        mostrarMensaje('Membresía creada correctamente.');
        await recargarClienteActual();
      } else {
        mostrarMensaje(
          body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo crear la membresía.',
          esError: true,
        );
      }
    } catch (e) {
      mostrarMensaje('Error creando membresía: $e', esError: true);
    }
  }

  Widget infoTile({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget topSummary(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.gold),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSoft,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget clientesTab() {
    final membresiaPrincipal = obtenerMembresiaPrincipal();
    final estadoMembresia = obtenerEstadoMembresiaTexto(membresiaPrincipal);
    final diasRestantes = obtenerDiasRestantes(membresiaPrincipal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              topSummary('Usuario', widget.session.username, Icons.person),
              const SizedBox(width: 10),
              topSummary('Rol', widget.session.rol, Icons.security),
              const SizedBox(width: 10),
              topSummary(
                'Estado cliente',
                _cliente == null ? 'Sin búsqueda' : estadoMembresia,
                Icons.verified,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.search, color: AppColors.gold),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Buscar cliente por cédula',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cedulaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.text),
                    decoration: const InputDecoration(
                      labelText: 'Cédula',
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _cargando ? null : buscarClientePorCedula,
                          icon: _cargando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: Text(_cargando ? 'Buscando...' : 'Buscar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: abrirNuevoIngreso,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Nuevo ingreso'),
                        ),
                      ),
                    ],
                  ),
                  if (_mensaje.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _mensaje,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_cliente != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.person, color: AppColors.gold),
                        SizedBox(width: 8),
                        Text(
                          'Datos del cliente',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    infoTile(
                      icon: Icons.badge,
                      titulo: 'Cédula',
                      valor: '${_cliente!['documento'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.person_outline,
                      titulo: 'Nombre',
                      valor:
                          '${_cliente!['nombres'] ?? ''} ${_cliente!['apellidos'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.phone,
                      titulo: 'Teléfono',
                      valor: '${_cliente!['telefono'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.chat,
                      titulo: 'WhatsApp',
                      valor: '${_cliente!['whatsapp'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.verified_user,
                      titulo: 'Estado cliente',
                      valor: '${_cliente!['estado'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.account_circle,
                      titulo: 'Usuario cliente',
                      valor: clienteYaTieneUsuario() ? 'YA CREADO' : 'AÚN NO CREADO',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Estado membresía: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: obtenerColorEstado(estadoMembresia),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            estadoMembresia,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (membresiaPrincipal != null) ...[
                      infoTile(
                        icon: Icons.confirmation_number,
                        titulo: 'ID Membresía',
                        valor: '${membresiaPrincipal['id']}',
                      ),
                      infoTile(
                        icon: Icons.fitness_center,
                        titulo: 'Plan',
                        valor: formatearPlan(membresiaPrincipal['plan_id'] as int?),
                      ),
                      infoTile(
                        icon: Icons.event_available,
                        titulo: 'Fecha inicio',
                        valor: '${membresiaPrincipal['fecha_inicio']}',
                      ),
                      infoTile(
                        icon: Icons.event_busy,
                        titulo: 'Fecha fin',
                        valor: '${membresiaPrincipal['fecha_fin']}',
                      ),
                      infoTile(
                        icon: Icons.timelapse,
                        titulo: 'Días restantes',
                        valor: diasRestantes == null ? 'N/D' : '$diasRestantes',
                      ),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.input,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'Este cliente no tiene membresía registrada.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: abrirWhatsApp,
                          icon: const Icon(Icons.message),
                          label: const Text('Abrir WhatsApp'),
                        ),
                        FilledButton.icon(
                          onPressed: abrirModalCrearUsuarioCliente,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Usuario cliente'),
                        ),
                        FilledButton.icon(
                          onPressed: abrirModalMembresia,
                          icon: const Icon(Icons.card_membership),
                          label: const Text('Membresía'),
                        ),
                        FilledButton.icon(
                          onPressed: abrirModalPago,
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Pago'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget medidasTab() => AdminMedidasTab(
        colorError: AppColors.danger,
        baseUrl: ApiConfig.baseUrl,
      );

  Widget rutinasTab() => AdminRutinasAutoTab(
        colorError: AppColors.danger,
        baseUrl: ApiConfig.baseUrl,
      );

  @override
  Widget build(BuildContext context) {
    final tabs = [clientesTab(), mensualidadesTab(), medidasTab(), rutinasTab()];
    final esDesktop = AppResponsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(size: 38),
            SizedBox(width: 10),
            Text(
              'Gym Style Life',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${widget.session.username} (${widget.session.rol})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout, color: AppColors.text),
          ),
        ],
      ),
      body: esDesktop
          ? Row(
              children: [
                Container(
                  width: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      right: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: NavigationRail(
                    backgroundColor: Colors.transparent,
                    selectedIndex: _tabIndex,
                    onDestinationSelected: (v) => setState(() => _tabIndex = v),
                    labelType: NavigationRailLabelType.all,
                    selectedIconTheme: const IconThemeData(color: Colors.black),
                    selectedLabelTextStyle: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                    indicatorColor: AppColors.gold,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.people, color: AppColors.textSoft),
                        label: Text('Clientes'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.warning_amber_rounded, color: AppColors.textSoft),
                        label: Text('Alertas'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.monitor_weight, color: AppColors.textSoft),
                        label: Text('Medidas'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome, color: AppColors.textSoft),
                        label: Text('Rutinas'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AppResponsive.tabBody(
                    context,
                    tabs[_tabIndex],
                    maxWidth: 1400,
                  ),
                ),
              ],
            )
          : tabs[_tabIndex],
      bottomNavigationBar: esDesktop
          ? null
          : NavigationBar(
              backgroundColor: AppColors.card,
              indicatorColor: AppColors.gold.withOpacity(0.18),
              selectedIndex: _tabIndex,
              onDestinationSelected: (v) => setState(() => _tabIndex = v),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.people), label: 'Clientes'),
                NavigationDestination(icon: Icon(Icons.warning_amber_rounded), label: 'Mensualidades'),
                NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Medidas'),
                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rutinas'),
              ],
            ),
    );
  }
}



class NuevoIngresoPage extends StatefulWidget {
  const NuevoIngresoPage({super.key});

  @override
  State<NuevoIngresoPage> createState() => _NuevoIngresoPageState();
}

class _NuevoIngresoPageState extends State<NuevoIngresoPage> {
  final _formKey = GlobalKey<FormState>();

  final tipoDocumento = TextEditingController();
  final documento = TextEditingController();
  final nombres = TextEditingController();
  final apellidos = TextEditingController();
  final fechaNacimiento = TextEditingController();
  final genero = TextEditingController();
  String? generoSeleccionado;
  final generoOtro = TextEditingController();
  final telefono = TextEditingController();
  final whatsapp = TextEditingController();
  final email = TextEditingController();
  final direccion = TextEditingController();
  final contactoEmergenciaNombre = TextEditingController();
  final contactoEmergenciaTelefono = TextEditingController();
  final fechaIngreso = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final estado = TextEditingController(text: 'ACTIVO');
  final observacionesCliente = TextEditingController();

  final password = TextEditingController();

  final peso = TextEditingController();
  final estatura = TextEditingController();
  final torax = TextEditingController();
  final bicepsIzq = TextEditingController();
  final bicepsDer = TextEditingController();
  final abdomenSup = TextEditingController();
  final abdomenInf = TextEditingController();
  final cadera = TextEditingController();
  final muslo = TextEditingController();
  final pantorrilla = TextEditingController();
  final grasa = TextEditingController();
  final muscular = TextEditingController();
  final oseo = TextEditingController();
  final liquidos = TextEditingController();
  final biotipo = TextEditingController();
  final objetivo = TextEditingController();
  final gastoEnergetico = TextEditingController();
  final fuma = TextEditingController();
  final bebe = TextEditingController();
  final horasSueno = TextEditingController();
  final otrosDeportes = TextEditingController();
  final lesiones = TextEditingController();
  final cirugias = TextEditingController();
  final observacionesMedidas = TextEditingController();

  bool crearUsuario = true;
  bool guardarMedidas = true;
  bool cargando = false;
  String mensaje = '';

  InputDecoration _dec(
    String label,
    IconData icon, {
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: Icon(icon),
    );
  }

  Future<void> _seleccionarFecha(
    BuildContext context,
    TextEditingController controller, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    DateTime initialDate;
    try {
      initialDate = controller.text.trim().isNotEmpty
          ? DateTime.parse(controller.text.trim())
          : DateTime.now();
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: AppColors.text,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
      if (mounted) setState(() {});
    }
  }

  String? _generoFinal() {
    final v = (generoSeleccionado ?? '').trim();
    if (v.isEmpty) return null;
    if (v == 'Otro') {
      return generoOtro.text.trim().isEmpty ? 'Otro' : generoOtro.text.trim();
    }
    return v;
  }

  Widget _campo(
    TextEditingController controller,
    String label, {
    TextInputType tipo = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData icon = Icons.edit_note,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tipo,
      maxLines: maxLines,
      validator: validator,
      obscureText: obscure,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: _dec(label, icon, helperText: helperText),
    );
  }

  Widget _dropdownCampo({
    required String label,
    required IconData icon,
    required List<String> opciones,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: AppColors.card,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w600,
      ),
      decoration: _dec(label, icon),
      validator: validator,
      items: opciones
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  double? _num(TextEditingController c) {
    final t = c.text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  double? _calcImc() {
    final p = _num(peso);
    final e = _num(estatura);
    if (p == null || e == null || e <= 0) return null;
    final est = e > 3 ? e / 100.0 : e;
    return p / (est * est);
  }

  Future<void> guardarTodo() async {
    if (!_formKey.currentState!.validate()) return;

    if (crearUsuario && password.text.trim().isEmpty) {
      setState(() => mensaje = 'Debes escribir la contraseña del usuario cliente.');
      return;
    }

    setState(() {
      cargando = true;
      mensaje = '';
    });

    try {
      final clienteResp = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/clientes/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tipo_documento': tipoDocumento.text.trim().isEmpty ? 'CC' : tipoDocumento.text.trim(),
          'documento': documento.text.trim(),
          'nombres': nombres.text.trim(),
          'apellidos': apellidos.text.trim(),
          'fecha_nacimiento': fechaNacimiento.text.trim().isEmpty ? null : fechaNacimiento.text.trim(),
          'genero': _generoFinal(),
          'telefono': telefono.text.trim().isEmpty ? null : telefono.text.trim(),
          'whatsapp': whatsapp.text.trim().isEmpty ? null : whatsapp.text.trim(),
          'email': email.text.trim().isEmpty ? null : email.text.trim(),
          'direccion': direccion.text.trim().isEmpty ? null : direccion.text.trim(),
          'contacto_emergencia_nombre': contactoEmergenciaNombre.text.trim().isEmpty ? null : contactoEmergenciaNombre.text.trim(),
          'contacto_emergencia_telefono': contactoEmergenciaTelefono.text.trim().isEmpty ? null : contactoEmergenciaTelefono.text.trim(),
          'foto_url': null,
          'fecha_ingreso': fechaIngreso.text.trim(),
          'estado': estado.text.trim().isEmpty ? 'ACTIVO' : estado.text.trim(),
          'observaciones': observacionesCliente.text.trim().isEmpty ? null : observacionesCliente.text.trim(),
        }),
      );

      final clienteBody = clienteResp.body.isNotEmpty ? jsonDecode(clienteResp.body) : {};
      if (clienteResp.statusCode < 200 || clienteResp.statusCode >= 300) {
        setState(() {
          mensaje = clienteBody is Map && clienteBody['detail'] != null
              ? clienteBody['detail'].toString()
              : 'No se pudo crear el cliente.';
        });
        return;
      }

      final int clienteId = clienteBody['id'];

      if (guardarMedidas) {
        final imcValor = _calcImc();
        final evalResp = await ApiClient.post(
          Uri.parse('${ApiConfig.baseUrl}/evaluaciones-fisicas/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cliente_id': clienteId,
            'fecha_evaluacion': fechaIngreso.text.trim(),
            'peso': _num(peso),
            'estatura': _num(estatura),
            'imc': imcValor == null ? null : double.parse(imcValor.toStringAsFixed(2)),
            'torax': _num(torax),
            'biceps_izq': _num(bicepsIzq),
            'biceps_der': _num(bicepsDer),
            'abdomen_sup': _num(abdomenSup),
            'abdomen_inf': _num(abdomenInf),
            'cadera': _num(cadera),
            'muslo': _num(muslo),
            'pantorrilla': _num(pantorrilla),
            'porcentaje_grasa': _num(grasa),
            'porcentaje_muscular': _num(muscular),
            'porcentaje_oseo': _num(oseo),
            'porcentaje_liquidos': _num(liquidos),
            'biotipo': biotipo.text.trim().isEmpty ? null : biotipo.text.trim(),
            'objetivo': objetivo.text.trim().isEmpty ? null : objetivo.text.trim(),
            'gasto_energetico': gastoEnergetico.text.trim().isEmpty ? null : gastoEnergetico.text.trim(),
            'fuma': fuma.text.trim().isEmpty ? null : fuma.text.trim(),
            'bebe': bebe.text.trim().isEmpty ? null : bebe.text.trim(),
            'horas_sueno': horasSueno.text.trim().isEmpty ? null : horasSueno.text.trim(),
            'otros_deportes': otrosDeportes.text.trim().isEmpty ? null : otrosDeportes.text.trim(),
            'lesiones': lesiones.text.trim().isEmpty ? null : lesiones.text.trim(),
            'cirugias': cirugias.text.trim().isEmpty ? null : cirugias.text.trim(),
            'observaciones': observacionesMedidas.text.trim().isEmpty ? null : observacionesMedidas.text.trim(),
          }),
        );

        if (evalResp.statusCode < 200 || evalResp.statusCode >= 300) {
          final body = evalResp.body.isNotEmpty ? jsonDecode(evalResp.body) : {};
          setState(() {
            mensaje = body is Map && body['detail'] != null
                ? 'Cliente creado, pero medidas fallaron: ${body['detail']}'
                : 'Cliente creado, pero no se pudieron guardar las medidas.';
          });
          return;
        }
      }

      if (crearUsuario) {
        final userResp = await ApiClient.post(
          Uri.parse('${ApiConfig.baseUrl}/usuarios/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'cliente_id': clienteId,
            'username': documento.text.trim(),
            'password': password.text.trim(),
          }),
        );

        if (userResp.statusCode < 200 || userResp.statusCode >= 300) {
          final body = userResp.body.isNotEmpty ? jsonDecode(userResp.body) : {};
          setState(() {
            mensaje = body is Map && body['detail'] != null
                ? 'Cliente creado, pero usuario falló: ${body['detail']}'
                : 'Cliente creado, pero no se pudo crear el usuario.';
          });
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => mensaje = 'Error: $e');
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Widget _seccion(String titulo, List<Widget> children, {String? subtitulo}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppUi.sectionTitle(titulo, subtitle: subtitulo),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esDesktop = AppResponsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo ingreso'),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppResponsive.maxFormWidth),
            child: ListView(
              padding: EdgeInsets.all(esDesktop ? 22 : 16),
              children: [
            _seccion(
              'Datos básicos',
              [
                _dropdownCampo(
                  label: 'Tipo documento',
                  icon: Icons.badge_outlined,
                  opciones: AppUi.tiposDocumento,
                  value: tipoDocumento.text.trim().isEmpty
                      ? 'CC'
                      : tipoDocumento.text.trim(),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                  onChanged: (v) => setState(() => tipoDocumento.text = v ?? 'CC'),
                ),
                const SizedBox(height: 12),
                _campo(
                  documento,
                  'Cédula / documento',
                  icon: Icons.credit_card,
                  tipo: TextInputType.number,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _campo(
                  nombres,
                  'Nombres',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _campo(
                  apellidos,
                  'Apellidos',
                  icon: Icons.person,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                _campo(
                  fechaNacimiento,
                  'Fecha nacimiento',
                  icon: Icons.cake_outlined,
                  readOnly: true,
                  onTap: () => _seleccionarFecha(
                    context,
                    fechaNacimiento,
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  ),
                ),
                const SizedBox(height: 12),
                _dropdownCampo(
                  label: 'Género',
                  icon: Icons.wc,
                  opciones: AppUi.opcionesGenero,
                  value: generoSeleccionado,
                  onChanged: (v) {
                    setState(() {
                      generoSeleccionado = v;
                      genero.text = v ?? '';
                      if (v != 'Otro') generoOtro.clear();
                    });
                  },
                ),
                if (generoSeleccionado == 'Otro') ...[
                  const SizedBox(height: 12),
                  _campo(
                    generoOtro,
                    'Indique cuál',
                    icon: Icons.edit,
                  ),
                ],
                const SizedBox(height: 12),
                _campo(
                  fechaIngreso,
                  'Fecha ingreso',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  onTap: () => _seleccionarFecha(
                    context,
                    fechaIngreso,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  ),
                ),
                const SizedBox(height: 12),
                _dropdownCampo(
                  label: 'Estado',
                  icon: Icons.verified_user_outlined,
                  opciones: AppUi.estadosCliente,
                  value: estado.text.trim().isEmpty ? 'ACTIVO' : estado.text.trim(),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                  onChanged: (v) => setState(() => estado.text = v ?? 'ACTIVO'),
                ),
              ],
              subtitulo: 'Misma lógica actual, pero con campos más claros y controlados.',
            ),
            _seccion(
              'Contacto',
              [
                _campo(
                  telefono,
                  'Teléfono',
                  icon: Icons.phone_outlined,
                  tipo: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _campo(
                  whatsapp,
                  'WhatsApp',
                  icon: Icons.chat_outlined,
                  tipo: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _campo(
                  email,
                  'Email',
                  icon: Icons.alternate_email,
                  tipo: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _campo(
                  direccion,
                  'Dirección',
                  icon: Icons.location_on_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                _campo(
                  contactoEmergenciaNombre,
                  'Contacto emergencia nombre',
                  icon: Icons.contact_phone_outlined,
                ),
                const SizedBox(height: 12),
                _campo(
                  contactoEmergenciaTelefono,
                  'Contacto emergencia teléfono',
                  icon: Icons.phone_in_talk_outlined,
                  tipo: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _campo(
                  observacionesCliente,
                  'Observaciones cliente',
                  icon: Icons.note_alt_outlined,
                  maxLines: 3,
                ),
              ],
            ),
            _seccion(
              'Medidas iniciales',
              [
                SwitchListTile(
                  value: guardarMedidas,
                  activeColor: AppColors.gold,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Guardar medidas iniciales',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Puedes dejarlas listas desde el primer registro.',
                    style: TextStyle(color: AppColors.textSoft),
                  ),
                  onChanged: (v) => setState(() => guardarMedidas = v),
                ),
                if (guardarMedidas) ...[
                  Row(children: [
                    Expanded(
                      child: _campo(
                        peso,
                        'Peso',
                        icon: Icons.monitor_weight_outlined,
                        tipo: AppUi.decimalKeyboard(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _campo(
                        estatura,
                        'Estatura',
                        icon: Icons.height,
                        tipo: AppUi.decimalKeyboard(),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _campo(torax, 'Tórax', icon: Icons.straighten, tipo: AppUi.decimalKeyboard()),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(bicepsIzq, 'Bíceps izq', icon: Icons.fitness_center, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(bicepsDer, 'Bíceps der', icon: Icons.fitness_center, tipo: AppUi.decimalKeyboard())),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(abdomenSup, 'Abdomen sup', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(abdomenInf, 'Abdomen inf', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(cadera, 'Cadera', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(muslo, 'Muslo', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(pantorrilla, 'Pantorrilla', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(grasa, '% Grasa', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(muscular, '% Muscular', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(oseo, '% Óseo', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(liquidos, '% Líquidos', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                  ]),
                  const SizedBox(height: 12),
                  _campo(biotipo, 'Biotipo', icon: Icons.category_outlined),
                  const SizedBox(height: 12),
                  _campo(objetivo, 'Objetivo', icon: Icons.flag_outlined),
                  const SizedBox(height: 12),
                  _campo(gastoEnergetico, 'Gasto energético', icon: Icons.local_fire_department_outlined),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _campo(fuma, 'Fuma', icon: Icons.smoking_rooms_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(bebe, 'Bebe', icon: Icons.local_bar_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _campo(horasSueno, 'Horas sueño', icon: Icons.bedtime_outlined)),
                  ]),
                  const SizedBox(height: 12),
                  _campo(otrosDeportes, 'Otros deportes', icon: Icons.sports_gymnastics_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  _campo(lesiones, 'Lesiones', icon: Icons.healing_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  _campo(cirugias, 'Cirugías', icon: Icons.medical_services_outlined, maxLines: 2),
                  const SizedBox(height: 12),
                  _campo(observacionesMedidas, 'Observaciones medidas', icon: Icons.description_outlined, maxLines: 3),
                ],
              ],
              subtitulo: 'Aquí ya quedan aplicados teclados numéricos y decimales donde corresponde.',
            ),
            _seccion(
              'Acceso cliente',
              [
                SwitchListTile(
                  value: crearUsuario,
                  activeColor: AppColors.gold,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Crear usuario cliente',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Username automático: ${documento.text.trim().isEmpty ? '(será la cédula)' : documento.text.trim()}',
                    style: const TextStyle(color: AppColors.textSoft),
                  ),
                  onChanged: (v) => setState(() => crearUsuario = v),
                ),
                if (crearUsuario) ...[
                  _campo(
                    password,
                    'Contraseña del cliente',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                ],
              ],
            ),
            if (mensaje.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(mensaje, style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: cargando ? null : guardarTodo,
              icon: cargando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.save),
              label: Text(cargando ? 'Guardando...' : 'Guardar nuevo ingreso'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  ),
);
  }
}

class AdminMedidasTab extends StatefulWidget {
  final String baseUrl;
  final Color colorError;

  const AdminMedidasTab({
    super.key,
    required this.baseUrl,
    required this.colorError,
  });

  @override
  State<AdminMedidasTab> createState() => _AdminMedidasTabState();
}

class _AdminMedidasTabState extends State<AdminMedidasTab> {
  final cedula = TextEditingController();
  final fechaEvaluacion = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final peso = TextEditingController();
  final estatura = TextEditingController();
  final imc = TextEditingController();
  final torax = TextEditingController();
  final bicepsIzq = TextEditingController();
  final bicepsDer = TextEditingController();
  final abdomenSup = TextEditingController();
  final abdomenInf = TextEditingController();
  final cadera = TextEditingController();
  final muslo = TextEditingController();
  final pantorrilla = TextEditingController();
  final grasa = TextEditingController();
  final muscular = TextEditingController();
  final oseo = TextEditingController();
  final liquidos = TextEditingController();
  final biotipo = TextEditingController();
  final objetivo = TextEditingController();
  final gastoEnergetico = TextEditingController();
  final fuma = TextEditingController();
  final bebe = TextEditingController();
  final horasSueno = TextEditingController();
  final otrosDeportes = TextEditingController();
  final lesiones = TextEditingController();
  final cirugias = TextEditingController();
  final observaciones = TextEditingController();

  List<dynamic> items = [];
  String msg = '';
  int? clienteIdEncontrado;
  String clienteNombre = '';
  int? evaluacionSeleccionadaId;
  bool cargando = false;

  double? _toDouble(TextEditingController c) {
    final v = c.text.trim().replaceAll(',', '.');
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  String _s(dynamic v) => v == null ? '' : v.toString();

  void _cargarFormularioDesdeItem(Map<String, dynamic> e) {
    evaluacionSeleccionadaId = e['id'] as int?;
    fechaEvaluacion.text = _s(e['fecha_evaluacion']).isEmpty
        ? DateTime.now().toIso8601String().split('T').first
        : _s(e['fecha_evaluacion']);
    peso.text = _s(e['peso']);
    estatura.text = _s(e['estatura']);
    imc.text = _s(e['imc']);
    torax.text = _s(e['torax']);
    bicepsIzq.text = _s(e['biceps_izq']);
    bicepsDer.text = _s(e['biceps_der']);
    abdomenSup.text = _s(e['abdomen_sup']);
    abdomenInf.text = _s(e['abdomen_inf']);
    cadera.text = _s(e['cadera']);
    muslo.text = _s(e['muslo']);
    pantorrilla.text = _s(e['pantorrilla']);
    grasa.text = _s(e['porcentaje_grasa']);
    muscular.text = _s(e['porcentaje_muscular']);
    oseo.text = _s(e['porcentaje_oseo']);
    liquidos.text = _s(e['porcentaje_liquidos']);
    biotipo.text = _s(e['biotipo']);
    objetivo.text = _s(e['objetivo']);
    gastoEnergetico.text = _s(e['gasto_energetico']);
    fuma.text = _s(e['fuma']);
    bebe.text = _s(e['bebe']);
    horasSueno.text = _s(e['horas_sueno']);
    otrosDeportes.text = _s(e['otros_deportes']);
    lesiones.text = _s(e['lesiones']);
    cirugias.text = _s(e['cirugias']);
    observaciones.text = _s(e['observaciones']);
  }

  void _limpiarFormulario({bool limpiarCedula = false}) {
    if (limpiarCedula) cedula.clear();
    fechaEvaluacion.text = DateTime.now().toIso8601String().split('T').first;
    for (final c in [
      peso,
      estatura,
      imc,
      torax,
      bicepsIzq,
      bicepsDer,
      abdomenSup,
      abdomenInf,
      cadera,
      muslo,
      pantorrilla,
      grasa,
      muscular,
      oseo,
      liquidos,
      biotipo,
      objetivo,
      gastoEnergetico,
      fuma,
      bebe,
      horasSueno,
      otrosDeportes,
      lesiones,
      cirugias,
      observaciones,
    ]) {
      c.clear();
    }
    evaluacionSeleccionadaId = null;
  }

  Future<void> cargar() async {
    final doc = cedula.text.trim();
    if (doc.isEmpty) {
      setState(() => msg = 'Debes escribir la cédula.');
      return;
    }

    setState(() {
      cargando = true;
      msg = '';
    });

    try {
      final resp = await ApiClient.get(
        Uri.parse('${widget.baseUrl}/evaluaciones-fisicas/cliente-cedula/$doc'),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};

      if (resp.statusCode == 404) {
        setState(() {
          clienteIdEncontrado = null;
          clienteNombre = '';
          items = [];
          _limpiarFormulario();
          msg = body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'Cliente no encontrado.';
          cargando = false;
        });
        return;
      }

      if (resp.statusCode != 200) {
        setState(() {
          msg = body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo consultar medidas.';
          cargando = false;
        });
        return;
      }

      final cliente = Map<String, dynamic>.from(body['cliente'] ?? {});
      final historial = List<dynamic>.from(body['historial'] ?? []);

      setState(() {
        clienteIdEncontrado = cliente['id'] as int?;
        clienteNombre =
            '${cliente['nombres'] ?? ''} ${cliente['apellidos'] ?? ''}'.trim();
        items = historial;
        if (historial.isNotEmpty) {
          _cargarFormularioDesdeItem(Map<String, dynamic>.from(historial.first));
          msg = 'Historial cargado correctamente.';
        } else {
          _limpiarFormulario();
          msg = 'Cliente encontrado. No tiene medidas registradas aún.';
        }
        cargando = false;
      });
    } catch (e) {
      setState(() {
        msg = 'Error: $e';
        cargando = false;
      });
    }
  }

  Map<String, dynamic> _buildBody() {
    return {
      'cliente_id': clienteIdEncontrado,
      'fecha_evaluacion': fechaEvaluacion.text.trim(),
      'peso': _toDouble(peso),
      'estatura': _toDouble(estatura),
      'imc': _toDouble(imc),
      'torax': _toDouble(torax),
      'biceps_izq': _toDouble(bicepsIzq),
      'biceps_der': _toDouble(bicepsDer),
      'abdomen_sup': _toDouble(abdomenSup),
      'abdomen_inf': _toDouble(abdomenInf),
      'cadera': _toDouble(cadera),
      'muslo': _toDouble(muslo),
      'pantorrilla': _toDouble(pantorrilla),
      'porcentaje_grasa': _toDouble(grasa),
      'porcentaje_muscular': _toDouble(muscular),
      'porcentaje_oseo': _toDouble(oseo),
      'porcentaje_liquidos': _toDouble(liquidos),
      'biotipo': biotipo.text.trim().isEmpty ? null : biotipo.text.trim(),
      'objetivo': objetivo.text.trim().isEmpty ? null : objetivo.text.trim(),
      'gasto_energetico': gastoEnergetico.text.trim().isEmpty
          ? null
          : gastoEnergetico.text.trim(),
      'fuma': fuma.text.trim().isEmpty ? null : fuma.text.trim(),
      'bebe': bebe.text.trim().isEmpty ? null : bebe.text.trim(),
      'horas_sueno': horasSueno.text.trim().isEmpty
          ? null
          : horasSueno.text.trim(),
      'otros_deportes': otrosDeportes.text.trim().isEmpty
          ? null
          : otrosDeportes.text.trim(),
      'lesiones': lesiones.text.trim().isEmpty ? null : lesiones.text.trim(),
      'cirugias': cirugias.text.trim().isEmpty ? null : cirugias.text.trim(),
      'observaciones': observaciones.text.trim().isEmpty
          ? null
          : observaciones.text.trim(),
    };
  }

  Future<void> guardarNueva() async {
    if (clienteIdEncontrado == null) {
      await cargar();
      if (clienteIdEncontrado == null) return;
    }

    try {
      final resp = await ApiClient.post(
        Uri.parse('${widget.baseUrl}/evaluaciones-fisicas/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildBody()),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evaluación creada correctamente')),
          );
        }
      } else {
        setState(() {
          msg = body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo guardar la evaluación.';
        });
      }
    } catch (e) {
      setState(() => msg = 'Error guardando: $e');
    }
  }

  Future<void> actualizarActual() async {
    if (evaluacionSeleccionadaId == null) {
      setState(() => msg = 'Primero carga o selecciona una evaluación del historial.');
      return;
    }

    try {
      final resp = await ApiClient.put(
        Uri.parse('${widget.baseUrl}/evaluaciones-fisicas/$evaluacionSeleccionadaId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_buildBody()),
      );

      final body = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await cargar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evaluación actualizada correctamente')),
          );
        }
      } else {
        setState(() {
          msg = body is Map && body['detail'] != null
              ? body['detail'].toString()
              : 'No se pudo actualizar la evaluación.';
        });
      }
    } catch (e) {
      setState(() => msg = 'Error actualizando: $e');
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    DateTime initialDate;
    try {
      initialDate = fechaEvaluacion.text.trim().isNotEmpty
          ? DateTime.parse(fechaEvaluacion.text.trim())
          : DateTime.now();
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.gold,
              onPrimary: Colors.black,
              surface: AppColors.card,
              onSurface: AppColors.text,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        fechaEvaluacion.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    TextInputType? tipo = TextInputType.number,
    int maxLines = 1,
    IconData icon = Icons.edit_note,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: c,
      keyboardType: tipo,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _itemHistorial(Map<String, dynamic> e) {
    final seleccionado = evaluacionSeleccionadaId == e['id'];
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setState(() {
            _cargarFormularioDesdeItem(e);
            msg = 'Evaluación ${e['id']} cargada en el formulario.';
          });
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: seleccionado ? AppColors.gold : AppColors.border,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: ListTile(
            title: Text(
              'Fecha: ${e['fecha_evaluacion']}',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Peso: ${e['peso'] ?? 'N/D'} | Estatura: ${e['estatura'] ?? 'N/D'} | IMC: ${e['imc'] ?? 'N/D'}\n"
              "Tórax: ${e['torax'] ?? 'N/D'} | Bíceps izq: ${e['biceps_izq'] ?? 'N/D'} | Bíceps der: ${e['biceps_der'] ?? 'N/D'}\n"
              "Cadera: ${e['cadera'] ?? 'N/D'} | Muslo: ${e['muslo'] ?? 'N/D'} | Pantorrilla: ${e['pantorrilla'] ?? 'N/D'}",
            ),
            trailing: seleccionado
                ? const Icon(Icons.check_circle, color: AppColors.gold)
                : const Icon(Icons.edit, color: AppColors.textSoft),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Medidas por cédula',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 14),
        _campo(cedula, 'Cédula del cliente', icon: Icons.badge_outlined, tipo: TextInputType.number),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: cargando ? null : cargar,
            icon: cargando
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(cargando ? 'Consultando...' : 'Consultar medidas'),
          ),
        ),
        if (clienteIdEncontrado != null) ...[
          const SizedBox(height: 10),
          Text(
            'Cliente: $clienteNombre | ID: $clienteIdEncontrado',
            style: const TextStyle(color: AppColors.gold),
          ),
          if (evaluacionSeleccionadaId != null)
            Text(
              'Evaluación seleccionada: $evaluacionSeleccionadaId',
              style: const TextStyle(color: AppColors.textSoft),
            ),
        ],
        if (msg.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: widget.colorError)),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Formulario de medidas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _campo(
                  fechaEvaluacion,
                  'Fecha evaluación',
                  icon: Icons.calendar_today_outlined,
                  tipo: TextInputType.datetime,
                  readOnly: true,
                  onTap: () => _seleccionarFecha(context),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(peso, 'Peso', icon: Icons.monitor_weight_outlined, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(estatura, 'Estatura', icon: Icons.height, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(imc, 'IMC', icon: Icons.calculate_outlined, tipo: AppUi.decimalKeyboard())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(torax, 'Tórax', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(bicepsIzq, 'Bíceps izq', icon: Icons.fitness_center, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(bicepsDer, 'Bíceps der', icon: Icons.fitness_center, tipo: AppUi.decimalKeyboard())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(abdomenSup, 'Abdomen sup', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(abdomenInf, 'Abdomen inf', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(cadera, 'Cadera', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(muslo, 'Muslo', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(pantorrilla, 'Pantorrilla', icon: Icons.straighten, tipo: AppUi.decimalKeyboard())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(grasa, '% grasa', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(muscular, '% muscular', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(oseo, '% óseo', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(liquidos, '% líquidos', icon: Icons.percent, tipo: AppUi.decimalKeyboard())),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(biotipo, 'Biotipo', tipo: TextInputType.text)),
                ]),
                const SizedBox(height: 10),
                _campo(objetivo, 'Objetivo', tipo: TextInputType.text),
                const SizedBox(height: 10),
                _campo(gastoEnergetico, 'Gasto energético', tipo: TextInputType.text),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _campo(fuma, 'Fuma', tipo: TextInputType.text)),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(bebe, 'Bebe', tipo: TextInputType.text)),
                  const SizedBox(width: 8),
                  Expanded(child: _campo(horasSueno, 'Horas sueño', tipo: TextInputType.text)),
                ]),
                const SizedBox(height: 10),
                _campo(otrosDeportes, 'Otros deportes', tipo: TextInputType.text, maxLines: 2),
                const SizedBox(height: 10),
                _campo(lesiones, 'Lesiones', tipo: TextInputType.text, maxLines: 2),
                const SizedBox(height: 10),
                _campo(cirugias, 'Cirugías', tipo: TextInputType.text, maxLines: 2),
                const SizedBox(height: 10),
                _campo(observaciones, 'Observaciones', tipo: TextInputType.text, maxLines: 3),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: guardarNueva,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar nueva'),
                    ),
                    FilledButton.icon(
                      onPressed: actualizarActual,
                      icon: const Icon(Icons.update),
                      label: const Text('Actualizar seleccionada'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _limpiarFormulario();
                          msg = 'Formulario limpio para nueva evaluación.';
                        });
                      },
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text('Limpiar formulario'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Historial de medidas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay evaluaciones para mostrar.'),
            ),
          )
        else
          ...items.map((e) => _itemHistorial(Map<String, dynamic>.from(e))),
      ],
    );
  }
}

class AdminRutinasAutoTab extends StatefulWidget {
  final String baseUrl;
  final Color colorError;

  const AdminRutinasAutoTab({
    super.key,
    required this.baseUrl,
    required this.colorError,
  });

  @override
  State<AdminRutinasAutoTab> createState() => _AdminRutinasAutoTabState();
}

class _AdminRutinasAutoTabState extends State<AdminRutinasAutoTab> {
  final cedula = TextEditingController();

  String grupoSeleccionado = 'pierna';
  String tipoSeleccionado = 'fuerza';
  String msg = '';
  String asignada = '';

  final List<String> grupos = const ['pierna', 'pecho', 'espalda', 'hombro', 'brazo', 'abdomen', 'gluteo'];
  final List<String> tipos = const ['fuerza', 'funcional', 'mixta'];

  Future<void> asignarAutomatica() async {
    final doc = cedula.text.trim();
    if (doc.isEmpty) {
      setState(() => msg = 'Debes escribir la cédula.');
      return;
    }

    try {
      final resp = await ApiClient.post(
        Uri.parse('${widget.baseUrl}/rutinas/asignar-automatica'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cedula': doc,
          'grupo_muscular': grupoSeleccionado,
          'tipo': tipoSeleccionado,
        }),
      );

      dynamic data;
      try {
        data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
      } catch (_) {
        data = {'detail': resp.body};
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final rutina = data['rutina'];
        setState(() {
          asignada = rutina != null
              ? (rutina['nombre'] ?? 'Rutina automática asignada')
              : 'Rutina automática asignada';
          msg = 'Rutina asignada correctamente';
        });
      } else {
        setState(() {
          msg = data is Map && data['detail'] != null
              ? data['detail'].toString()
              : 'No se pudo asignar la rutina automática.';
        });
      }
    } catch (e) {
      setState(() => msg = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rutina automática',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: cedula,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Cédula del cliente',
            prefixIcon: Icon(Icons.badge),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: grupoSeleccionado,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(
            labelText: 'Grupo muscular',
            prefixIcon: Icon(Icons.fitness_center),
          ),
          items: grupos
              .map(
                (g) => DropdownMenuItem(
                  value: g,
                  child: Text(g.toUpperCase()),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => grupoSeleccionado = v);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: tipoSeleccionado,
          dropdownColor: AppColors.card,
          decoration: const InputDecoration(
            labelText: 'Tipo de rutina',
            prefixIcon: Icon(Icons.category),
          ),
          items: tipos
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.toUpperCase()),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => tipoSeleccionado = v);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: asignarAutomatica,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Asignar rutina automática'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: asignarAutomatica,
          icon: const Icon(Icons.refresh),
          label: const Text('Reasignar otra rutina al azar'),
        ),
        if (msg.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            msg,
            style: TextStyle(
              color: msg.toLowerCase().contains('correctamente')
                  ? AppColors.goldSoft
                  : widget.colorError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (asignada.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Rutina elegida al azar: $asignada',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Aquí no tienes que crear rutinas ni ejercicios manualmente. '
              'Solo escribes la cédula, eliges grupo muscular y tipo, '
              'y el sistema asigna una rutina precargada al azar.',
            ),
          ),
        ),
      ],
    );
  }
}

class ClientHomePage extends StatefulWidget {
  final UserSession session;

  const ClientHomePage({super.key, required this.session});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _tabIndex = 0;
  bool _cargando = true;
  String _mensaje = '';
  Map<String, dynamic>? _cliente;
  List<dynamic> _membresias = [];
  List<dynamic> _evaluaciones = [];
  Map<String, dynamic>? _rutinaActual;

  static const Map<int, String> planesNombre = {
    1: 'DIARIO',
    2: 'SEMANAL',
    3: 'QUINCENAL',
    4: 'MENSUAL',
    5: 'TRIMESTRAL',
  };

  @override
  void initState() {
    super.initState();
    cargarDatosCliente();
  }

  String _valor(dynamic v, {String fallback = 'N/D'}) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return fallback;
    return s;
  }

  Widget _medidaChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: ${_valor(value)}',
        style: const TextStyle(color: AppColors.text),
      ),
    );
  }

  Future<void> _marcarEjercicioCumplido(int clienteRutinaId, int rutinaEjercicioId) async {
    try {
      final resp = await ApiClient.post(
        Uri.parse('${ApiConfig.baseUrl}/rutinas/cliente-rutina/$clienteRutinaId/ejercicio/$rutinaEjercicioId/cumplir'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'cumplido': true}),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (_rutinaActual != null) {
          setState(() {
            final rutina = Map<String, dynamic>.from(_rutinaActual!['rutina'] as Map<String, dynamic>);
            final ejercicios = List<dynamic>.from((rutina['ejercicios'] ?? []) as List);
            ejercicios.removeWhere((item) {
              final mapa = Map<String, dynamic>.from(item as Map);
              return mapa['id'] == rutinaEjercicioId;
            });
            rutina['ejercicios'] = ejercicios;
            _rutinaActual!['rutina'] = rutina;
            if (ejercicios.isEmpty) {
              _rutinaActual = null;
            }
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio marcado como cumplido.'), backgroundColor: AppColors.success),
        );
      } else {
        final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data is Map && data['detail'] != null ? '${data['detail']}' : 'No se pudo marcar como cumplido.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> cargarDatosCliente() async {
    if (widget.session.clienteId == null) {
      setState(() {
        _mensaje = 'Tu usuario no tiene cliente asociado.';
        _cargando = false;
      });
      return;
    }

    setState(() {
      _cargando = true;
      _mensaje = '';
    });

    try {
      final clienteResp = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/clientes/${widget.session.clienteId}'));

      if (clienteResp.statusCode != 200) {
        setState(() {
          _mensaje = 'No se pudo cargar la información del cliente.';
          _cargando = false;
        });
        return;
      }

      final clienteData = jsonDecode(clienteResp.body);

      final membresiasResp =
          await ApiClient.get(Uri.parse('${ApiConfig.baseUrl}/membresias/'));
      final evaluacionesResp = await ApiClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/evaluaciones-fisicas/?cliente_id=${widget.session.clienteId}',
        ),
      );
      final rutinaResp = await ApiClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/rutinas/cliente/${widget.session.clienteId}/actual',
        ),
      );

      List<dynamic> membresiasCliente = [];
      if (membresiasResp.statusCode == 200) {
        final List<dynamic> todas = jsonDecode(membresiasResp.body);
        membresiasCliente = todas
            .where((m) => m['cliente_id'] == widget.session.clienteId)
            .toList();
        membresiasCliente
            .sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      }

      List<dynamic> evaluacionesCliente = [];
      if (evaluacionesResp.statusCode == 200) {
        evaluacionesCliente = jsonDecode(evaluacionesResp.body);
      }

      Map<String, dynamic>? rutinaData;
      if (rutinaResp.statusCode == 200) {
        rutinaData = Map<String, dynamic>.from(jsonDecode(rutinaResp.body));
      }

      setState(() {
        _cliente = clienteData;
        _membresias = membresiasCliente;
        _evaluaciones = evaluacionesCliente;
        _rutinaActual = rutinaData;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _mensaje = 'Error de conexión: $e';
        _cargando = false;
      });
    }
  }

  Map<String, dynamic>? obtenerMembresiaPrincipal() {
    if (_membresias.isEmpty) return null;
    final activas = _membresias
        .where((m) => (m['estado'] ?? '').toString().toUpperCase() == 'ACTIVA')
        .toList();
    if (activas.isNotEmpty) {
      activas.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      return Map<String, dynamic>.from(activas.first);
    }
    return Map<String, dynamic>.from(_membresias.first);
  }

  String obtenerEstadoMembresiaTexto(Map<String, dynamic>? membresia) {
    if (membresia == null) return 'SIN MEMBRESÍA';

    final estado = (membresia['estado'] ?? '').toString().toUpperCase();
    final fechaFin = (membresia['fecha_fin'] ?? '').toString();
    final hoy = DateTime.now();
    final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);

    DateTime? fechaFinDate;
    try {
      fechaFinDate = DateTime.parse(fechaFin);
    } catch (_) {
      fechaFinDate = null;
    }

    if (estado == 'CANCELADA') return 'CANCELADA';
    if (estado == 'VENCIDA') return 'VENCIDA';

    if (fechaFinDate != null) {
      final finSoloFecha =
          DateTime(fechaFinDate.year, fechaFinDate.month, fechaFinDate.day);
      if (finSoloFecha.isBefore(hoySoloFecha)) return 'VENCIDA';
    }

    if (estado == 'ACTIVA') return 'ACTIVA';
    return estado.isEmpty ? 'SIN ESTADO' : estado;
  }

  int? obtenerDiasRestantes(Map<String, dynamic>? membresia) {
    if (membresia == null) return null;

    try {
      final fechaFin =
          DateTime.parse((membresia['fecha_fin'] ?? '').toString());
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
      return fin.difference(hoy).inDays;
    } catch (_) {
      return null;
    }
  }

  Color obtenerColorEstado(String estado) {
    switch (estado) {
      case 'ACTIVA':
        return AppColors.success;
      case 'VENCIDA':
      case 'CANCELADA':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String formatearPlan(int? planId) {
    if (planId == null) return 'SIN PLAN';
    return planesNombre[planId] ?? 'PLAN $planId';
  }

  void cerrarSesion() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget infoTile({
    required IconData icon,
    required String titulo,
    required String valor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cuentaTab() {
    final membresiaPrincipal = obtenerMembresiaPrincipal();
    final estadoMembresia = obtenerEstadoMembresiaTexto(membresiaPrincipal);
    final diasRestantes = obtenerDiasRestantes(membresiaPrincipal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(
                    Icons.person,
                    color: AppColors.gold,
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.session.nombre,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.session.username,
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 14,
                    ),
                  ),
                  if (_mensaje.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _mensaje,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_cliente != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mis datos',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    infoTile(
                      icon: Icons.badge,
                      titulo: 'Cédula',
                      valor: '${_cliente!['documento'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.person_outline,
                      titulo: 'Nombre',
                      valor:
                          '${_cliente!['nombres'] ?? ''} ${_cliente!['apellidos'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.phone,
                      titulo: 'Teléfono',
                      valor: '${_cliente!['telefono'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.chat,
                      titulo: 'WhatsApp',
                      valor: '${_cliente!['whatsapp'] ?? ''}',
                    ),
                    infoTile(
                      icon: Icons.verified_user,
                      titulo: 'Estado cliente',
                      valor: '${_cliente!['estado'] ?? ''}',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi membresía',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Estado: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: obtenerColorEstado(estadoMembresia),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          estadoMembresia,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (membresiaPrincipal != null) ...[
                    infoTile(
                      icon: Icons.fitness_center,
                      titulo: 'Plan',
                      valor: formatearPlan(membresiaPrincipal['plan_id'] as int?),
                    ),
                    infoTile(
                      icon: Icons.event_available,
                      titulo: 'Fecha inicio',
                      valor: '${membresiaPrincipal['fecha_inicio']}',
                    ),
                    infoTile(
                      icon: Icons.event_busy,
                      titulo: 'Fecha fin',
                      valor: '${membresiaPrincipal['fecha_fin']}',
                    ),
                    infoTile(
                      icon: Icons.timelapse,
                      titulo: 'Días restantes',
                      valor: diasRestantes == null ? 'N/D' : '$diasRestantes',
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.input,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'No tienes membresía registrada.',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget medidasTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _evaluaciones.isEmpty
          ? [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay evaluaciones registradas.'),
                ),
              ),
            ]
          : _evaluaciones.map((e) {
              final item = Map<String, dynamic>.from(e as Map);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha: ${_valor(item['fecha_evaluacion'])}',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _medidaChip('Peso', item['peso']),
                          _medidaChip('Estatura', item['estatura']),
                          _medidaChip('IMC', item['imc']),
                          _medidaChip('Tórax', item['torax']),
                          _medidaChip('Bíceps izq', item['biceps_izq']),
                          _medidaChip('Bíceps der', item['biceps_der']),
                          _medidaChip('Abdomen sup', item['abdomen_sup']),
                          _medidaChip('Abdomen inf', item['abdomen_inf']),
                          _medidaChip('Cadera', item['cadera']),
                          _medidaChip('Muslo', item['muslo']),
                          _medidaChip('Pantorrilla', item['pantorrilla']),
                          _medidaChip('% Grasa', item['porcentaje_grasa']),
                          _medidaChip('% Muscular', item['porcentaje_muscular']),
                          _medidaChip('% Óseo', item['porcentaje_oseo']),
                          _medidaChip('% Líquidos', item['porcentaje_liquidos']),
                          _medidaChip('Biotipo', item['biotipo']),
                          _medidaChip('Objetivo', item['objetivo']),
                          _medidaChip('Gasto energético', item['gasto_energetico']),
                          _medidaChip('Fuma', item['fuma']),
                          _medidaChip('Bebe', item['bebe']),
                          _medidaChip('Sueño', item['horas_sueno']),
                        ],
                      ),
                      if (_valor(item['otros_deportes'], fallback: '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Otros deportes: ${item['otros_deportes']}', style: const TextStyle(color: AppColors.textSoft)),
                      ],
                      if (_valor(item['lesiones'], fallback: '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Lesiones: ${item['lesiones']}', style: const TextStyle(color: AppColors.textSoft)),
                      ],
                      if (_valor(item['cirugias'], fallback: '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Cirugías: ${item['cirugias']}', style: const TextStyle(color: AppColors.textSoft)),
                      ],
                      if (_valor(item['observaciones'], fallback: '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Observaciones: ${item['observaciones']}', style: const TextStyle(color: AppColors.textSoft)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }

  Widget _chip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.text)),
        ],
      ),
    );
  }

  Widget rutinaTab() {
    if (_rutinaActual == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No tienes rutina activa asignada.'),
        ),
      );
    }

    final asignacionId = _rutinaActual!['id'];
    final rutina = _rutinaActual!['rutina'] as Map<String, dynamic>;
    final ejercicios = (rutina['ejercicios'] ?? []) as List<dynamic>;
    final pendientes = ejercicios.where((e) => (e['cumplido'] ?? false) != true).toList();
    final cumplidos = ejercicios.where((e) => (e['cumplido'] ?? false) == true).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rutina['nombre'] ?? 'Rutina',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip('Objetivo: ${rutina['objetivo'] ?? 'N/D'}', Icons.track_changes),
                    _chip('Nivel: ${rutina['nivel'] ?? 'N/D'}', Icons.bolt),
                    _chip('Pendientes: ${pendientes.length}', Icons.hourglass_bottom),
                    _chip('Cumplidos: ${cumplidos.length}', Icons.check_circle),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (pendientes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '¡Ya cumpliste toda tu rutina! Buen trabajo.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ...pendientes.asMap().entries.map((entry) {
          final index = entry.key;
          final item = Map<String, dynamic>.from(entry.value as Map);
          final imagen = (item['gif_url'] ?? item['imagen_url'] ?? '').toString();
          final rutinaEjercicioId = item['id'];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['nombre'] ?? 'Ejercicio',
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _marcarEjercicioCumplido(asignacionId, rutinaEjercicioId),
                        icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 32),
                        tooltip: 'Marcar como cumplido',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip('Día: ${item['dia'] ?? 'N/D'}', Icons.calendar_today),
                      _chip('Series: ${item['series'] ?? 'N/D'}', Icons.repeat),
                      _chip('Reps: ${item['repeticiones'] ?? 'N/D'}', Icons.fitness_center),
                      _chip('Descanso: ${item['descanso'] ?? 'N/D'}', Icons.timer),
                    ],
                  ),
                  if ((item['descripcion'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(item['descripcion'], style: const TextStyle(fontSize: 17)),
                  ],
                  if ((item['instrucciones'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.input,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['instrucciones'],
                              style: const TextStyle(color: AppColors.textSoft, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  NetworkExerciseMedia(url: imagen),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [cuentaTab(), medidasTab(), rutinaTab()];
    final esDesktop = AppResponsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AppLogo(size: 38),
            SizedBox(width: 10),
            Text(
              'Mi cuenta',
              style: TextStyle(color: AppColors.text),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: cerrarSesion,
            icon: const Icon(Icons.logout, color: AppColors.text),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : esDesktop
              ? Row(
                  children: [
                    Container(
                      width: 96,
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        border: Border(
                          right: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: NavigationRail(
                        backgroundColor: Colors.transparent,
                        selectedIndex: _tabIndex,
                        onDestinationSelected: (v) => setState(() => _tabIndex = v),
                        labelType: NavigationRailLabelType.all,
                        selectedIconTheme: const IconThemeData(color: Colors.black),
                        selectedLabelTextStyle: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                        indicatorColor: AppColors.gold,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.person, color: AppColors.textSoft),
                            label: Text('Cuenta'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.monitor_weight, color: AppColors.textSoft),
                            label: Text('Medidas'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.fitness_center, color: AppColors.textSoft),
                            label: Text('Rutina'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AppResponsive.tabBody(
                        context,
                        tabs[_tabIndex],
                        maxWidth: 1320,
                      ),
                    ),
                  ],
                )
              : tabs[_tabIndex],
      bottomNavigationBar: esDesktop
          ? null
          : NavigationBar(
              backgroundColor: AppColors.card,
              indicatorColor: AppColors.gold.withOpacity(0.18),
              selectedIndex: _tabIndex,
              onDestinationSelected: (v) => setState(() => _tabIndex = v),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.person), label: 'Cuenta'),
                NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Medidas'),
                NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Rutina'),
              ],
            ),
    );
  }
}
