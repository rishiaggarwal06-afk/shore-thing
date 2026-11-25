import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/beach.dart';
import '../models/forecast.dart';
import 'http_client.dart';

/// Gets the real 7-day forecast for a beach from Open-Meteo (free, no key needed).
///
/// Two requests per beach: the weather forecast (sky, temperature, rain, wind, UV,
/// sunrise) and the marine forecast (waves, sea temperature). Only the beach's own
/// coordinates are sent, never the user's location. Answers are kept for an hour so
/// flipping between beaches doesn't ask again.
///
/// Open-Meteo's free plan is for non-commercial use: a paid plan is needed once the
/// app has ads or paid features.
class ForecastService {
  ForecastService._();
  static final instance = ForecastService._();

  /// Apple's networking on iPhone (see http_client.dart).
  final http.Client _client = makeHttpClient();

  static const _keepFor = Duration(hours: 1);
  final _cache = <String, ({DateTime at, Future<BeachForecast> forecast})>{};

  Future<BeachForecast> forBeach(Beach b, {bool refresh = false}) {
    final hit = _cache[b.slug];
    if (!refresh && hit != null && DateTime.now().difference(hit.at) < _keepFor) return hit.forecast;
    // Never wait forever: if the network is stuck, give up after 20 seconds and say so.
    // One retry, and never wait forever (two tries of up to 20 s each).
    final f = _fetch(b).catchError((Object _) => _fetch(b)).timeout(const Duration(seconds: 45));
    _cache[b.slug] = (at: DateTime.now(), forecast: f);
    f.catchError((Object _) {
      _cache.remove(b.slug); // don't remember a failure; try again next time
      return BeachForecast(const [], DateTime.now());
    });
    return f;
  }

  Future<BeachForecast> _fetch(Beach b) async {
    final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${b.lat}',
      'longitude': '${b.lon}',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,'
          'precipitation_sum,wind_speed_10m_max,uv_index_max,sunrise,sunset',
      'temperature_unit': 'fahrenheit',
      'wind_speed_unit': 'mph',
      'precipitation_unit': 'inch',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final marineUri = Uri.https('marine-api.open-meteo.com', '/v1/marine', {
      'latitude': '${b.lat}',
      'longitude': '${b.lon}',
      'daily': 'wave_height_max',
      'hourly': 'sea_surface_temperature',
      'timezone': 'auto',
      'forecast_days': '7',
    });
    final weather = _client.get(weatherUri).timeout(const Duration(seconds: 20));
    // The marine forecast is a bonus: if it fails, the weather still shows.
    final marine = _client
        .get(marineUri)
        .timeout(const Duration(seconds: 20))
        .then<Map<String, dynamic>?>((r) => r.statusCode == 200 ? jsonDecode(r.body) as Map<String, dynamic> : null)
        .catchError((Object _) => null);

    final w = await weather;
    if (w.statusCode != 200) throw Exception('Forecast unavailable (${w.statusCode})');
    return parse(jsonDecode(w.body) as Map<String, dynamic>, await marine, DateTime.now());
  }

  /// Turns Open-Meteo's answers into [BeachForecast]. Separate so tests can feed it sample answers.
  static BeachForecast parse(Map<String, dynamic> weather, Map<String, dynamic>? marine, DateTime fetched) {
    final d = weather['daily'] as Map<String, dynamic>;
    final dates = (d['time'] as List).cast<String>();

    List<T?> col<T>(Map<String, dynamic>? m, String key, T? Function(num) f) {
      final list = m?[key] as List?;
      return [for (var i = 0; i < dates.length; i++) (list != null && i < list.length && list[i] != null) ? f(list[i] as num) : null];
    }

    final code = col(d, 'weather_code', (v) => v.toInt());
    final hi = col(d, 'temperature_2m_max', (v) => v.round());
    final lo = col(d, 'temperature_2m_min', (v) => v.round());
    final rainChance = col(d, 'precipitation_probability_max', (v) => v.round());
    final rain = col(d, 'precipitation_sum', (v) => v.toDouble());
    final wind = col(d, 'wind_speed_10m_max', (v) => v.round());
    final uv = col(d, 'uv_index_max', (v) => v.toDouble());
    final sunrise = (d['sunrise'] as List?)?.cast<String?>();
    final sunset = (d['sunset'] as List?)?.cast<String?>();

    // Marine: daily biggest waves (metres → feet) and the day's average sea temperature (°C → °F).
    final md = marine?['daily'] as Map<String, dynamic>?;
    final mDates = (md?['time'] as List?)?.cast<String>() ?? const [];
    final mWaves = md?['wave_height_max'] as List? ?? const [];
    final waveByDate = <String, double>{
      for (var i = 0; i < mDates.length && i < mWaves.length; i++)
        if (mWaves[i] != null) mDates[i]: (mWaves[i] as num) * 3.28084,
    };
    final mh = marine?['hourly'] as Map<String, dynamic>?;
    final hTimes = (mh?['time'] as List?)?.cast<String>() ?? const [];
    final hSst = mh?['sea_surface_temperature'] as List? ?? const [];
    final sstSum = <String, double>{}, sstN = <String, int>{};
    for (var i = 0; i < hTimes.length && i < hSst.length; i++) {
      if (hSst[i] == null) continue;
      final day = hTimes[i].substring(0, 10);
      sstSum[day] = (sstSum[day] ?? 0) + (hSst[i] as num);
      sstN[day] = (sstN[day] ?? 0) + 1;
    }

    final days = <DayForecast>[];
    for (var i = 0; i < dates.length; i++) {
      if (hi[i] == null || lo[i] == null) continue;
      final day = dates[i];
      final sst = sstN[day] == null ? null : sstSum[day]! / sstN[day]!;
      days.add(DayForecast(
        date: DateTime.parse(day),
        weatherCode: code[i] ?? 0,
        highF: hi[i]!,
        lowF: lo[i]!,
        rainChance: rainChance[i],
        rainIn: rain[i],
        windMph: wind[i],
        uvIndex: uv[i],
        sunrise: sunrise != null && i < sunrise.length && sunrise[i] != null ? DateTime.tryParse(sunrise[i]!) : null,
        sunset: sunset != null && i < sunset.length && sunset[i] != null ? DateTime.tryParse(sunset[i]!) : null,
        waveFt: waveByDate[day],
        waterF: sst == null ? null : (sst * 9 / 5 + 32).round(),
      ));
    }
    return BeachForecast(days, fetched);
  }
}
