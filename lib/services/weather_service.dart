import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/weather_model.dart';

class WeatherService {
  /// Konuma göre güncel hava durumunu getirir.
  Future<WeatherModel> fetchWeather() async {
    if (ApiConfig.weatherApiKey.isEmpty) {
      throw 'Hava durumu API anahtarı eksik.\n'
          'Uygulamayı run_config.bat (Windows) veya run_config.sh ile başlat,\n'
          'ya da VS Code launch.json içindeki WEATHER_API_KEY değerini kontrol et.';
    }
    final position = await _getLocation();
    final url = Uri.parse(
      '${ApiConfig.weatherBaseUrl}/weather'
      '?lat=${position.latitude}'
      '&lon=${position.longitude}'
      '&appid=${ApiConfig.weatherApiKey}'
      '&units=metric'
      '&lang=tr',
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    switch (response.statusCode) {
      case 200:
        return WeatherModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      case 401:
        throw 'Geçersiz hava durumu API anahtarı. api_config.dart dosyasını kontrol et.';
      case 429:
        throw 'Hava durumu API istek limiti aşıldı.';
      default:
        throw 'Hava durumu alınamadı (${response.statusCode}).';
    }
  }

  Future<Position> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Konum servisleri kapalı. Lütfen cihaz ayarlarından etkinleştir.';
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Konum izni reddedildi.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin ver.';
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 8),
      ),
    );
  }
}
