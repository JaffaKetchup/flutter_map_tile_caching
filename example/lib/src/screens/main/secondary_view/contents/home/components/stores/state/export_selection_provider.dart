import 'package:flutter/foundation.dart';

class ExportSelectionProvider extends ChangeNotifier {
  final List<String> _selectedStores = [];
  List<String> get selectedStores => _selectedStores;
  void addSelectedStore(String storeName) {
    _selectedStores.add(storeName);
    notifyListeners();
  }

  void removeSelectedStore(String storeName) {
    _selectedStores.remove(storeName);
    notifyListeners();
  }

  void clearSelectedStores() {
    _selectedStores.clear();
    notifyListeners();
  }
}
