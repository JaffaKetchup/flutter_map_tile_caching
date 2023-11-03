import 'dart:typed_data';

abstract interface class BackendStore {
  abstract String name;
}

abstract interface class BackendTile {
  abstract String url;
  abstract DateTime lastModified;
  abstract Uint8List bytes;
}
