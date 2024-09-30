import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

class ConfigureDownloadProvider extends ChangeNotifier {
  static const defaultValues = (
    parallelThreads: 3,
    rateLimit: 200,
    maxBufferLength: 200,
    skipExistingTiles: false,
    skipSeaTiles: true,
  );

  int _parallelThreads = defaultValues.parallelThreads;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  int _rateLimit = defaultValues.rateLimit;
  int get rateLimit => _rateLimit;
  set rateLimit(int newNum) {
    _rateLimit = newNum;
    notifyListeners();
  }

  int _maxBufferLength = defaultValues.maxBufferLength;
  int get maxBufferLength => _maxBufferLength;
  set maxBufferLength(int newNum) {
    _maxBufferLength = newNum;
    notifyListeners();
  }

  bool _skipExistingTiles = defaultValues.skipExistingTiles;
  bool get skipExistingTiles => _skipExistingTiles;
  set skipExistingTiles(bool newState) {
    _skipExistingTiles = newState;
    notifyListeners();
  }

  bool _skipSeaTiles = defaultValues.skipSeaTiles;
  bool get skipSeaTiles => _skipSeaTiles;
  set skipSeaTiles(bool newState) {
    _skipSeaTiles = newState;
    notifyListeners();
  }

  FMTCStore? _selectedStore;
  FMTCStore? get selectedStore => _selectedStore;
  set selectedStore(FMTCStore? newStore) {
    _selectedStore = newStore;
    notifyListeners();
  }
}
