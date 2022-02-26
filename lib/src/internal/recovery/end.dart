import 'dart:io';

Future<void> end(File file) async {
  await file.create(recursive: true);
  await file.delete();
}
