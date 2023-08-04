import 'package:flutter/foundation.dart';

class ConfigureDownloadProvider extends ChangeNotifier {
  int _parallelThreads = 5;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  int _rateLimit = 200;
  int get rateLimit => _rateLimit;
  set rateLimit(int newNum) {
    _rateLimit = newNum;
    notifyListeners();
  }

  int _maxBufferLength = 500;
  int get maxBufferLength => _maxBufferLength;
  set maxBufferLength(int newNum) {
    _maxBufferLength = newNum;
    notifyListeners();
  }

  bool _skipExistingTiles = true;
  bool get skipExistingTiles => _skipExistingTiles;
  set skipExistingTiles(bool newState) {
    _skipExistingTiles = newState;
    notifyListeners();
  }

  bool _skipSeaTiles = true;
  bool get skipSeaTiles => _skipSeaTiles;
  set skipSeaTiles(bool newState) {
    _skipSeaTiles = newState;
    notifyListeners();
  }

  bool _isReady = false;
  bool get isReady => _isReady;
  set isReady(bool newState) {
    _isReady = newState;
    notifyListeners();
  }
}
