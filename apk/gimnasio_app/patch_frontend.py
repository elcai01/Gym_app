import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Add shared_preferences import
    if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
        content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';")

    # Update UserSession class
    old_session = """class UserSession {
  static String? token;
  static String? username;
  static String? rol;
  static int? clienteId;
  static String? nombre;
}"""
    
    new_session = """class UserSession {
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
      // 2 horas = 2 * 60 * 60 * 1000 = 7200000 ms
      if (now - lastActivity < 7200000) {
        token = prefs.getString('token');
        username = prefs.getString('username');
        rol = prefs.getString('rol');
        clienteId = prefs.getInt('clienteId');
        nombre = prefs.getString('nombre');
        await updateActivity(); // Refresh time
      } else {
        await clearSession(); // Expiró
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
}"""
    content = content.replace(old_session, new_session)

    # In void main()
    # Need to make main async and call WidgetsFlutterBinding.ensureInitialized()
    # Then await UserSession.loadSession() before runApp
    if "void main() {" in content and "WidgetsFlutterBinding.ensureInitialized();" not in content:
        content = content.replace("void main() {", "void main() async {\n  WidgetsFlutterBinding.ensureInitialized();\n  await UserSession.loadSession();")

    # In _LoginPageState._login, save session
    login_success = """        UserSession.clienteId = data['cliente_id'];
        UserSession.nombre = data['nombre'];"""
    
    login_success_new = """        UserSession.clienteId = data['cliente_id'];
        UserSession.nombre = data['nombre'];
        await UserSession.saveSession();"""
    content = content.replace(login_success, login_success_new)

    # Wrap MaterialApp with Listener to update activity globally
    if "return MaterialApp(" in content:
        # Actually, maybe wrap GymStyleLifeApp's build method
        app_build = """  Widget build(BuildContext context) {
    return MaterialApp("""
        app_build_new = """  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => UserSession.updateActivity(),
      child: MaterialApp("""
        content = content.replace(app_build, app_build_new)
        # Close the Listener
        app_close = """      },
    );
  }"""
        app_close_new = """      },
    ),
    );
  }"""
        content = content.replace(app_close, app_close_new)

    # Update GymStyleLifeApp initialRoute based on session
    initial_route = "initialRoute: '/login',"
    initial_route_new = "initialRoute: UserSession.token != null ? (UserSession.rol == 'admin' ? '/admin_home' : '/client_home') : '/login',"
    content = content.replace(initial_route, initial_route_new)

    # Fix initial screen bug if any (GymStyleLifeApp is stateless)

    # In _AdminHomePageState.cerrarSesion, clear session
    cerrar_sesion_admin = """  void cerrarSesion() {
    UserSession.token = null;
    UserSession.username = null;
    UserSession.rol = null;
    UserSession.clienteId = null;
    UserSession.nombre = null;
    Navigator.pushReplacementNamed(context, '/login');
  }"""
    cerrar_sesion_admin_new = """  void cerrarSesion() async {
    await UserSession.clearSession();
    Navigator.pushReplacementNamed(context, '/login');
  }"""
    content = content.replace(cerrar_sesion_admin, cerrar_sesion_admin_new)

    # In _ClientHomePageState.cerrarSesion, clear session
    cerrar_sesion_client = """  void cerrarSesion() {
    UserSession.token = null;
    UserSession.username = null;
    UserSession.rol = null;
    UserSession.clienteId = null;
    UserSession.nombre = null;
    Navigator.pushReplacementNamed(context, '/login');
  }"""
    cerrar_sesion_client_new = """  void cerrarSesion() async {
    await UserSession.clearSession();
    Navigator.pushReplacementNamed(context, '/login');
  }"""
    content = content.replace(cerrar_sesion_client, cerrar_sesion_client_new)
    
    # Another place could be the _marcarEjercicioCumplido bug. Wait, that was fixed backend-side. 
    # Front-end already checks if the array is empty and sets _rutinaActual to null. It's fine.

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Frontend patched")

if __name__ == "__main__":
    main()
