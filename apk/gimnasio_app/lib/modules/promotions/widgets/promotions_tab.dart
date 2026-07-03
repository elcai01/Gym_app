import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gimnasio_app/main.dart';

class AdminPromotionsTab extends StatefulWidget {
  final String baseUrl;

  const AdminPromotionsTab({super.key, required this.baseUrl});

  @override
  State<AdminPromotionsTab> createState() => _AdminPromotionsTabState();
}

class _AdminPromotionsTabState extends State<AdminPromotionsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estados de Estadísticas
  Map<String, dynamic> _stats = {};
  bool _cargandoStats = false;

  // Estados de Promociones
  List<dynamic> _promociones = [];
  bool _cargandoPromociones = false;

  // Estados de Asignación Manual
  final TextEditingController _documentoCtrl = TextEditingController();
  Map<String, dynamic>? _clienteEncontrado;
  bool _buscandoCliente = false;
  String? _promoSeleccionadaId;
  final TextEditingController _observacionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarStats();
    _cargarPromociones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _documentoCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CARGA DE DATOS DESDE LA API
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _cargarStats() async {
    if (!mounted) return;
    setState(() => _cargandoStats = true);
    try {
      final resp = await http.get(Uri.parse('${widget.baseUrl}/promociones/estadisticas'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _stats = data);
      }
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    } finally {
      if (mounted) setState(() => _cargandoStats = false);
    }
  }

  Future<void> _cargarPromociones() async {
    if (!mounted) return;
    setState(() => _cargandoPromociones = true);
    try {
      final resp = await http.get(Uri.parse('${widget.baseUrl}/promociones/'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _promociones = data);
      }
    } catch (e) {
      debugPrint('Error cargando promociones: $e');
    } finally {
      if (mounted) setState(() => _cargandoPromociones = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCIONES DE CREACIÓN / EDICIÓN
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _guardarPromocion(Map<String, dynamic> promo) async {
    try {
      final resp = await http.post(
        Uri.parse('${widget.baseUrl}/promociones/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(promo),
      );
      if (resp.statusCode == 200) {
        _cargarPromociones();
        _cargarStats();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoción creada con éxito.')),
        );
      } else {
        final err = jsonDecode(resp.body)['detail'] ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con la API: $e')),
      );
    }
  }

  Future<void> _eliminarPromocion(int id) async {
    try {
      final resp = await http.delete(Uri.parse('${widget.baseUrl}/promociones/$id'));
      if (resp.statusCode == 200) {
        _cargarPromociones();
        _cargarStats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promoción eliminada.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ASIGNACIÓN MANUAL
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _buscarCliente() async {
    final doc = _documentoCtrl.text.trim();
    if (doc.isEmpty) return;
    setState(() => _buscandoCliente = true);
    try {
      final resp = await http.get(Uri.parse('${widget.baseUrl}/clientes/por-cedula/$doc'));
      if (resp.statusCode == 200) {
        setState(() => _clienteEncontrado = jsonDecode(resp.body));
      } else {
        setState(() => _clienteEncontrado = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente no encontrado.')),
        );
      }
    } catch (e) {
      debugPrint('Error buscando cliente: $e');
    } finally {
      setState(() => _buscandoCliente = false);
    }
  }

  Future<void> _asignarManual() async {
    if (_clienteEncontrado == null || _promoSeleccionadaId == null) return;
    try {
      final resp = await http.post(
        Uri.parse('${widget.baseUrl}/promociones/asignar-manual'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cliente_id': _clienteEncontrado!['id'],
          'promocion_id': int.parse(_promoSeleccionadaId!),
          'observacion': _observacionCtrl.text.trim(),
        }),
      );
      if (resp.statusCode == 200) {
        _cargarStats();
        _documentoCtrl.clear();
        _observacionCtrl.clear();
        setState(() {
          _clienteEncontrado = null;
          _promoSeleccionadaId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beneficio asignado exitosamente al cliente.')),
        );
      } else {
        final err = jsonDecode(resp.body)['detail'] ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VISTAS DE TAB VIEWS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabStats() {
    if (_cargandoStats && _stats.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    final topUsers = _stats['top_usuarios'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Resumen del Motor de Promociones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _cargarStats),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard('Creadas', _stats['total_creadas']?.toString() ?? '0', Icons.inventory_2, Colors.blue),
              _buildStatCard('Activas', _stats['activas']?.toString() ?? '0', Icons.check_circle, Colors.green),
              _buildStatCard('Vencidas', _stats['vencidas']?.toString() ?? '0', Icons.history, Colors.orange),
              _buildStatCard('Usadas', _stats['total_usadas']?.toString() ?? '0', Icons.done_all, AppColors.gold),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Clientes con Mayor Cantidad de Canjes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          if (topUsers.isEmpty)
            const Text('Aún no se registran canjes.', style: TextStyle(color: Colors.white38))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topUsers.length,
              itemBuilder: (ctx, i) {
                final u = topUsers[i];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.gold.withOpacity(0.2),
                      foregroundColor: AppColors.gold,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(u['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${u['total']} Canjes',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPromociones() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gestión de Promociones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                onPressed: () => _abrirModalPromocion(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Promoción'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _promociones.isEmpty
              ? const Center(child: Text('No hay promociones creadas.', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _promociones.length,
                  itemBuilder: (ctx, i) {
                    final p = _promociones[i];
                    final limite = p['limite_usos'] != null ? p['limite_usos'].toString() : '∞';
                    final tipo = p['tipo_beneficio']?.toString().replaceFirst('_DESC', '% Descuento').replaceAll('_', ' ') ?? '';

                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.gold),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['codigo'] ?? '',
                            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Beneficio: $tipo\nUsos: ${p['usos_realizados']} / $limite | Vigencia: ${p['fecha_inicio']} al ${p['fecha_fin']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _eliminarPromocion(p['id']),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabAsignar() {
    final activePromos = _promociones.where((p) => p['activa'] == true).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Asignación Manual de Beneficios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          const Text(
            'Busca un cliente por su número de cédula y aplícale directamente una promoción activa sin requerir ingreso de código por parte del usuario.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _documentoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cédula o Documento del Cliente',
                    labelStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _buscarCliente,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
                child: _buscandoCliente
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_clienteEncontrado != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cliente Seleccionado:', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    '${_clienteEncontrado!['nombres']} ${_clienteEncontrado!['apellidos']}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('Documento: ${_clienteEncontrado!['documento']}', style: const TextStyle(color: Colors.white70)),
                  Text('Estado: ${_clienteEncontrado!['estado']}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _promoSeleccionadaId,
              dropdownColor: AppColors.card,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Promoción o Beneficio',
                labelStyle: TextStyle(color: Colors.white54),
              ),
              items: activePromos.map<DropdownMenuItem<String>>((p) {
                return DropdownMenuItem<String>(
                  value: p['id'].toString(),
                  child: Text(
                    '${p['nombre']} [${p['codigo']}]',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _promoSeleccionadaId = val),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _observacionCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones internas (Opcional)',
                labelStyle: TextStyle(color: Colors.white54),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _promoSeleccionadaId == null ? null : _asignarManual,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Asignar Beneficio Directo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODALES / DIÁLOGOS DE CREACIÓN DE PROMOCIÓN
  // ──────────────────────────────────────────────────────────────────────────

  void _abrirModalPromocion() {
    final ctrlNombre = TextEditingController();
    final ctrlDesc = TextEditingController();
    final ctrlCodigo = TextEditingController();
    final ctrlFechaIni = TextEditingController();
    final ctrlFechaFin = TextEditingController();
    final ctrlLimite = TextEditingController();
    final ctrlBeneficioPers = TextEditingController();
    final ctrlObs = TextEditingController();
    String tipoBeneficio = '1_MES_GRATIS';
    bool activa = true;
    bool unUsoUsuario = true;
    bool unUsoGlobal = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Text('Nueva Promoción / Beneficio', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrlNombre,
                  decoration: const InputDecoration(labelText: 'Nombre de la Promoción', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlDesc,
                  decoration: const InputDecoration(labelText: 'Descripción larga', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlCodigo,
                  decoration: const InputDecoration(labelText: 'Código Cupón (Ej: DESCUENTO50)', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlFechaIni,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Inicio (AAAA-MM-DD)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) ctrlFechaIni.text = picked.toString().substring(0, 10);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlFechaFin,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Expiración (AAAA-MM-DD)',
                    labelStyle: TextStyle(color: Colors.white60),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) ctrlFechaFin.text = picked.toString().substring(0, 10);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: tipoBeneficio,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Tipo de Beneficio', labelStyle: TextStyle(color: Colors.white60)),
                  items: const [
                    DropdownMenuItem(value: '1_MES_GRATIS', child: Text('1 Mes de Membresía Gratis', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: '15_DIAS_GRATIS', child: Text('15 Días de Membresía Gratis', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: '50_DESC', child: Text('50% Descuento', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: '100_DESC', child: Text('100% Descuento', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'CLASE_PERSONALIZADA', child: Text('Clase Personalizada Gratis', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'ACCESO_VIP', child: Text('Acceso VIP Especial', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'OTRO', child: Text('Otro Beneficio', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) => setDialogState(() => tipoBeneficio = val ?? '1_MES_GRATIS'),
                ),
                if (tipoBeneficio == 'OTRO') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: ctrlBeneficioPers,
                    decoration: const InputDecoration(labelText: 'Describir Beneficio', labelStyle: TextStyle(color: Colors.white60)),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlLimite,
                  decoration: const InputDecoration(labelText: 'Límite global de usos (Omitir para ilimitado)', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Un solo uso por usuario', style: TextStyle(color: Colors.white)),
                  value: unUsoUsuario,
                  onChanged: (val) => setDialogState(() => unUsoUsuario = val),
                  activeColor: AppColors.gold,
                ),
                SwitchListTile(
                  title: const Text('Un solo uso global', style: TextStyle(color: Colors.white)),
                  value: unUsoGlobal,
                  onChanged: (val) => setDialogState(() => unUsoGlobal = val),
                  activeColor: AppColors.gold,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlObs,
                  decoration: const InputDecoration(labelText: 'Observaciones', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white70))),
            FilledButton(
              onPressed: () {
                final limVal = int.tryParse(ctrlLimite.text.trim());
                _guardarPromocion({
                  'nombre': ctrlNombre.text.trim(),
                  'descripcion': ctrlDesc.text.trim(),
                  'codigo': ctrlCodigo.text.trim(),
                  'fecha_inicio': ctrlFechaIni.text.trim(),
                  'fecha_fin': ctrlFechaFin.text.trim(),
                  'activa': activa,
                  'limite_usos': limVal,
                  'un_uso_por_usuario': unUsoUsuario,
                  'un_uso_global': unUsoGlobal,
                  'tipo_beneficio': tipoBeneficio,
                  'beneficio_personalizado': ctrlBeneficioPers.text.trim(),
                  'observaciones': ctrlObs.text.trim(),
                });
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Crear Promoción'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Programa de Promociones y Fidelización', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
            Tab(icon: Icon(Icons.discount), text: 'Promociones'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'Asignación Manual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabStats(),
          _buildTabPromociones(),
          _buildTabAsignar(),
        ],
      ),
    );
  }
}
