class ScaleMeasurement {
  final double? weight;
  final int? impedance;
  final bool stabilized;
  final bool isFinal;
  final DateTime date;

  ScaleMeasurement({
    this.weight,
    this.impedance,
    this.stabilized = false,
    this.isFinal = false,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'impedance': impedance,
      'stabilized': stabilized,
      'isFinal': isFinal,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ScaleMeasurement(weight: $weight, impedance: $impedance, stabilized: $stabilized, isFinal: $isFinal, date: $date)';
  }
}
