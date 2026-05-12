@echo off
echo Running pre-flight checks...
dart run tool/preflight.dart
if %ERRORLEVEL% neq 0 (
    echo.
    echo Build cancelled. Fix the issues above first.
    exit /b 1
)
echo.
echo Pre-flight passed. Building APK...
flutter build apk --debug
echo.
echo Done. APK is at build\app\outputs\flutter-apk\app-debug.apk
