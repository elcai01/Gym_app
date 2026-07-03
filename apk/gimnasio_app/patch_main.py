import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Añadir AdminStaffTab al final
    staff_tab_code = """
class AdminStaffTab extends StatefulWidget {
  final String baseUrl;
  const AdminStaffTab({Key? key, required this.baseUrl}) : super(key: key);

  @override
  State<AdminStaffTab> createState() => _AdminStaffTabState();
}

class _AdminStaffTabState extends State<AdminStaffTab> {
  bool _cargando = true;
  List<dynamic> _usuarios = [];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _cargando = true);
    try {
      final res = await http.get(Uri.parse('${widget.baseUrl}/usuarios'));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        setState(() {
          _usuarios = list.where((u) => u['rol'] != 'CLIENTE').toList();
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _abrirModalCrear() async {
    final ctrlNombre = TextEditingController();
    final ctrlUser = TextEditingController();
    final ctrlPass = TextEditingController();
    String? rolSeleccionado;
    
    final rolesMap = {
      'ADMIN': 1,
      'RECEPCION': 2,
      'ENTRENADOR': 3,
    };

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear Usuario Staff'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrlNombre, decoration: const InputDecoration(labelText: 'Nombre Completo')),
              const SizedBox(height: 10),
              TextField(controller: ctrlUser, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 10),
              TextField(controller: ctrlPass, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Rol'),
                items: rolesMap.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => rolSeleccionado = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (ctrlNombre.text.isEmpty || ctrlUser.text.isEmpty || ctrlPass.text.isEmpty || rolSeleccionado == null) return;
              try {
                final res = await http.post(
                  Uri.parse('${widget.baseUrl}/usuarios/staff'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'nombre': ctrlNombre.text,
                    'username': ctrlUser.text,
                    'password': ctrlPass.text,
                    'rol_id': rolesMap[rolSeleccionado]
                  }),
                );
                if (res.statusCode == 200) {
                  Navigator.pop(ctx);
                  _cargarUsuarios();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirModalCrear,
        backgroundColor: AppColors.gold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _usuarios.length,
        itemBuilder: (ctx, i) {
          final u = _usuarios[i];
          return Card(
            color: AppColors.card,
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: AppColors.gold),
              title: Text(u['nombre'], style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
              subtitle: Text('Usuario: ${u['username']} - Rol: ${u['rol']}', style: const TextStyle(color: AppColors.textSoft)),
            ),
          );
        },
      ),
    );
  }
}
"""
    if "class AdminStaffTab" not in content:
        content += "\n" + staff_tab_code

    # 2. Add abrirModalModificarFechas in _AdminHomePageState
    modificar_fechas_code = """
  Future<void> abrirModalModificarFechas() async {
    if (_cliente == null || _membresia == null) return;
    
    final ctrlInicio = TextEditingController(text: _membresia!['fecha_inicio']?.split('T')[0] ?? '');
    final ctrlFin = TextEditingController(text: _membresia!['fecha_fin']?.split('T')[0] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forzar Fechas Membresía'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Solo SUPER ADMIN.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: ctrlInicio, decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD)')),
            const SizedBox(height: 10),
            TextField(controller: ctrlFin, decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              try {
                final url = '${ApiConfig.baseUrl}/membresias/${_membresia!['id']}';
                final res = await http.put(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'fecha_inicio': ctrlInicio.text,
                    'fecha_fin': ctrlFin.text,
                  }),
                );
                if (res.statusCode == 200) {
                  Navigator.pop(ctx);
                  recargarClienteActual(silencioso: false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fechas actualizadas')));
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
                }
              } catch(e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Aplicar Fechas'),
          )
        ],
      ),
    );
  }
"""
    if "abrirModalModificarFechas" not in content:
        content = content.replace("Widget medidasTab() => AdminMedidasTab(", modificar_fechas_code + "\n  Widget medidasTab() => AdminMedidasTab(")

    # 3. Add modifying dates button in clientesTab()
    button_code = """
                        FilledButton.icon(
                          onPressed: abrirModalAcceso,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('RFID / Huella'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1B4B),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (widget.session.username == 'admin' && _membresia != null)
                          FilledButton.icon(
                            onPressed: abrirModalModificarFechas,
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Modificar Fechas'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade800,
                              foregroundColor: Colors.white,
                            ),
                          ),
"""
    if "Modificar Fechas" not in content:
        content = re.sub(
            r"FilledButton\.icon\(\s*onPressed:\s*abrirModalAcceso,.*?\}\),.*?\),", 
            button_code, 
            content, 
            flags=re.DOTALL
        )

    # 4. Inject AdminStaffTab to build()
    build_start = "    final tabs = [clientesTab(), mensualidadesTab(), medidasTab(), rutinasTab()];"
    build_replace = """    final esSuperAdmin = widget.session.username == 'admin';
    final tabs = [
      clientesTab(),
      mensualidadesTab(),
      medidasTab(),
      rutinasTab(),
      if (esSuperAdmin) AdminStaffTab(baseUrl: ApiConfig.baseUrl),
    ];"""
    content = content.replace(build_start, build_replace)

    # rail destinations
    rail_dest_find = """                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome, color: AppColors.textSoft),
                        label: Text('Rutinas'),
                      ),
                    ],"""
    rail_dest_replace = """                      NavigationRailDestination(
                        icon: Icon(Icons.auto_awesome, color: AppColors.textSoft),
                        label: Text('Rutinas'),
                      ),
                      if (esSuperAdmin)
                        const NavigationRailDestination(
                          icon: Icon(Icons.admin_panel_settings, color: AppColors.textSoft),
                          label: Text('Staff'),
                        ),
                    ],"""
    content = content.replace(rail_dest_find, rail_dest_replace)

    # bottom destinations
    bottom_dest_find = """                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rutinas'),
              ],"""
    bottom_dest_replace = """                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rutinas'),
                if (esSuperAdmin)
                  const NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Staff'),
              ],"""
    content = content.replace(bottom_dest_find, bottom_dest_replace)

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("Success")

if __name__ == "__main__":
    main()
