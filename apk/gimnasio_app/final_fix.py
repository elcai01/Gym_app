import re

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. UserSession replacement
old_us = """class UserSession {
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
}"""

new_us = """class UserSession {
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'username': username,
      'rol': rol,
      'cliente_id': clienteId,
      'activo': activo,
    };
  }

  static Future<UserSession?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_time');
    
    if (lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastActivity < 7200000) {
        final sessionStr = prefs.getString('session_data');
        if (sessionStr != null) {
          await updateActivity();
          return UserSession.fromJson(jsonDecode(sessionStr));
        }
      } else {
        await clearSession();
      }
    }
    return null;
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('session_data', jsonEncode(toJson()));
    await updateActivity();
  }

  static Future<void> updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}"""
content = content.replace(old_us, new_us)

# 2. Login Page
login_old = """      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final session = UserSession.fromJson(data);

        if (!mounted) return;"""
login_new = """      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final session = UserSession.fromJson(data);
        await session.saveToPrefs();

        if (!mounted) return;"""
content = content.replace(login_old, login_new)

# 3. cerrarSesion
cerrar_admin = """  void cerrarSesion() {
    Navigator.of(context).pushReplacementNamed('/login');
  }"""
cerrar_new = """  void cerrarSesion() async {
    await UserSession.clearSession();
    Navigator.of(context).pushReplacementNamed('/login');
  }"""
content = content.replace(cerrar_admin, cerrar_new)

# 4. _membresia -> obtenerMembresiaPrincipal()
memb_old = """  Future<void> abrirModalModificarFechas() async {
    if (_cliente == null || _membresia == null) return;
    
    final ctrlInicio = TextEditingController(text: _membresia!['fecha_inicio']?.split('T')[0] ?? '');
    final ctrlFin = TextEditingController(text: _membresia!['fecha_fin']?.split('T')[0] ?? '');"""

memb_new = """  Future<void> abrirModalModificarFechas() async {
    final membresia = obtenerMembresiaPrincipal();
    if (_cliente == null || membresia == null) return;
    
    final ctrlInicio = TextEditingController(text: membresia['fecha_inicio']?.split('T')[0] ?? '');
    final ctrlFin = TextEditingController(text: membresia['fecha_fin']?.split('T')[0] ?? '');"""
content = content.replace(memb_old, memb_new)

memb_id_old = """                final url = '${ApiConfig.baseUrl}/membresias/${_membresia!['id']}';"""
memb_id_new = """                final url = '${ApiConfig.baseUrl}/membresias/${membresia['id']}';"""
content = content.replace(memb_id_old, memb_id_new)

# 5. silencioso error
silencioso_old = """                  recargarClienteActual(silencioso: false);"""
silencioso_new = """                  cargarDatosCliente();"""
content = content.replace(silencioso_old, silencioso_new)

# 6. const arrays
const_rail_old = """                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome, color: AppColors.textSoft),
                        label: Text('Rutinas'),
                      ),
                      if (esSuperAdmin)
                        const NavigationRailDestination(
                          icon: Icon(Icons.admin_panel_settings, color: AppColors.textSoft),
                          label: Text('Staff'),
                        ),
                    ],"""
const_rail_new = """                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome, color: AppColors.textSoft),
                        label: Text('Rutinas'),
                      ),
                      if (esSuperAdmin)
                        NavigationRailDestination(
                          icon: Icon(Icons.admin_panel_settings, color: AppColors.textSoft),
                          label: Text('Staff'),
                        ),
                    ],"""
content = content.replace(const_rail_old, const_rail_new)

const_bot_old = """                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rutinas'),
                if (esSuperAdmin)
                  const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Staff'),
              ],"""
const_bot_new = """                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rutinas'),
                if (esSuperAdmin)
                  NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Staff'),
              ],"""
content = content.replace(const_bot_old, const_bot_new)

# const destinations issue: If the list itself is const
content = content.replace("destinations: const [", "destinations: [")
content = content.replace("destinations: const <NavigationRailDestination>[", "destinations: <NavigationRailDestination>[")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done final fix")
