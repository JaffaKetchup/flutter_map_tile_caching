@echo off
start cmd /C "dart compile exe tile_server/bin/tile_server.dart && start /b tile_server/bin/tile_server.exe"