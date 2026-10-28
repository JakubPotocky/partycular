import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;

import '../core/config.dart';

/// Basemap colours, ported from the web app's `lib/map-style.ts`.
class MapPalette {
  const MapPalette({
    required this.land,
    required this.park,
    required this.water,
    required this.building,
    required this.road,
    required this.edge,
    required this.text,
    required this.halo,
  });

  static const light = MapPalette(
    land: '#f1eee8',
    park: '#cde7bd',
    water: '#a8c9ef',
    building: '#e1ded8',
    road: '#ffffff',
    edge: '#dedbd5',
    text: '#69716d',
    halo: '#f1eee8',
  );

  static const dark = MapPalette(
    land: '#202c37',
    park: '#263e3d',
    water: '#35485d',
    building: '#2b3b48',
    road: '#435563',
    edge: '#1b2731',
    text: '#879daa',
    halo: '#202c37',
  );

  final String land, park, water, building, road, edge, text, halo;
}

/// Ready-to-render vector themes for both appearances, sharing one tile source.
class MapStyles {
  const MapStyles({required this.light, required this.dark, required this.tileProviders});

  final vtr.Theme light;
  final vtr.Theme dark;
  final TileProviders tileProviders;

  vtr.Theme forBrightness(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}

/// Builds the basemap from the bundled OpenFreeMap "Liberty"-based style.
class MapStyleRepository {
  MapStyleRepository({required this._client, required this._prefs, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static const styleAsset = 'assets/map/style-base.json';
  static const _tileTemplateKey = 'map.tileTemplate';
  static const _tileMaxZoomKey = 'map.tileMaxZoom';
  static const keys = {_tileTemplateKey, _tileMaxZoomKey};

  final http.Client _client;
  final SharedPreferencesWithCache _prefs;
  final AssetBundle _bundle;

  Future<MapStyles> load() async {
    final base = jsonDecode(await _bundle.loadString(styleAsset)) as Map<String, Object?>;
    final source = await _resolveTileSource();
    final reader = vtr.ThemeReader();
    return MapStyles(
      light: reader.read(recolorStyle(base, MapPalette.light, id: 'partycular-light')),
      dark: reader.read(recolorStyle(base, MapPalette.dark, id: 'partycular-dark')),
      tileProviders: TileProviders({
        'openmaptiles': NetworkVectorTileProvider(urlTemplate: source.template, maximumZoom: source.maxZoom),
      }),
    );
  }

  /// OpenFreeMap publishes versioned tile URLs through TileJSON. The last
  /// known template is remembered so the map also starts without network.
  Future<({String template, int maxZoom})> _resolveTileSource() async {
    try {
      final response = await _client.get(AppConfig.tileJsonUri).timeout(AppConfig.requestTimeout);
      if (response.statusCode == 200) {
        final Object? json = jsonDecode(response.body);
        if (json case {'tiles': [final String template, ...]}) {
          final maxZoom = switch (json) {
            {'maxzoom': final num zoom} => zoom.toInt(),
            _ => 14,
          };
          await _prefs.setString(_tileTemplateKey, template);
          await _prefs.setInt(_tileMaxZoomKey, maxZoom);
          return (template: template, maxZoom: maxZoom);
        }
      }
    } on Exception {
      // Fall through to the remembered template.
    }
    final cached = _prefs.getString(_tileTemplateKey);
    if (cached == null) throw const MapStyleException('Tile source unavailable');
    return (template: cached, maxZoom: _prefs.getInt(_tileMaxZoomKey) ?? 14);
  }

  /// Returns a copy of [base] with paint colours replaced by [palette].
  /// Same rules as `colors()` in the web app's `lib/map-style.ts`.
  static Map<String, Object?> recolorStyle(Map<String, Object?> base, MapPalette palette, {required String id}) {
    final style = jsonDecode(jsonEncode(base)) as Map<String, Object?>;
    style['id'] = id;
    final layers = (style['layers'] as List<Object?>).cast<Map<String, Object?>>();
    for (final layer in layers) {
      final paint = Map<String, Object?>.from((layer['paint'] as Map<String, Object?>?) ?? const {});
      paint.addAll(_layerColors(layer, palette));
      layer['paint'] = paint;
    }
    return style;
  }

  static Map<String, String> _layerColors(Map<String, Object?> layer, MapPalette p) {
    final type = layer['type'];
    final id = layer['id'] as String? ?? '';
    final source = layer['source-layer'] as String? ?? '';
    if (type == 'background') return {'background-color': p.land};
    if (type == 'symbol') return {'text-color': p.text, 'text-halo-color': p.halo};
    var color = p.land;
    if (source == 'water' || source == 'waterway') {
      color = p.water;
    } else if (source == 'park' || source == 'landcover' || RegExp('cemetery|pitch').hasMatch(id)) {
      color = p.park;
    } else if (source == 'building') {
      color = p.building;
    } else if (source == 'transportation' || source == 'aeroway') {
      color = RegExp('casing|rail').hasMatch(id) ? p.edge : p.road;
    } else if (source == 'boundary') {
      color = p.edge;
    }
    return switch (type) {
      'fill' => {'fill-color': color, 'fill-outline-color': color},
      'line' => {'line-color': color},
      _ => const {},
    };
  }
}

class MapStyleException implements Exception {
  const MapStyleException(this.message);

  final String message;

  @override
  String toString() => 'MapStyleException: $message';
}
