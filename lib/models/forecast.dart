/// One day of real forecast for a beach (from Open-Meteo).
/// Wave and water numbers come from a second (marine) forecast and can be missing.
class DayForecast {
  const DayForecast({
    required this.date,
    required this.weatherCode,
    required this.highF,
    required this.lowF,
    this.rainChance,
    this.rainIn,
    this.windMph,
    this.uvIndex,
    this.sunrise,
    this.sunset,
    this.waveFt,
    this.waterF,
  });

  final DateTime date; // the day, in the beach's own time zone
  final int weatherCode; // WMO code: 0 = clear, 61 = rain, 95 = thunderstorm, ...
  final int highF;
  final int lowF;
  final int? rainChance; // % chance of rain
  final double? rainIn; // expected rain, inches
  final int? windMph; // strongest wind
  final double? uvIndex;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double? waveFt; // biggest waves of the day
  final int? waterF; // average sea temperature
}

/// The 7-day forecast for one beach, plus when it was fetched.
class BeachForecast {
  const BeachForecast(this.days, this.fetched);
  final List<DayForecast> days;
  final DateTime fetched;
}
