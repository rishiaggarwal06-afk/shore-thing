import 'package:beach_finder/services/forecast_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sample answers shaped like Open-Meteo's, so the forecast reader is checked without the internet.
void main() {
  test('reads the weather and marine forecasts into days', () {
    final weather = {
      'daily': {
        'time': ['2026-11-23', '2026-11-24'],
        'weather_code': [0, 61],
        'temperature_2m_max': [74.6, 70.2],
        'temperature_2m_min': [65.1, 63.9],
        'precipitation_probability_max': [5, 80],
        'precipitation_sum': [0.0, 0.42],
        'wind_speed_10m_max': [9.8, 18.3],
        'uv_index_max': [6.1, 3.0],
        'sunrise': ['2026-11-23T06:52', '2026-11-24T06:53'],
        'sunset': ['2026-11-23T17:47', '2026-11-24T17:47'],
      },
    };
    final marine = {
      'daily': {
        'time': ['2026-11-23', '2026-11-24'],
        'wave_height_max': [0.6, 1.5],
      },
      'hourly': {
        'time': ['2026-11-23T00:00', '2026-11-23T12:00', '2026-11-24T00:00'],
        'sea_surface_temperature': [25.0, 26.0, 24.0],
      },
    };
    final f = ForecastService.parse(weather, marine, DateTime(2026, 11, 23, 9));
    expect(f.days, hasLength(2));
    final today = f.days.first;
    expect(today.highF, 75);
    expect(today.lowF, 65);
    expect(today.rainChance, 5);
    expect(today.windMph, 10);
    expect(today.waveFt, closeTo(1.97, .01)); // 0.6 m
    expect(today.waterF, 78); // average of 25 and 26 °C
    expect(today.sunset!.hour, 17);
    expect(f.days[1].weatherCode, 61);
    expect(f.days[1].waterF, 75); // 24 °C
  });

  test('works without the marine forecast', () {
    final weather = {
      'daily': {
        'time': ['2026-11-23'],
        'weather_code': [3],
        'temperature_2m_max': [50],
        'temperature_2m_min': [40],
      },
    };
    final f = ForecastService.parse(weather, null, DateTime(2026, 11, 23));
    expect(f.days.single.waveFt, isNull);
    expect(f.days.single.waterF, isNull);
    expect(f.days.single.rainChance, isNull);
  });
}
