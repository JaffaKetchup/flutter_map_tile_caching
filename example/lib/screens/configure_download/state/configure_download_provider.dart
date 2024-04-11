import 'package:flutter/foundation.dart';

class ConfigureDownloadProvider extends ChangeNotifier {
  static const defaultValues = {
    'parallelThreads': 5,
    'rateLimit': 200,
    'maxBufferLength': 500,
  };

  int _parallelThreads = defaultValues['parallelThreads']!;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  int _rateLimit = defaultValues['rateLimit']!;
  int get rateLimit => _rateLimit;
  set rateLimit(int newNum) {
    _rateLimit = newNum;
    notifyListeners();
  }

  int _maxBufferLength = defaultValues['maxBufferLength']!;
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
