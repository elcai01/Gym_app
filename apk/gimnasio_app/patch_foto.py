import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Add imports if not present
    if "import 'package:image_picker/image_picker.dart';" not in content:
        import_idx = content.find("import 'package:http/http.dart'")
        if import_idx != -1:
            imports = "import 'package:image_picker/image_picker.dart';\nimport 'package:http_parser/http_parser.dart';\n"
            content = content[:import_idx] + imports + content[import_idx:]

    # 2. Add _tomarYSubirFoto method to _AdminHomePageState
    # Let's find "Future<void> recargarClienteActual() async {" and insert before it
    func_target = "Future<void> recargarClienteActual() async {"
    func_idx = content.find(func_target)
    if func_idx != -1:
        tomar_foto_code = """
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
        # Ensure we only insert it once
        if "_tomarYSubirFoto" not in content:
            content = content[:func_idx] + tomar_foto_code + content[func_idx:]


    # 3. Replace the UI where it says "Datos del cliente"
    ui_target_start = "                    Row(\n                      children: const [\n                        Icon(Icons.person, color: AppColors.gold),\n                        SizedBox(width: 8),\n                        Text(\n                          'Datos del cliente',\n                          style: TextStyle(\n                            fontSize: 22,\n                            fontWeight: FontWeight.bold,\n                            color: AppColors.text,\n                          ),\n                        ),\n                      ],\n                    ),"
    ui_idx = content.find("Row(\n                      children: const [\n                        Icon(Icons.person, color: AppColors.gold),")
    if ui_idx != -1:
        # Find the end of this Row
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
                              backgroundImage: (_cliente!['foto_url'] != null && _cliente!['foto_url'].toString().isNotEmpty)
                                  ? NetworkImage('${ApiConfig.baseUrl}${_cliente!['foto_url']}')
                                  : null,
                              child: (_cliente!['foto_url'] == null || _cliente!['foto_url'].toString().isEmpty)
                                  ? const Icon(Icons.person, size: 40, color: AppColors.textSoft)
                                  : null,
                            ),
                            if (widget.session.rol == 'ADMIN')
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
                                '${_cliente!['nombres'] ?? ''} ${_cliente!['apellidos'] ?? ''}',
                                style: const TextStyle(color: AppColors.textSoft, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),"""
            
            content = content[:ui_idx] + new_ui + content[end_row_idx:]

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("Done")

if __name__ == "__main__":
    main()
