@ECHO OFF

flutter clean | more
flutter build apk --split-per-abi --obfuscate --split-debug-info=/symbols | more
goto :choice

:choice
set /P c=Install ('app-armeabi-v7a-release.apk') over active ADB connection [Y/N]? 
if /I "%c%" EQU "Y" goto :install
if /I "%c%" EQU "N" EXIT /B
goto :choice


:install
adb install build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
EXIT /B