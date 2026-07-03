import re

def fix_main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Fix the duplicate _tomarYSubirFoto in AdminHomePage
    # The duplicate is two identical blocks of _tomarYSubirFoto.
    # We can use regex to find both and replace with one.
    func_pattern = r"Future<void> _tomarYSubirFoto\(\) async \{.*?\s*if \(mounted\) setState\(\(\) => _cargando = false\);\n    \}\n  \}"
    matches = list(re.finditer(func_pattern, content, flags=re.DOTALL))
    
    # Let's just completely remove all instances of _tomarYSubirFoto to have a clean slate, then re-insert them where needed.
    content = re.sub(func_pattern, "", content, flags=re.DOTALL)
    
    # 2. Insert _tomarYSubirFoto correctly into AdminHomePage and ClientHomePage
    tomar_foto_code_admin = """
  Future<void> _tomarYSubirFoto() async {
    if (_cliente == null) return;
    
    final picker = ImagePicker();
    
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Seleccionar origen', style: TextStyle(color: AppColors.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.gold),
              title: const Text('Cámara', style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.gold),
              title: const Text('Galería', style: TextStyle(color: AppColors.text)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _cargando = true);
    try {
      final idCliente = _cliente!['id'];
      final uri = Uri.parse('${ApiConfig.baseUrl}/clientes/$idCliente/foto');
      final request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        pickedFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
      
      final response = await request.send();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto actualizada')));
        }
        await recargarClienteActual();
      } else {
        final respStr = await response.stream.bytesToString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $respStr')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
"""
    # Insert in AdminHomePage
    idx_admin = content.find("class _AdminHomePageState extends State<AdminHomePage>")
    if idx_admin != -1:
        idx_recargar = content.find("Future<void> recargarClienteActual()", idx_admin)
        if idx_recargar != -1:
            content = content[:idx_recargar] + tomar_foto_code_admin + "\n  " + content[idx_recargar:]

    # Insert in ClientHomePage
    tomar_foto_code_client = tomar_foto_code_admin.replace("await recargarClienteActual();", "await _cargarDatosCliente();")
    idx_client = content.find("class _ClientHomePageState extends State<ClientHomePage>")
    if idx_client != -1:
        idx_cargar = content.find("Future<void> _cargarDatosCliente()", idx_client)
        if idx_cargar != -1:
            content = content[:idx_cargar] + tomar_foto_code_client + "\n  " + content[idx_cargar:]


    # 3. Fix the UI for ClientHomePage (so the client can also upload their photo!)
    # Look for "Datos del cliente" in ClientHomePage
    if idx_client != -1:
        ui_target_start = "                    Row(\n                      children: const [\n                        Icon(Icons.person, color: AppColors.gold),\n                        SizedBox(width: 8),\n                        Text(\n                          'Datos del cliente'"
        ui_idx = content.find("Row(\n                      children: const [\n                        Icon(Icons.person, color: AppColors.gold),", idx_client)
        if ui_idx != -1:
            end_row_idx = content.find("],\n                    ),", ui_idx)
            if end_row_idx != -1:
                end_row_idx += len("],\n                    ),")
                new_ui = """Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.border,
                              backgroundImage: (_clienteDatos!['foto_url'] != null && _clienteDatos!['foto_url'].toString().isNotEmpty)
                                  ? NetworkImage('${ApiConfig.baseUrl}${_clienteDatos!['foto_url']}')
                                  : null,
                              child: (_clienteDatos!['foto_url'] == null || _clienteDatos!['foto_url'].toString().isEmpty)
                                  ? const Icon(Icons.person, size: 40, color: AppColors.textSoft)
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _tomarYSubirFoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Datos del cliente',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                '${_clienteDatos!['nombres'] ?? ''} ${_clienteDatos!['apellidos'] ?? ''}',
                                style: const TextStyle(color: AppColors.textSoft, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),"""
                content = content[:ui_idx] + new_ui + content[end_row_idx:]


    # 4. Remove `silencioso` if it's lingering anywhere
    content = content.replace("recargarClienteActual(silencioso: true)", "recargarClienteActual()")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("Fixes applied.")

if __name__ == "__main__":
    fix_main()
