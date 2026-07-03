import 'dart:math';

/// Resultado completo de la composición corporal estimada,
/// replicando todas las métricas que muestra el reporte de Xiaomi Home.
class BodyCompositionResult {
  // Datos de entrada
  final double peso;
  final double estaturaCm;
  final int edad;
  final bool esMasculino;
  final double impedancia;

  // Métricas Calculadas
  final double imc;
  final int bodyScore;
  final double bodyWaterMass;     // Masa de agua (kg)
  final double fatMass;           // Masa grasa (kg)
  final double boneMineralContent;// Contenido mineral óseo (kg)
  final double proteinMass;       // Masa de proteína (kg)
  final double muscleMass;        // Masa muscular (kg)
  
  final double fatPercentage;     // % Grasa
  final double musclePercentage;  // % Músculo
  final double waterPercentage;   // % Agua
  final double proteinPercentage;  // % Proteína
  final double bonePercentage;     // % Mineral óseo
  
  final double skeletalMuscleMass;// Masa muscular esquelética (kg)
  final int visceralFatRating;    // Índice de grasa visceral (1-30)
  final int basalMetabolicRate;   // TMB (Kcal)
  final double waistToHipRatio;   // Relación cintura-cadera
  final int bodyAge;              // Edad corporal (años)
  final double fatFreeBodyWeight; // Peso libre de grasa (kg)
  
  // Tipo de Cuerpo
  final String bodyType;          // Clasificación de tipo de cuerpo

  // Recomendaciones
  final double standardWeight;    // Peso estándar ideal (kg)
  final double weightControl;     // Control de peso (kg, ej: -22.7 o +5.0)
  final double fatControl;        // Control de grasa (kg)
  final String muscleControl;     // Control de músculo (ej: "Keep it up" o "Aumentar")

  const BodyCompositionResult({
    required this.peso,
    required this.estaturaCm,
    required this.edad,
    required this.esMasculino,
    required this.impedancia,
    required this.imc,
    required this.bodyScore,
    required this.bodyWaterMass,
    required this.fatMass,
    required this.boneMineralContent,
    required this.proteinMass,
    required this.muscleMass,
    required this.fatPercentage,
    required this.musclePercentage,
    required this.waterPercentage,
    required this.proteinPercentage,
    required this.bonePercentage,
    required this.skeletalMuscleMass,
    required this.visceralFatRating,
    required this.basalMetabolicRate,
    required this.waistToHipRatio,
    required this.bodyAge,
    required this.fatFreeBodyWeight,
    required this.bodyType,
    required this.standardWeight,
    required this.weightControl,
    required this.fatControl,
    required this.muscleControl,
  });

  // Categorías de estados
  String getStatusImc() {
    if (imc < 18.5) return 'Bajo';
    if (imc < 25.0) return 'Standard';
    if (imc < 30.0) return 'Sobrepeso';
    return 'Obeso';
  }

  String getStatusGrasa() {
    final idealMin = esMasculino ? 11.0 : 21.0;
    final idealMax = esMasculino ? 21.9 : 32.9;
    if (fatPercentage < idealMin) return 'Bajo';
    if (fatPercentage <= idealMax) return 'Standard';
    if (fatPercentage < (idealMax + 6.0)) return 'Alto';
    return 'Muy Alto';
  }

  String getStatusMusculo() {
    final idealMin = esMasculino ? 65.0 : 50.0;
    if (musclePercentage < idealMin) return 'Bajo';
    return 'Bueno';
  }

  String getStatusAgua() {
    final idealMin = esMasculino ? 55.0 : 50.0;
    final idealMax = esMasculino ? 65.0 : 60.0;
    if (waterPercentage < idealMin) return 'Bajo';
    if (waterPercentage <= idealMax) return 'Standard';
    return 'Excelente';
  }

  String getStatusProteina() {
    final idealMin = 16.0;
    final idealMax = 20.0;
    if (proteinPercentage < idealMin) return 'Bajo';
    if (proteinPercentage <= idealMax) return 'Standard';
    return 'Excelente';
  }

  String getStatusOseo() {
    final idealMin = esMasculino ? 3.5 : 2.5;
    if (bonePercentage < idealMin) return 'Bajo';
    return 'Standard';
  }

  String getStatusVisceral() {
    if (visceralFatRating < 10) return 'Standard';
    if (visceralFatRating < 15) return 'Alto';
    return 'Muy Alto';
  }

  String getStatusSkeletal() {
    return 'Standard';
  }

  String getStatusWaistHip() {
    final limit = esMasculino ? 0.90 : 0.85;
    if (waistToHipRatio <= limit) return 'Standard';
    return 'Alto';
  }
}

/// Calculadora avanzada de composición corporal basada en BIA
class BodyCompositionCalculator {
  static BodyCompositionResult calcular({
    required double peso,
    required double impedancia,
    required double estaturaCm,
    required int edad,
    required bool esMasculino,
  }) {
    if (estaturaCm > 220 || estaturaCm < 50) estaturaCm = 170.0;
    if (peso < 10 || peso > 200) peso = 70.0;
    if (edad > 99) edad = 99;

    // Si la báscula no pudo medir la impedancia (ej. zapatos puestos), 
    // asignamos un valor promedio para evitar divisiones por cero o cálculos absurdos.
    double imp = impedancia > 0 ? impedancia : 450.0;

    double checkValueOverflow(double value, double minimum, double maximum) {
      if (value < minimum) return minimum;
      if (value > maximum) return maximum;
      return value;
    }

    // 1. Lean Body Mass (LBM)
    double lbm = (estaturaCm * 9.058 / 100.0) * (estaturaCm / 100.0);
    lbm += peso * 0.32 + 12.226;
    lbm -= imp * 0.0068;
    lbm -= edad * 0.0542;

    // 2. Basal Metabolic Rate (BMR)
    double bmr;
    if (!esMasculino) {
      bmr = 864.6 + peso * 10.2036;
      bmr -= estaturaCm * 0.39336;
      bmr -= edad * 6.204;
      if (bmr > 2996) bmr = 5000;
    } else {
      bmr = 877.8 + peso * 14.916;
      bmr -= estaturaCm * 0.726;
      bmr -= edad * 8.976;
      if (bmr > 2322) bmr = 5000;
    }
    final basalMetabolicRate = checkValueOverflow(bmr, 500, 10000).round();

    // 3. Body Fat Percentage
    double constValue;
    if (!esMasculino && edad <= 49) {
      constValue = 9.25;
    } else if (!esMasculino && edad > 49) {
      constValue = 4.95; 
    } else {
      constValue = 0.8;
    }
    
    double coefficient = 1.0;
    if (esMasculino && peso < 61) {
      coefficient = 0.98;
    } else if (!esMasculino && peso > 60) {
      coefficient = 0.96;
      if (estaturaCm > 160) coefficient *= 1.03;
    } else if (!esMasculino && peso < 50) {
      coefficient = 1.02;
      if (estaturaCm > 160) coefficient *= 1.03;
    }
    
    double fatPercentage = (1.0 - (((lbm - constValue) * coefficient) / peso)) * 100.0;
    fatPercentage = checkValueOverflow(fatPercentage, 5.0, 75.0);
    final fatMass = peso * (fatPercentage / 100.0);

    // 4. Body Water Percentage
    double waterPercentage = (100.0 - fatPercentage) * 0.7;
    double coefWater = (waterPercentage <= 50) ? 1.02 : 0.98;
    waterPercentage = checkValueOverflow(waterPercentage * coefWater, 35.0, 75.0);
    final bodyWaterMass = peso * (waterPercentage / 100.0);

    // 5. Bone Mass
    double baseBone = (!esMasculino) ? 0.245691014 : 0.18016894;
    double boneMass = (baseBone - (lbm * 0.05158)) * -1;
    if (!esMasculino) {
       boneMass = (baseBone - (lbm * 0.07158)) * -1;
    }
    boneMass += (boneMass > 2.2) ? 0.1 : -0.1;
    boneMass = checkValueOverflow(boneMass, 0.5, 8.0);
    final boneMineralContent = boneMass;
    final bonePercentage = (boneMass / peso) * 100.0;

    // 6. Muscle Mass
    double muscleMass = peso - ((fatPercentage * 0.01) * peso) - boneMass;
    muscleMass = checkValueOverflow(muscleMass, 10.0, 120.0);
    final double musclePercentage = checkValueOverflow((muscleMass / peso) * 100.0, 10.0, 85.0);

    // Skeletal Muscle Mass (Janssen BIA equation for Dual Mode)
    double smm;
    if (impedancia > 0) {
      double riLf = (estaturaCm * estaturaCm) / imp;
      double sexVal = esMasculino ? 1.0 : 0.0;
      smm = (riLf * 0.401) + (sexVal * 3.825) + (edad * -0.071) + 5.102;
    } else {
      // Sin impedancia real, aproximamos como ~55% de la masa muscular total
      smm = muscleMass * 0.55; 
    }
    if (smm < 0) smm = 0.0;
    final skeletalMuscleMass = smm;

    // 7. Visceral Fat
    double vfal = 0.0;
    if (!esMasculino) {
      if (peso > (13 - (estaturaCm * 0.5)) * -1) {
        double subsubcalc = ((estaturaCm * 1.45) + (estaturaCm * 0.1158) * estaturaCm) - 120;
        double subcalc = peso * 500 / subsubcalc;
        vfal = (subcalc - 6) + (edad * 0.07);
      } else if (peso < 65) {
        double subsubcalc = ((estaturaCm * 1.45) + (estaturaCm * 0.1158) * estaturaCm) - peso;
        double subcalc = peso * 460 / subsubcalc;
        vfal = (subcalc - 6) + (edad * 0.07);
      } else {
        double subcalc = 0.691 + (estaturaCm * -0.0024) + (estaturaCm * -0.0024);
        vfal = (((estaturaCm * 0.027) - (subcalc * peso)) * -1) + (edad * 0.07) - edad;
      }
    } else {
      if (estaturaCm < peso * 1.6) {
        double subcalc = ((estaturaCm * 0.4) - (estaturaCm * (estaturaCm * 0.0826))) * -1;
        vfal = ((peso * 305) / (subcalc + 48)) - 2.9 + (edad * 0.15);
      } else {
        double subcalc = 0.765 + estaturaCm * -0.0015;
        vfal = (((estaturaCm * 0.143) - (peso * subcalc)) * -1) + (16.00 * 0.15) - 5.60;
      }
    }
    final visceralFatRating = checkValueOverflow(vfal, 1, 50).round();

    // 8. BMI
    final estaturaM = estaturaCm / 100.0;
    final imc = peso / (estaturaM * estaturaM);
    
    // Waist to Hip Ratio (estimated)
    final double waistToHipRatio = esMasculino 
        ? (0.82 + (imc * 0.003) + (edad * 0.0005)).clamp(0.75, 1.1)
        : (0.72 + (imc * 0.003) + (edad * 0.0005)).clamp(0.65, 1.0);

    // 9. Protein Percentage
    double proteinPercentage = (muscleMass / peso) * 100.0;
    proteinPercentage -= waterPercentage;
    proteinPercentage = checkValueOverflow(proteinPercentage, 5, 32);
    final proteinMass = peso * (proteinPercentage / 100.0);

    // 10. Metabolic Age (Edad Corporal)
    // Fórmula ajustada para replicar el comportamiento de Xiaomi, donde la masa muscular
    // reduce fuertemente la edad corporal, y la grasa la aumenta levemente.
    double baseFat = esMasculino ? 15.0 : 22.0;
    double baseMuscle = esMasculino ? 45.0 : 35.0;
    double ageAdjust = 0.0;
    
    // Penalización o premio por porcentaje de grasa
    if (fatPercentage > baseFat) {
      ageAdjust += (fatPercentage - baseFat) * 0.15;
    } else {
      ageAdjust -= (baseFat - fatPercentage) * 0.2;
    }
    
    // Premio por alta masa muscular (Xiaomi valora mucho el músculo)
    if (musclePercentage > baseMuscle) {
      ageAdjust -= (musclePercentage - baseMuscle) * 0.25;
    } else {
      ageAdjust += (baseMuscle - musclePercentage) * 0.15;
    }
    
    double metabolicAge = edad + ageAdjust;
    
    // Limitar entre -10 años y +15 años respecto a la edad real
    metabolicAge = metabolicAge.clamp(edad - 10.0, edad + 15.0);
    final bodyAge = checkValueOverflow(metabolicAge, 15, 80).round();
    
    // 12. Puntuación Corporal (Body Score)
    double score = 100.0;
    if (imc > 25.0) score -= (imc - 25.0) * 2.0;
    if (imc < 18.5) score -= (18.5 - imc) * 1.5;
    if (esMasculino && fatPercentage > 20) score -= (fatPercentage - 20);
    else if (!esMasculino && fatPercentage > 28) score -= (fatPercentage - 28);
    final bodyScore = score.round().clamp(40, 100);

    // 13. Clasificación del Tipo de Cuerpo (9 Tipos de Xiaomi)
    String bodyType = 'Balanced';
    if (imc < 18.5) {
      if (fatPercentage < (esMasculino ? 10.0 : 18.0)) bodyType = 'Lean';
      else if (fatPercentage > (esMasculino ? 16.0 : 25.0)) bodyType = 'Slim & muscular';
      else bodyType = 'Underweight';
    } else if (imc <= 25.0) {
      if (fatPercentage < (esMasculino ? 12.0 : 20.0)) bodyType = 'Balanced-muscular';
      else if (fatPercentage > (esMasculino ? 22.0 : 30.0)) bodyType = 'Lack-exercise';
      else bodyType = 'Balanced';
    } else {
      if (fatPercentage < (esMasculino ? 15.0 : 22.0)) bodyType = 'Thick-set';
      else if (fatPercentage > (esMasculino ? 25.0 : 33.0)) bodyType = 'Obese';
      else bodyType = 'Overweight';
    }

    // 14. Peso Estándar Ideal
    final standardWeight = 22.0 * (estaturaM * estaturaM);
    final weightControl = standardWeight - peso;

    // Control de Grasa y Músculo
    final idealFatMass = peso * ((esMasculino ? 15.0 : 22.0) / 100.0);
    final fatControl = idealFatMass - fatMass;

    String muscleControl = 'Keep it up';
    if (musclePercentage < (esMasculino ? 68.0 : 55.0)) {
      muscleControl = '+${(peso * 0.05).toStringAsFixed(1)} kg';
    }
    
    final fatFreeBodyWeight = peso - fatMass;

    return BodyCompositionResult(
      peso: peso,
      estaturaCm: estaturaCm,
      edad: edad,
      esMasculino: esMasculino,
      impedancia: impedancia,
      imc: imc,
      bodyScore: bodyScore,
      bodyWaterMass: bodyWaterMass,
      fatMass: fatMass,
      boneMineralContent: boneMineralContent,
      proteinMass: proteinMass,
      muscleMass: muscleMass,
      fatPercentage: fatPercentage,
      musclePercentage: musclePercentage,
      waterPercentage: waterPercentage,
      proteinPercentage: proteinPercentage,
      bonePercentage: bonePercentage,
      skeletalMuscleMass: skeletalMuscleMass,
      visceralFatRating: visceralFatRating,
      basalMetabolicRate: basalMetabolicRate,
      waistToHipRatio: waistToHipRatio,
      bodyAge: bodyAge,
      fatFreeBodyWeight: fatFreeBodyWeight,
      bodyType: bodyType,
      standardWeight: standardWeight,
      weightControl: weightControl,
      fatControl: fatControl,
      muscleControl: muscleControl,
    );
  }
}
