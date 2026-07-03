/// Representa un registro de pesaje guardado en la base de datos del backend.
class ScaleReading {
  final int? id;
  final int clienteId;
  final int? usuarioId;
  final DateTime fechaPesaje;

  final double? peso;
  final double? impedancia;
  final double? imc;
  final double? porcentajeGrasa;
  final double? porcentajeMuscular;
  final double? porcentajeOseo;
  final double? porcentajeLiquidos;

  const ScaleReading({
    this.id,
    required this.clienteId,
    this.usuarioId,
    required this.fechaPesaje,
    this.peso,
    this.impedancia,
    this.imc,
    this.porcentajeGrasa,
    this.porcentajeMuscular,
    this.porcentajeOseo,
    this.porcentajeLiquidos,
  });

  factory ScaleReading.fromJson(Map<String, dynamic> json) {
    return ScaleReading(
      id: json['id'] as int?,
      clienteId: json['cliente_id'] as int,
      usuarioId: json['usuario_id'] as int?,
      fechaPesaje: DateTime.parse(json['fecha_pesaje'] as String),
      peso: _toDouble(json['peso']),
      impedancia: _toDouble(json['impedancia']),
      imc: _toDouble(json['imc']),
      porcentajeGrasa: _toDouble(json['porcentaje_grasa']),
      porcentajeMuscular: _toDouble(json['porcentaje_muscular']),
      porcentajeOseo: _toDouble(json['porcentaje_oseo']),
      porcentajeLiquidos: _toDouble(json['porcentaje_liquidos']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cliente_id': clienteId,
      if (usuarioId != null) 'usuario_id': usuarioId,
      'fecha_pesaje': fechaPesaje.toIso8601String().split('T').first,
      if (peso != null) 'peso': peso,
      if (impedancia != null) 'impedancia': impedancia,
      if (imc != null) 'imc': imc,
      if (porcentajeGrasa != null) 'porcentaje_grasa': porcentajeGrasa,
      if (porcentajeMuscular != null) 'porcentaje_muscular': porcentajeMuscular,
      if (porcentajeOseo != null) 'porcentaje_oseo': porcentajeOseo,
      if (porcentajeLiquidos != null) 'porcentaje_liquidos': porcentajeLiquidos,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  String toString() =>
      'ScaleReading(id: $id, clienteId: $clienteId, peso: $peso kg, fecha: $fechaPesaje)';
}
