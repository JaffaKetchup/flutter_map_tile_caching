@ECHO OFF

dart pub global activate dartdoc | more
dartdoc | more
dart pub global activate dhttpd | more
dhttpd --path doc/api | more