import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../screens/main/pages/map/map_view.dart';

class MapProvider extends ChangeNotifier {
  UserLocationFollowState _followState = UserLocationFollowState.standard;
  UserLocationFollowState get followState => _followState;
  set followState(UserLocationFollowState newState) {
    _followState = newState;
    notifyListeners();
  }

  MapController _mapController = MapController();
  MapController get mapController => _mapController;
  set mapController(MapController newController) {
    _mapController = newController;
    notifyListeners();
  }

  // ignore: close_sinks
  final _trackLocationStreamController = StreamController<double?>()..add(16);
  late final trackLocationStream =
      _trackLocationStreamController.stream.asBroadcastStream();
  void trackLocation({required bool navigation}) =>
      _trackLocationStreamController.add(navigation ? 18 : 16);

  // ignore: close_sinks
  final _trackHeadingStreamController = StreamController<void>()..add(null);
  late final trackHeadingStream =
      _trackHeadingStreamController.stream.asBroadcastStream();
  void trackHeading() => _trackHeadingStreamController.add(null);
}
