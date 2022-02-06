import 'package:flutter/cupertino.dart';

class BulkDownloadProvider extends ChangeNotifier {
  int _minZoom = 2;
  int get minZoom => _minZoom;
  set minZoom(int newNum) {
    _minZoom = newNum;
    needsRecalculation = true;
    notifyListeners();
  }

  int _maxZoom = 16;
  int get maxZoom => _maxZoom;
  set maxZoom(int newNum) {
    _maxZoom = newNum;
    needsRecalculation = true;
    notifyListeners();
  }

  int _parallelThreads = 5;
  int get parallelThreads => _parallelThreads;
  set parallelThreads(int newNum) {
    _parallelThreads = newNum;
    notifyListeners();
  }

  bool _preventRedownload = true;
  bool get preventRedownload => _preventRedownload;
  set preventRedownload(bool newBool) {
    _preventRedownload = newBool;
    notifyListeners();
  }

  bool _seaTileRemoval = true;
  bool get seaTileRemoval => _seaTileRemoval;
  set seaTileRemoval(bool newBool) {
    _seaTileRemoval = newBool;
    notifyListeners();
  }

  bool _disableRecovery = false;
  bool get disableRecovery => _disableRecovery;
  set disableRecovery(bool newBool) {
    _disableRecovery = newBool;
    notifyListeners();
  }

  bool _needsRecalculation = false;
  bool get needsRecalculation => _needsRecalculation;
  set needsRecalculation(bool newBool) {
    _needsRecalculation = newBool;
    notifyListeners();
  }
}
