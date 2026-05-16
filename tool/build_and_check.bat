@echo off
echo Running pre-flight checks...
dart run tool/preflight.dart
if %ERRORLEVEL% neq 0 (
    echo.
    echo Build cancelled. Fix preflight issues first.
    exit /b 1
)
echo.
echo Running journey checks...
dart run tool/journey_check.dart
if %ERRORLEVEL% neq 0 (
    echo.
    echo Build cancelled. Fix journey check failures first.
    exit /b 1
)
echo.
echo All checks passed. Building APK...
flutter build apk --debug
echo.
echo Done. APK is at build\app\outputs\flutter-apk\app-debug.apk
