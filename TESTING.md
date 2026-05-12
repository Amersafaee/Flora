# Flora Testing Guide

## Before every APK install — run pre-flight
tool\build_and_check.bat

This runs all automated checks then builds the APK only if everything passes.

## Run all unit tests
flutter test --exclude-tags integration

## Run integration tests (requires network and Firebase)
flutter test --tags integration

## What each check catches
- Gemini API key missing → Flora chat will say sorry cannot connect
- Firestore rules missing collection → wiki or community will show permission denied  
- orderBy+where without index → Flora context will crash silently
- Task model unsafe parsing → home screen crashes on startup
- Auth stream not cached → login button spins forever
- Coming soon strings → broken buttons shipped to users
- Flutter analyze issues → compile errors or warnings in production

## Manual tests (cannot be automated)
- Sign in on real device
- Camera identification
- Image upload to Firebase Storage
- Push notifications
- Dark mode on all screens
