import 'package:flutter/foundation.dart';

class DownloadConfigurationProvider extends ChangeNotifier {
  static const defaultValues = (
    minZoom: 0,
    maxZoom: 14,
    startTile: 1,
    endTile: null,
    parallelThreads: 3,
    rateLimit: 200,
    maxBufferLength: 0,
    skipExistingTiles: false,
    skipSeaTiles: true,
  );

  int _minZoom = defaultValues.minZoom;
  int get minZoom => _minZoom;
  set minZoom(int newNum) {
    _minZoom = newNum;
    notifyListeners();
  }

  int _maxZoom = defaultValues.maxZoom;
  int get maxZoom => _maxZoom;
  set maxZoom(int newNum) {
    _maxZoom = newNum;
    notifyListeners();
  }

  int _startTile = defaultValues.startTile;
  int get startTile => _startTile;
  set startTile(int newNum) {
    _startTile = newNum;
    notifyListeners();
  }

  int? _endTile = defaultValues.endTile;
  int? get endTile => _endTile;
  set endTile(int? newNum) {
    _endTile = endTile;
    notifyListeners();
  }

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

  String? _selectedStoreName;
  String? get selectedStoreName => _selectedStoreName;
  set selectedStoreName(String? newStoreName) {
    _selectedStoreName = newStoreName;
    notifyListeners();
  }
}
