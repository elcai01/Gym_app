import re

file_path = 'lib/main.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
if 'package:shared_preferences/shared_preferences.dart' not in content:
    content = content.replace(
        "import 'package:http/http.dart' as http;",
        "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';\nimport 'package:google_fonts/google_fonts.dart';"
    )

# 2. Main async & loadSession
if 'await UserSession.loadSession()' not in content:
    content = content.replace('void main() {', 'void main() async {\n  WidgetsFlutterBinding.ensureInitialized();\n  await UserSession.loadSession();')

# 3. UserSession upgrade
old_session = '''class UserSession {
  static String? token;
  static String? username;
  static String? rol;
  static int? clienteId;
  static String? nombre;
}'''
new_session = '''class UserSession {
  static String? token;
  static String? username;
  static String? rol;
  static int? clienteId;
  static String? nombre;

  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity_time');
    
    if (lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastActivity < 7200000) {
        token = prefs.getString('token');
        username = prefs.getString('username');
        rol = prefs.getString('rol');
        clienteId = prefs.getInt('clienteId');
        nombre = prefs.getString('nombre');
        await updateActivity();
      } else {
        await clearSession();
      }
    }
  }

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) await prefs.setString('token', token!);
    if (username != null) await prefs.setString('username', username!);
    if (rol != null) await prefs.setString('rol', rol!);
    if (clienteId != null) await prefs.setInt('clienteId', clienteId!);
    if (nombre != null) await prefs.setString('nombre', nombre!);
    await updateActivity();
  }

  static Future<void> updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    token = null;
    username = null;
    rol = null;
    clienteId = null;
    nombre = null;
  }
}'''
content = content.replace(old_session, new_session)

# 4. Listener around MaterialApp & routing
app_build = '''  Widget build(BuildContext context) {
    return MaterialApp('''
app_build_new = '''  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => UserSession.updateActivity(),
      child: MaterialApp('''
if 'Listener(' not in content:
    content = content.replace(app_build, app_build_new)
    
    app_close = '''      },
    );
  }'''
    app_close_new = '''      },
    ),
    );
  }'''
    content = content.replace(app_close, app_close_new)

initial_route = "initialRoute: '/login',"
initial_route_new = "initialRoute: UserSession.token != null ? (UserSession.rol == 'admin' ? '/admin_home' : '/client_home') : '/login',"
content = content.replace(initial_route, initial_route_new)

# 5. _LoginPageState login success
login_success = '''        UserSession.clienteId = data['cliente_id'];
        UserSession.nombre = data['nombre'];'''
login_success_new = '''        UserSession.clienteId = data['cliente_id'];
        UserSession.nombre = data['nombre'];
        await UserSession.saveSession();'''
content = content.replace(login_success, login_success_new)

# 6. Admin Staff Tab (using patch_main.py)
import patch_main
import fix_theme
import fix_ui_dates

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

# Apply patches
patch_main.main()
fix_ui_dates.main()
fix_theme.main()
