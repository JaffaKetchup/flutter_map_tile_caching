@echo off
start cmd /C "dart compile exe test/tools/tile_server/bin/tile_server.dart && start /b test/tools/tile_server/bin/tile_server.exe"