import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:gimnasio_app/utils/api_client.dart';

import '../models/scale_reading.dart';

/// Repositorio responsable de comunicar el módulo de báscula con el backend.
/// Toda la lógica de red está aislada aquí, sin conocimiento de la UI.
class ScaleRepository {
  final String baseUrl;

  ScaleRepository({required this.baseUrl});

  // ─── Guardar pesaje ───────────────────────────────────────────────────────

  /// Envía un nuevo registro de pesaje al backend y retorna el objeto guardado.
  Future<ScaleReading> guardarPesaje(ScaleReading pesaje) async {
    final uri = Uri.parse('$baseUrl/pesajes-bascula/');
    final response = await ApiClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(pesaje.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ScaleReading.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Error al guardar pesaje: ${response.statusCode} — ${response.body}',
    );
  }

  // ─── Historial de un cliente ──────────────────────────────────────────────

  /// Obtiene el historial de pesajes de un cliente ordenado del más reciente al más antiguo.
  Future<List<ScaleReading>> obtenerHistorial(int clienteId) async {
    final uri = Uri.parse(
      '$baseUrl/pesajes-bascula/cliente/$clienteId',
    );
    final response = await ApiClient.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => ScaleReading.fromJson(item)).toList();
    }
    throw Exception(
      'Error al obtener historial: ${response.statusCode} — ${response.body}',
    );
  }

  Future<Map<String, dynamic>?> buscarClientePorCedula(String cedula) async {
    final uri = Uri.parse('$baseUrl/clientes/por-cedula/$cedula');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Obtiene la última estatura (en cm) registrada para el cliente desde Evaluaciones Físicas.
  Future<double?> obtenerUltimaEstatura(String cedula) async {
    final uri = Uri.parse('$baseUrl/evaluaciones-fisicas/cliente-cedula/$cedula');
    final response = await ApiClient.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['ultima_evaluacion'] != null && data['ultima_evaluacion']['estatura'] != null) {
        // La estatura suele estar en metros (ej. 1.75). La pasamos a cm (175.0).
        final estaturaMetro = double.tryParse(data['ultima_evaluacion']['estatura'].toString()) ?? 0.0;
        if (estaturaMetro > 0) {
          return estaturaMetro < 3.0 ? estaturaMetro * 100.0 : estaturaMetro;
        }
      }
    }
    return null;
  }

  // ─── Eliminar pesaje ──────────────────────────────────────────────────────

  /// Elimina un registro de pesaje por su ID.
  Future<void> eliminarPesaje(int id) async {
    final uri = Uri.parse('$baseUrl/pesajes-bascula/$id');
    final response = await ApiClient.delete(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al eliminar pesaje: ${response.statusCode} — ${response.body}',
      );
    }
  }
}
