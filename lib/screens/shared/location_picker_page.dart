import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/osm_map.dart';

/// Opens a full-screen OpenStreetMap. Tap to drop the pin, then "Confirm Pin".
/// Returns the chosen [LatLng] via Navigator.pop. Use readOnly to just view.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initial, this.readOnly = false});

  final LatLng? initial;
  final bool readOnly;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  MapController _controller = MapController();
  late LatLng _center = widget.initial ?? oroquietaCenter;
  double _zoom = 16;
  LatLng? _pin;
  int _mapVersion = 0;
  bool _tileError = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _pin = widget.initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() {
    final old = _controller;
    setState(() {
      _tileError = false;
      _controller = MapController();
      _mapVersion++; // rebuilds the map so tiles are requested again
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    final r = await getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (r.isReal) {
      setState(() => _pin = r.point);
      _controller.move(r.point, 17);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${r.message ?? 'Location unavailable.'} '
            'You can still tap the map to place your pin.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.readOnly ? 'Pinned Location' : 'Pin Pickup Location',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: ValueKey(_mapVersion),
            mapController: _controller,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: 3,
              maxZoom: 19,
              onTap: widget.readOnly
                  ? null
                  : (_, point) => setState(() => _pin = point),
              onPositionChanged: (camera, _) {
                _center = camera.center;
                _zoom = camera.zoom;
              },
            ),
            children: [
              osmTileLayer(
                onTileError: () {
                  if (mounted && !_tileError) setState(() => _tileError = true);
                },
              ),
              if (_pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _pin!,
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
              child: MapErrorBanner(onRetry: _retry),
            ),
          if (!widget.readOnly)
            Positioned(
              right: 16,
              bottom: 190,
              child: FloatingActionButton.small(
                heroTag: 'picker_my_location',
                onPressed: _locating ? null : _useMyLocation,
                child: _locating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _bottomPanel(context),
          ),
        ],
      ),
    );
  }

  Widget _bottomPanel(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _pin == null
                  ? 'Tap the map to drop your pin'
                  : 'Pin: ${_pin!.latitude.toStringAsFixed(5)}, '
                        '${_pin!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 4),
              Text(
                'Zoom in and tap your house or the exact spot for pickup. '
                'Tap again to move the pin.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _pin == null
                      ? null
                      : () => Navigator.pop(context, _pin),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Pin'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
