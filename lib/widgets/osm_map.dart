import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:path_provider/path_provider.dart';

dynamic _mapTileStore;

/// Initializes a persistent tile cache so previously viewed map areas remain
/// available after the app restarts or the device loses connectivity.
Future<void> initializeOfflineMapCache() async {
  final directory = await getTemporaryDirectory();
  _mapTileStore = FileCacheStore('${directory.path}/recyconnect_map_tiles');
}

/// OpenStreetMap tile layer. A real userAgentPackageName is required by the
/// OSM tile usage policy; change it to your app id.
TileLayer osmTileLayer({VoidCallback? onTileError}) => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.onsdg.recyconnect',
  tileProvider: _mapTileStore == null
      ? NetworkTileProvider()
      : CachedTileProvider(
          store: _mapTileStore,
          maxStale: const Duration(days: 30),
        ),
  errorTileCallback: onTileError == null
      ? null
      : (tile, error, stackTrace) => onTileError(),
);

/// Attribution is required by OpenStreetMap's license.
Widget osmAttribution() => RichAttributionWidget(
  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
);

Widget pinIcon({Color color = Colors.red, double size = 44}) =>
    Icon(Icons.location_on, color: color, size: size);

/// Fallback message when the map cannot load (WBS 1.6.13).
class MapErrorBanner extends StatelessWidget {
  const MapErrorBanner({super.key, required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.orange.shade800,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'This map area is not cached yet. Connect once to download it, then it will work offline.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
