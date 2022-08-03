@ECHO OFF

flutter clean | more
flutter build windows --obfuscate --split-debug-info=/symbols | more