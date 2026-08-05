/// Capital, interés y mora cobrados del mes calendario en curso
/// (`GET /dashboard/cobros_mes`), equivalente móvil de "Cobros del mes en
/// vivo" de Kovra Web. Se recalcula contra la fecha de hoy en cada
/// llamada, así que se "reinicia" solo cada 1ro de mes.
class CobrosMes {
  const CobrosMes({
    required this.capital,
    required this.interes,
    required this.mora,
    required this.total,
  });

  final double capital;
  final double interes;
  final double mora;
  final double total;

  factory CobrosMes.fromJson(Map<String, dynamic> json) {
    return CobrosMes(
      capital: (json['capital'] as num?)?.toDouble() ?? 0,
      interes: (json['interes'] as num?)?.toDouble() ?? 0,
      mora: (json['mora'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }
}
