class TileProgress {
  final String? failedUrl;
  final bool wasSeaTile;
  final bool wasExistingTile;
  final Duration duration;

  TileProgress({
    required this.failedUrl,
    required this.wasSeaTile,
    required this.wasExistingTile,
    required this.duration,
  });
}
