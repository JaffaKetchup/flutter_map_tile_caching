// ignore_for_file: constant_identifier_names

enum RegionMode {
  Square,
  Rectangle,
  Circle,
}

T regionModeBranch<T>(
        RegionMode currentMode, Map<RegionMode, T> possibilities) =>
    possibilities[currentMode]!;
