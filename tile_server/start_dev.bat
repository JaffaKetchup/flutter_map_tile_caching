@echo off
start cmd /C "dart compile exe bin/tile_server.dart && start /b bin/tile_server.exe"