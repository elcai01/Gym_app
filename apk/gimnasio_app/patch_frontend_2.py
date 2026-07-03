import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add shared_preferences import
    if "import 'package:shared_preferences/shared_preferences.dart';" not in content:
        content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\nimport 'package:shared_preferences/shared_preferences.dart';")

    # 2. Modify UserSession to add static methods
    old_session = """class UserSession {
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
    new_session = """class UserSession {
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
        final sessionString = prefs.getString('user_session');
        if (sessionString != null) {
          final data = jsonDecode(sessionString);
          await updateActivity();
          return UserSession.fromJson(data);
        }
      } else {
        await clearPrefs();
      }
    }
    return null;
  }

  static Future<void> saveToPrefs(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(session.toJson()));
    await updateActivity();
  }

  static Future<void> updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('last_activity_time');
  }
}"""
    content = content.replace(old_session, new_session)

    # 3. Modify main() and GymStyleLifeApp
    old_main = """void main() {
  runApp(const GymStyleLifeApp());
}

class GymStyleLifeApp extends StatelessWidget {
  const GymStyleLifeApp({super.key});"""
    new_main = """void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialSession = await UserSession.loadFromPrefs();
  runApp(GymStyleLifeApp(initialSession: initialSession));
}

class GymStyleLifeApp extends StatelessWidget {
  final UserSession? initialSession;
  const GymStyleLifeApp({super.key, this.initialSession});"""
    content = content.replace(old_main, new_main)

    # Wrap MaterialApp with Listener and update home:
    old_material_app = """    return MaterialApp(
      title: 'Gym Style Life',
      debugShowCheckedModeBanner: false,"""
    new_material_app = """    return Listener(
      onPointerDown: (_) => UserSession.updateActivity(),
      child: MaterialApp(
      title: 'Gym Style Life',
      debugShowCheckedModeBanner: false,"""
    content = content.replace(old_material_app, new_material_app)

    old_home = """      home: const LoginPage(),"""
    new_home = """      home: initialSession != null
          ? (initialSession!.rol == 'ADMIN'
              ? AdminHomePage(session: initialSession!)
              : ClientHomePage(session: initialSession!))
          : const LoginPage(),"""
    content = content.replace(old_home, new_home)

    # Fix Listener bracket close. The MaterialApp ends before `class AppScrollBehavior`
    material_app_end = """        ),
      ),
      home: const LoginPage(),
    );
  }
}

class AppScrollBehavior"""
    material_app_end_new = """        ),
      ),
      home: initialSession != null
          ? (initialSession!.rol == 'ADMIN'
              ? AdminHomePage(session: initialSession!)
              : ClientHomePage(session: initialSession!))
          : const LoginPage(),
    ),
    );
  }
}

class AppScrollBehavior"""
    # Just be careful not to replace home twice. Let's do it cleanly by searching for home: const LoginPage(),
    # Wait, the best way is to replace `home: const LoginPage(),\n    );\n  }\n}`
    
    # Actually, let's revert to a simpler replacement for home:
    content = content.replace(new_home, old_home) # Undo new_home replace if done early
    content = content.replace("home: const LoginPage(),\n    );\n  }", "home: initialSession != null\n          ? (initialSession!.rol == 'ADMIN'\n              ? AdminHomePage(session: initialSession!)\n              : ClientHomePage(session: initialSession!))\n          : const LoginPage(),\n    ),\n    );\n  }")


    # 4. In _LoginPageState, save session after login
    login_save = """        final session = UserSession.fromJson(data);
        if (!mounted) return;"""
    new_login_save = """        final session = UserSession.fromJson(data);
        await UserSession.saveToPrefs(session);
        if (!mounted) return;"""
    content = content.replace(login_save, new_login_save)

    # 5. AdminHomePage cerrarSesion()
    admin_logout_old = """  void cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }"""
    admin_logout_new = """  void cerrarSesion() async {
    await UserSession.clearPrefs();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }"""
    content = content.replace(admin_logout_old, admin_logout_new)

    # 6. ClientHomePage cerrarSesion()
    client_logout_old = """  void cerrarSesion() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }"""
    client_logout_new = """  void cerrarSesion() async {
    await UserSession.clearPrefs();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }"""
    content = content.replace(client_logout_old, client_logout_new)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Frontend session patch applied.")

if __name__ == "__main__":
    main()
