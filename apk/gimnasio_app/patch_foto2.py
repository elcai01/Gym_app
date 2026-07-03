import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    # Find the line for "Future<void> recargarClienteActual"
    func_idx = -1
    for i, line in enumerate(lines):
        if "Future<void> recargarClienteActual(" in line:
            func_idx = i
            break
            
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
        await recargarClienteActual(silencioso: true);
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
        lines.insert(func_idx, tomar_foto_code)
        with open(file_path, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print("Done")
    else:
        print("Function not found")

if __name__ == "__main__":
    main()
