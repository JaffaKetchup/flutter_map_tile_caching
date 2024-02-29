// Copyright © Luka S (JaffaKetchup) under GPL-v3
// A full license can be found at .\LICENSE

import 'package:objectbox/objectbox.dart';

@Entity()
class ObjectBoxRoot {
  ObjectBoxRoot({
    required this.length,
    required this.size,
  });

  @Id()
  int id = 0;

  int length;
  int size;
}
