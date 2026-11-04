/// Month-by-month conditions for the "Best time to go" strip.
///
/// PLACEHOLDER: these numbers are rough stand-ins so the layout can be built.
/// The next step replaces this with real Open-Meteo climate data.
class MonthConditions {
  const MonthConditions(this.month, this.airF, this.waterF, this.waveFt, this.rainIn);

  final String month;
  final int airF; // typical daytime high
  final int waterF;
  final String waveFt;
  final double rainIn; // monthly total
}

class ClimateService {
  const ClimateService();

  static const isPlaceholder = true;

  List<MonthConditions> monthlyFor(String beachSlug) => const [
        MonthConditions('Jan', 40, 40, '2–4', 3.5),
        MonthConditions('Feb', 42, 39, '2–4', 3.1),
        MonthConditions('Mar', 50, 42, '2–4', 4.1),
        MonthConditions('Apr', 60, 48, '2–3', 3.7),
        MonthConditions('May', 70, 56, '1–3', 3.5),
        MonthConditions('Jun', 79, 64, '1–3', 3.4),
        MonthConditions('Jul', 84, 71, '1–2', 4.0),
        MonthConditions('Aug', 83, 74, '1–3', 4.1),
        MonthConditions('Sep', 77, 71, '2–4', 3.6),
        MonthConditions('Oct', 66, 63, '2–4', 3.6),
        MonthConditions('Nov', 56, 55, '2–4', 3.2),
        MonthConditions('Dec', 45, 46, '2–4', 3.8),
      ];
}
