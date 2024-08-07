// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:meta/meta.dart';

/// Largest fully representable integer in Dart
@internal
final largestInt = double.maxFinite.toInt();

/// Smallest fully representable integer in Dart
@internal
final smallestInt = -double.maxFinite.toInt();
