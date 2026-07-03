import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_client.dart';
import 'package:gimnasio_app/main.dart';

class AdminAutomationTab extends StatefulWidget {
  final String baseUrl;

  const AdminAutomationTab({super.key, required this.baseUrl});

  @override
  State<AdminAutomationTab> createState() => _AdminAutomationTabState();
}

class _AdminAutomationTabState extends State<AdminAutomationTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estados de Cola de Hoy
  List<dynamic> _colaHoy = [];
  bool _cargandoCola = false;

  // Estados de Campañas
  List<dynamic> _campanas = [];
  bool _cargandoCampanas = false;

  // Estados de Plantillas
  List<dynamic> _plantillas = [];
  bool _cargandoPlantillas = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarColaHoy();
    _cargarCampanas();
    _cargarPlantillas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // CARGA DE DATOS DESDE LA API
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _cargarColaHoy() async {
    if (!mounted) return;
    setState(() => _cargandoCola = true);
    try {
      final resp = await ApiClient.get(Uri.parse('${widget.baseUrl}/automatizaciones/programados-hoy'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _colaHoy = data);
      }
    } catch (e) {
      debugPrint('Error cargando cola: $e');
    } finally {
      if (mounted) setState(() => _cargandoCola = false);
    }
  }

  Future<void> _cargarCampanas() async {
    if (!mounted) return;
    setState(() => _cargandoCampanas = true);
    try {
      final resp = await ApiClient.get(Uri.parse('${widget.baseUrl}/campanas/'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _campanas = data);
      }
    } catch (e) {
      debugPrint('Error cargando campañas: $e');
    } finally {
      if (mounted) setState(() => _cargandoCampanas = false);
    }
  }

  Future<void> _cargarPlantillas() async {
    if (!mounted) return;
    setState(() => _cargandoPlantillas = true);
    try {
      final resp = await ApiClient.get(Uri.parse('${widget.baseUrl}/plantillas/'));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) setState(() => _plantillas = data);
      }
    } catch (e) {
      debugPrint('Error cargando plantillas: $e');
    } finally {
      if (mounted) setState(() => _cargandoPlantillas = false);
    }
  }

  Future<void> _forzarReprocesar() async {
    try {
      final resp = await ApiClient.post(Uri.parse('${widget.baseUrl}/automatizaciones/reprocesar-cola'));
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cola diaria regenerada correctamente.')),
        );
        _cargarColaHoy();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCIONES DE CAMPAÑAS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _guardarCampana(Map<String, dynamic> campana) async {
    try {
      final resp = await ApiClient.post(
        Uri.parse('${widget.baseUrl}/campanas/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(campana),
      );
      if (resp.statusCode == 200) {
        _cargarCampanas();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaña guardada con éxito.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando campaña: $e')),
      );
    }
  }

  Future<void> _eliminarCampana(int id) async {
    try {
      final resp = await ApiClient.delete(Uri.parse('${widget.baseUrl}/campanas/$id'));
      if (resp.statusCode == 200) {
        _cargarCampanas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaña eliminada.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error eliminando: $e')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ACCIONES DE PLANTILLAS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _guardarPlantilla(Map<String, dynamic> plantilla) async {
    try {
      final resp = await ApiClient.post(
        Uri.parse('${widget.baseUrl}/plantillas/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(plantilla),
      );
      if (resp.statusCode == 200) {
        _cargarPlantillas();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plantilla guardada con éxito.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando plantilla: $e')),
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // VISTAS DE PESTAÑAS (TAB VIEWS)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabColaHoy() {
    if (_cargandoCola && _colaHoy.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mensajes Programados para Hoy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _cargarColaHoy,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.input,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _forzarReprocesar,
                    icon: const Icon(Icons.sync_problem),
                    label: const Text('Regenerar Cola'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _colaHoy.isEmpty
              ? const Center(
                  child: Text(
                    'No hay mensajes programados para hoy.\nPresiona "Regenerar Cola" para crearlos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.card),
                      columns: const [
                        DataColumn(label: Text('Hora', style: TextStyle(color: AppColors.gold))),
                        DataColumn(label: Text('Usuario', style: TextStyle(color: AppColors.gold))),
                        DataColumn(label: Text('WhatsApp', style: TextStyle(color: AppColors.gold))),
                        DataColumn(label: Text('Tipo', style: TextStyle(color: AppColors.gold))),
                        DataColumn(label: Text('Estado', style: TextStyle(color: AppColors.gold))),
                        DataColumn(label: Text('Enviado / Cancelación', style: TextStyle(color: AppColors.gold))),
                      ],
                      rows: _colaHoy.map<DataRow>((m) {
                        Color statusColor = Colors.orange;
                        if (m['estado'] == 'ENVIADO') statusColor = Colors.green;
                        if (m['estado'] == 'FALLIDO') statusColor = Colors.red;
                        if (m['estado'] == 'CANCELADO') statusColor = Colors.grey;

                        final horaReal = m['hora_real_envio'] != null
                            ? DateTime.parse(m['hora_real_envio']).toLocal().toString().substring(11, 19)
                            : '';
                        final motivo = m['motivo_cancelacion'] ?? m['error'] ?? '';

                        return DataRow(
                          cells: [
                            DataCell(Text(m['hora_programada'] ?? '', style: const TextStyle(color: Colors.white))),
                            DataCell(Text(m['cliente_nombre'] ?? '', style: const TextStyle(color: Colors.white))),
                            DataCell(Text(m['numero_destino'] ?? '', style: const TextStyle(color: Colors.white))),
                            DataCell(Text(m['tipo'] ?? '', style: const TextStyle(color: Colors.white70))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  border: Border.all(color: statusColor),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  m['estado'] ?? '',
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                m['estado'] == 'ENVIADO' ? 'Real: $horaReal' : motivo,
                                style: const TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTabCampanas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Campañas Especiales Configuradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCampana(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Campaña'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _campanas.isEmpty
              ? const Center(
                  child: Text('No hay campañas configuradas.', style: TextStyle(color: Colors.white38)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _campanas.length,
                  itemBuilder: (ctx, i) {
                    final c = _campanas[i];
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          c['activa'] == true ? Icons.campaign : Icons.campaign_outlined,
                          color: c['activa'] == true ? AppColors.gold : Colors.white38,
                          size: 32,
                        ),
                        title: Text(c['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Fecha: ${c['fecha']} a las ${c['hora']} | Aplica a: ${c['aplica_a']}\nPlantilla: ${c['plantilla']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70),
                              onPressed: () => _abrirModalCampana(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarCampana(c['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabPlantillas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Plantillas de Mensajes del Sistema',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              FilledButton.icon(
                onPressed: () => _abrirModalPlantilla(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nueva Plantilla'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _plantillas.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _plantillas.length,
                  itemBuilder: (ctx, i) {
                    final p = _plantillas[i];
                    return Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(p['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text(p['contenido'] ?? '', style: const TextStyle(color: Colors.white70)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.gold),
                              onPressed: () => _abrirModalPlantilla(p),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _confirmarEliminarPlantilla(p),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _confirmarEliminarPlantilla(Map<String, dynamic> p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Eliminar Plantilla', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar la plantilla "${p['nombre']}"?\nEsta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: Colors.white70))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        final resp = await ApiClient.delete(Uri.parse('${widget.baseUrl}/plantillas/${p['id']}'));
        if (resp.statusCode == 200) {
          _cargarPlantillas();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantilla eliminada.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la plantilla.')),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MODALES / DIÁLOGOS DE CREACIÓN Y EDICIÓN
  // ──────────────────────────────────────────────────────────────────────────

  void _abrirModalCampana([Map<String, dynamic>? editCamp]) {
    final ctrlNombre = TextEditingController(text: editCamp?['nombre'] ?? '');
    final ctrlFecha = TextEditingController(text: editCamp?['fecha'] ?? '');
    final ctrlHora = TextEditingController(text: editCamp?['hora'] ?? '09:00');
    final ctrlPlantilla = TextEditingController(text: editCamp?['plantilla'] ?? '');
    bool activa = editCamp?['activa'] ?? true;
    String aplicaA = editCamp?['aplica_a'] ?? 'TODOS';
    bool envioUnico = editCamp?['envio_unico'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            editCamp != null ? 'Editar Campaña' : 'Nueva Campaña Especial',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrlNombre,
                  decoration: const InputDecoration(labelText: 'Nombre de Campaña', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlFecha,
                  decoration: const InputDecoration(
                    labelText: 'Fecha (AAAA-MM-DD)',
                    labelStyle: TextStyle(color: Colors.white60),
                    suffixIcon: Icon(Icons.calendar_today, color: AppColors.gold),
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
                    if (picked != null) {
                      ctrlFecha.text = picked.toString().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlHora,
                  decoration: const InputDecoration(labelText: 'Hora de Envío (HH:MM)', labelStyle: TextStyle(color: Colors.white60)),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: aplicaA,
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(labelText: 'Aplica a', labelStyle: TextStyle(color: Colors.white60)),
                  items: const [
                    DropdownMenuItem(value: 'TODOS', child: Text('Todos los Clientes', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'ACTIVOS', child: Text('Solo Activos', style: TextStyle(color: Colors.white))),
                    DropdownMenuItem(value: 'VENCIDOS', child: Text('Solo Vencidos', style: TextStyle(color: Colors.white))),
                  ],
                  onChanged: (val) => setDialogState(() => aplicaA = val ?? 'TODOS'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: ctrlPlantilla,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Mensaje de Plantilla',
                    labelStyle: TextStyle(color: Colors.white60),
                    helperText: 'Variables: {nombre}, {apellido}, {nombre_gimnasio}',
                    helperStyle: TextStyle(color: Colors.white38),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Campaña Activa', style: TextStyle(color: Colors.white)),
                  value: activa,
                  onChanged: (val) => setDialogState(() => activa = val),
                  activeColor: AppColors.gold,
                ),
                SwitchListTile(
                  title: const Text('Envío Único', style: TextStyle(color: Colors.white)),
                  value: envioUnico,
                  onChanged: (val) => setDialogState(() => envioUnico = val),
                  activeColor: AppColors.gold,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white70))),
            FilledButton(
              onPressed: () {
                _guardarCampana({
                  'nombre': ctrlNombre.text.trim(),
                  'fecha': ctrlFecha.text.trim(),
                  'hora': ctrlHora.text.trim(),
                  'plantilla': ctrlPlantilla.text.trim(),
                  'activa': activa,
                  'aplica_a': aplicaA,
                  'envio_unico': envioUnico,
                });
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirModalPlantilla(Map<String, dynamic>? p) {
    final bool esNueva = p == null;
    final ctrlNombre = TextEditingController(text: p?['nombre'] ?? '');
    final ctrlCodigo = TextEditingController(text: p?['codigo'] ?? '');
    final ctrlContenido = TextEditingController(text: p?['contenido'] ?? '');

    void insertarVariable(String variable, StateSetter setDialogState) {
      final sel = ctrlContenido.selection;
      final text = ctrlContenido.text;
      final val = '{$variable}';
      if (sel.isValid && sel.start >= 0) {
        final newText = text.replaceRange(sel.start, sel.end, val);
        ctrlContenido.text = newText;
        ctrlContenido.selection = TextSelection.collapsed(offset: sel.start + val.length);
      } else {
        ctrlContenido.text = text + val;
      }
      setDialogState(() {});
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            esNueva ? 'Nueva Plantilla' : 'Editar: ${p!['nombre']}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (esNueva) ...
                  [
                    TextField(
                      controller: ctrlNombre,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Plantilla',
                        labelStyle: TextStyle(color: Colors.white60),
                        helperText: 'Ej: Año Nuevo, Día de la Mujer, etc.',
                        helperStyle: TextStyle(color: Colors.white38),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrlCodigo,
                      decoration: const InputDecoration(
                        labelText: 'Código Interno (sin espacios)',
                        labelStyle: TextStyle(color: Colors.white60),
                        helperText: 'Ej: ANO_NUEVO, DIA_MUJER (solo letras y guiones bajos)',
                        helperStyle: TextStyle(color: Colors.white38),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) => ctrlCodigo.text = v.toUpperCase().replaceAll(' ', '_'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: ctrlContenido,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Contenido del Mensaje',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  const Text('Variables disponibles (toca para insertar):', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'nombre',
                      'apellido',
                      'fecha_vencimiento',
                      'dias_restantes',
                      'nombre_gimnasio',
                    ].map((v) {
                      return ActionChip(
                        label: Text('{$v}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.gold,
                        onPressed: () => insertarVariable(v, setDialogState),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            FilledButton(
              onPressed: () {
                final codigo = esNueva
                    ? ctrlCodigo.text.trim().toUpperCase().replaceAll(' ', '_')
                    : p!['codigo'];
                final nombre = esNueva ? ctrlNombre.text.trim() : p!['nombre'];
                if (codigo.isEmpty || nombre.isEmpty || ctrlContenido.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Todos los campos son obligatorios.')),
                  );
                  return;
                }
                _guardarPlantilla({
                  'codigo': codigo,
                  'nombre': nombre,
                  'contenido': ctrlContenido.text.trim(),
                });
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
              child: const Text('Guardar'),
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
        title: const Text('Centro de Automatización Inteligente', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.schedule), text: 'Cola de Hoy'),
            Tab(icon: Icon(Icons.campaign), text: 'Campañas Especiales'),
            Tab(icon: Icon(Icons.wysiwyg), text: 'Plantillas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabColaHoy(),
          _buildTabCampanas(),
          _buildTabPlantillas(),
        ],
      ),
    );
  }
}
