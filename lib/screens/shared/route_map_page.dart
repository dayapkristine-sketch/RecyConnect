import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/recyclable_post.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch_helper.dart';
import '../../utils/location_helper.dart';
import '../../widgets/osm_map.dart';
import '../../widgets/header_background.dart';

/// Shows collector -> household pin, distance, and opens turn-by-turn
/// directions in the browser/maps app (OpenStreetMap routing, no API key).
class RouteMapPage extends StatefulWidget {
  const RouteMapPage({
    super.key,
    required this.from,
    required this.to,
    required this.title,
    this.fromIsReal = true,
    this.phone,
  });

  final LatLng from;
  final LatLng to;
  final String title;
  final bool fromIsReal;
  final String? phone;

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  bool _tileError = false;
  int _mapVersion = 0;

  @override
  Widget build(BuildContext context) {
    final km = distanceKm(widget.from, widget.to);
    final theme = Theme.of(context);
    final samePlace = km < 0.05;

    return Scaffold(
      appBar: HeaderAppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey(_mapVersion),
            options: samePlace
                ? MapOptions(initialCenter: widget.to, initialZoom: 17)
                : MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds(widget.from, widget.to),
                      padding: const EdgeInsets.fromLTRB(50, 110, 50, 230),
                    ),
                  ),
            children: [
              osmTileLayer(
                onTileError: () {
                  if (mounted && !_tileError) setState(() => _tileError = true);
                },
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [widget.from, widget.to],
                    strokeWidth: 4,
                    color: AppTheme.green,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.from,
                    width: 24,
                    height: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                  Marker(
                    point: widget.to,
                    width: 48,
                    height: 48,
                    alignment: Alignment.topCenter,
                    child: pinIcon(),
                  ),
                ],
              ),
              osmAttribution(),
            ],
          ),
          if (_tileError)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: MapErrorBanner(
                onRetry: () => setState(() {
                  _tileError = false;
                  _mapVersion++;
                }),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(blurRadius: 12, color: Colors.black26),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.near_me, color: AppTheme.brand(context)),
                        const SizedBox(width: 8),
                        Text(
                          '${fmtKm(km)} away (straight line)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (!widget.fromIsReal) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Your location is unavailable, so distance is measured '
                        'from Oroquieta City center.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted(context),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => openOsmDirections(
                              context,
                              widget.from,
                              widget.to,
                            ),
                            icon: const Icon(Icons.directions),
                            label: const Text('Get directions'),
                          ),
                        ),
                        if (widget.phone != null &&
                            widget.phone!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => callPhone(context, widget.phone!),
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
