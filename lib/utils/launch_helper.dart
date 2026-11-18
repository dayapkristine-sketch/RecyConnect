import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> _launch(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<void> callPhone(BuildContext context, String phone) async {
  final ok = await _launch(Uri(scheme: 'tel', path: phone));
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open the dialer. Number: $phone')),
    );
  }
}

/// Turn-by-turn directions on openstreetmap.org (OSRM), no API key needed.
Future<void> openOsmDirections(
  BuildContext context,
  LatLng from,
  LatLng to,
) async {
  final uri = Uri.parse(
    'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car'
    '&route=${from.latitude}%2C${from.longitude}%3B${to.latitude}%2C${to.longitude}',
  );
  final ok = await _launch(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open directions.')));
  }
}
