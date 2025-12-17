@echo off
REM ==========================================
REM Flutter Web Build for GitHub Pages (Windows)
REM ==========================================

echo 🚀 Building Flutter Web for GitHub Pages...

REM Navigate to Flutter project root
cd /d "%~dp0"

REM Clean previous builds
echo 🧹 Cleaning previous builds...
call flutter clean

REM Get dependencies
echo 📦 Getting dependencies...
call flutter pub get

REM Build web with release mode and proper base href for GitHub Pages
echo 🔨 Building web release...
call flutter build web --release --web-renderer html --base-href "/elearning_for_it/"

REM Check if build was successful
if exist "build\web" (
    echo ✅ Web build successful!
    echo 📁 Build output: build\web\
    echo.
    echo Next steps:
    echo 1. The built files are in: build\web\
    echo 2. Push to GitHub and enable GitHub Pages from Settings
    echo 3. Set source to 'gh-pages' branch or 'docs' folder
) else (
    echo ❌ Build failed!
    exit /b 1
)

pause
