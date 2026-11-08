/// Typical conditions for one month at one beach (for the "Best time to go" strip).
class MonthConditions {
  const MonthConditions(this.month, this.airF, this.waterF, this.waveFt, this.rainIn);

  final String month; // "Jan" … "Dec"
  final int airF; // average daytime high
  final int waterF; // average sea surface temperature
  final String waveFt; // typical range, e.g. "1–3"
  final double rainIn; // average monthly total

  factory MonthConditions.fromJson(Map<String, dynamic> j) => MonthConditions(
        j['month'] as String,
        j['airF'] as int,
        j['waterF'] as int,
        j['waveFt'] as String,
        (j['rainIn'] as num).toDouble(),
      );
}
