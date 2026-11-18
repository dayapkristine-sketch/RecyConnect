import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Oroquieta City center, used as the default map position / fallback.
const LatLng oroquietaCenter = LatLng(8.4856, 123.8054);

final Distance _distance = Distance(roundResult: false);

double distanceKm(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Kilometer, a, b);

class LocationResult {
  const LocationResult(this.point, this.isReal, [this.message]);
  final LatLng point;
  final bool isReal;
  final String? message;
}

/// Never throws. Falls back to the city center with a readable message.
Future<LocationResult> getCurrentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(
        oroquietaCenter,
        false,
        'Location services are turned off.',
      );
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return const LocationResult(
        oroquietaCenter,
        false,
        'Location permission was denied.',
      );
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return LocationResult(LatLng(pos.latitude, pos.longitude), true);
  } catch (_) {
    return const LocationResult(
      oroquietaCenter,
      false,
      'Could not get your location.',
    );
  }
}
