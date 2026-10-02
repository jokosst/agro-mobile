import 'package:geolocator/geolocator.dart';

class LocationService {
  // Koordinat Default Kebun Cabai Agrocom (Sambas, Kalimantan Barat) sesuai storyboard
  static const double defaultKebunLat = -0.1234;
  static const double defaultKebunLng = 109.3456;
  static const double defaultRadiusMeter = 50.0; // Valid radius <= 50m

  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Fallback to last known position or simulated location
      return await Geolocator.getLastKnownPosition();
    }
  }

  static double calculateDistanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  static bool isWithinGardenRadius({
    required double userLat,
    required double userLng,
    double kebunLat = defaultKebunLat,
    double kebunLng = defaultKebunLng,
    double maxRadius = defaultRadiusMeter,
  }) {
    final distance = calculateDistanceInMeters(
      startLatitude: userLat,
      startLongitude: userLng,
      endLatitude: kebunLat,
      endLongitude: kebunLng,
    );
    return distance <= maxRadius;
  }
}
