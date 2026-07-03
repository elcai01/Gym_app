import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Add Google Fonts import if not present
    if "import 'package:google_fonts/google_fonts.dart';" not in content:
        content = content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\nimport 'package:google_fonts/google_fonts.dart';"
        )

    # 1. Update AppColors
    old_app_colors = """class AppColors {
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
}"""

    new_app_colors = """class AppColors {
  static const Color background = Color(0xFF060608);
  static const Color card = Color(0xFF101014);
  static const Color input = Color(0xFF18181D);
  static const Color border = Color(0xFF22222A);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldSoft = Color(0xFFFCD34D);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFF43F5E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color text = Color(0xFFFDFDFD);
  static const Color textSoft = Color(0xFFA1A1AA);
}"""
    content = content.replace(old_app_colors, new_app_colors)

    # 2. Update ThemeData
    # Replacing TextTheme and adding GoogleFonts
    content = re.sub(
        r"textTheme: const TextTheme\((.*?)\),",
        r"textTheme: GoogleFonts.outfitTextTheme(const TextTheme(\1)),",
        content,
        flags=re.DOTALL
    )

    # Make AppBar uses GoogleFonts
    content = re.sub(
        r"titleTextStyle: TextStyle\(\s*color: AppColors\.text,\s*fontSize: 20,\s*fontWeight: FontWeight\.w700,\s*\),",
        r"titleTextStyle: GoogleFonts.outfit(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),",
        content
    )

    # CardTheme update for glassmorphism/glow
    content = re.sub(
        r"cardTheme: CardThemeData\(.*?\),",
        r"""cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 16,
          shadowColor: AppColors.gold.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          margin: EdgeInsets.zero,
        ),""",
        content,
        flags=re.DOTALL,
        count=1
    )

    # FilledButtonThemeData update
    content = re.sub(
        r"filledButtonTheme: FilledButtonThemeData\(.*?\),",
        r"""filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            elevation: 8,
            shadowColor: AppColors.gold.withValues(alpha: 0.4),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),""",
        content,
        flags=re.DOTALL,
        count=1
    )

    # 3. Fix the "Modificar Fechas" function
    old_modificar_fechas = r"Future<void> abrirModalModificarFechas\(\) async \{.*?\s+child: const Text\('Aplicar Fechas'\),\s+\)\s+\]\s+,\s+\)\s+,\s+\)\s+;"
    
    new_modificar_fechas = """Future<void> abrirModalModificarFechas() async {
    final membresia = obtenerMembresiaPrincipal();
    if (_cliente == null || membresia == null) return;
    
    final hoyString = DateTime.now().toIso8601String().split('T').first;
    final ctrlInicio = TextEditingController(text: hoyString);
    
    final planId = membresia['plan_id'];
    String calculoFin = membresia['fecha_fin']?.split('T')[0] ?? '';
    if (planId != null && planesDuracion.containsKey(planId)) {
      calculoFin = calcularFechaFin(hoyString, planesDuracion[planId]!);
    }
    final ctrlFin = TextEditingController(text: calculoFin);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Text('Forzar Fechas Membresía', style: TextStyle(color: AppColors.gold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Solo SUPER ADMIN. Se recalcula automáticamente la fecha fin.', style: TextStyle(color: AppColors.textSoft, fontSize: 13)),
                const SizedBox(height: 15),
                TextField(
                  controller: ctrlInicio, 
                  decoration: const InputDecoration(labelText: 'Fecha Inicio (YYYY-MM-DD)'),
                  style: const TextStyle(color: AppColors.text),
                  onChanged: (val) {
                    if (val.length == 10 && planId != null && planesDuracion.containsKey(planId)) {
                      setDialogState(() {
                        ctrlFin.text = calcularFechaFin(val, planesDuracion[planId]!);
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: ctrlFin, 
                  decoration: const InputDecoration(labelText: 'Fecha Fin (YYYY-MM-DD)'),
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textSoft))),
              FilledButton(
                onPressed: () async {
                  try {
                    final url = '${ApiConfig.baseUrl}/membresias/${membresia['id']}';
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
                child: const Text('Aplicar Fechas'),
              )
            ],
          );
        }
      ),
    );"""
    
    content = re.sub(old_modificar_fechas, new_modificar_fechas, content, flags=re.DOTALL)

    # Let's fix also _registrarAsistencia if there are date interactions or just _abrirModalMembresia changes:
    # Actually _abrirModalMembresia already initializes with DateTime.now(), so it's good. But the user said:
    # "agregar el tema de que cuando se tomen las fechas se tome bien que el día que se actualicen queden con la fecha del día"
    # This might also apply when an active membership is RENEWED. Where is renew logic?
    # In abrirModalMembresia, when creating it calls _guardarMembresia or similar.
    # What about _renovarMembresia? Did we find it? "No results found" earlier.
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Done")

if __name__ == "__main__":
    main()
