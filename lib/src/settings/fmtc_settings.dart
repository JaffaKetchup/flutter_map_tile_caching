import '../internal/tile_provider.dart';
import 'tile_provider_settings.dart';

/// Global 'flutter_map_tile_caching' settings
class FMTCSettings {
  /// Default settings used when creating an [FMTCTileProvider]
  ///
  /// Can be overriden on a case-to-case basis when actually creating the tile provider.
  final FMTCTileProviderSettings defaultTileProviderSettings;

  /// Create custom global 'flutter_map_tile_caching' settings
  FMTCSettings({FMTCTileProviderSettings? defaultTileProviderSettings})
      : defaultTileProviderSettings =
            defaultTileProviderSettings ?? FMTCTileProviderSettings();
}
