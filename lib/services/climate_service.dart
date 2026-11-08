import '../models/beach.dart';
import '../models/month_conditions.dart';

/// Month-by-month conditions for the "Best time to go" strip.
///
/// Real numbers come from beaches.json, filled in by tool/fetch_climate.py
/// (Open-Meteo historical weather + marine data). A beach without them yet
/// falls back to clearly labelled placeholder numbers.
class ClimateService {
  const ClimateService();

  ({List<MonthConditions> months, bool placeholder, String? source}) monthlyFor(Beach b) {
    if (b.monthly.length == 12) return (months: b.monthly, placeholder: false, source: b.monthlySource);
    return (months: _placeholder, placeholder: true, source: null);
  }

  static const _placeholder = [
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
