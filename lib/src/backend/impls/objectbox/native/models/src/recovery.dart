// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';
import 'package:objectbox/objectbox.dart';

import '../../../../../../../flutter_map_tile_caching.dart';
import 'recovery_region.dart';

/// Represents a [RecoveredRegion]
@Entity()
class ObjectBoxRecovery {
  /// Creates a representation of a [RecoveredRegion]
  ObjectBoxRecovery({
    required this.refId,
    required this.storeName,
    required this.creationTime,
    required this.minZoom,
    required this.maxZoom,
    required this.startTile,
    required this.endTile,
    required this.region,
  });

  /// Creates a representation of a [RecoveredRegion]
  ///
  /// [target] should refer to the [BaseRegion] representation
  /// [ObjectBoxRecoveryRegion].
  ObjectBoxRecovery.fromRegion({
    required this.refId,
    required this.storeName,
    required this.endTile,
    required DownloadableRegion region,
    required ObjectBoxRecoveryRegion target,
  })  : creationTime = DateTime.timestamp(),
        minZoom = region.minZoom,
        maxZoom = region.maxZoom,
        startTile = region.start,
        region = ToOne(target: target);

  /// ObjectBox ID
  ///
  /// Not to be confused with [refId].
  @Id()
  @internal
  int id = 0;

  /// Corresponds to [RecoveredRegion.id]
  @Index()
  @Unique()
  final int refId;

  /// Corresponds to [RecoveredRegion.storeName]
  final String storeName;

  /// The timestamp of when this object was created/stored
  @Property(type: PropertyType.date)
  final DateTime creationTime;

  /// Corresponds to [RecoveredRegion.minZoom] & [DownloadableRegion.minZoom]
  final int minZoom;

  /// Corresponds to [RecoveredRegion.maxZoom] & [DownloadableRegion.maxZoom]
  final int maxZoom;

  /// Corresponds to [RecoveredRegion.start] & [DownloadableRegion.start]
  ///
  /// Is not immutable because it is updated during downloads.
  int startTile;

  /// Corresponds to [RecoveredRegion.end] & [DownloadableRegion.end]
  final int endTile;

  /// Recoverable [MultiRegion]s are implemented in recovery as a single 'root'
  /// [ObjectBoxRecovery] with only this property defined, and linked
  /// [ObjectBoxRecovery]s for each sub-region
  final ToOne<ObjectBoxRecoveryRegion> region;

  /// Convert this object into a [RecoveredRegion]
  RecoveredRegion toRegion() => RecoveredRegion(
        id: refId,
        storeName: storeName,
        time: creationTime,
        minZoom: minZoom,
        maxZoom: maxZoom,
        start: startTile,
        end: endTile,
        region: region.target!.toRegion(),
      );
}
