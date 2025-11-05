@echo off
REM ===============================================
REM Video Call Testing Setup Script for Windows
REM ===============================================

echo.
echo ================================================
echo Video Call Testing Setup
echo ================================================
echo.

REM Get PC's local IP address
echo [1/4] Finding your PC's local IP address...
echo.
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    echo Found IP: %%a
    set LOCAL_IP=%%a
)
echo.

REM Prompt for IP confirmation
echo ================================================
echo IMPORTANT: Update api_config.dart
echo ================================================
echo.
echo Please update the following file:
echo   elearningit\lib\config\api_config.dart
echo.
echo Change the _pcLocalIp constant to:
echo   static const String _pcLocalIp = 'http://%LOCAL_IP::=%:5000';
echo.
echo Make sure both devices are on the SAME WiFi network!
echo.
pause

echo.
echo [2/4] Checking if backend dependencies are installed...
cd elearningit\backend
if not exist node_modules (
    echo Installing backend dependencies...
    call npm install
) else (
    echo Backend dependencies already installed.
)

echo.
echo [3/4] Starting backend server...
echo.
echo Server will start on port 5000
echo Access from Android device at: http://%LOCAL_IP::=%:5000
echo.
start cmd /k "npm run dev"

echo.
echo [4/4] Ready to start Flutter app...
echo.
echo ================================================
echo Next Steps:
echo ================================================
echo.
echo 1. Update api_config.dart with IP address shown above
echo 2. Connect your Android device via USB (enable USB debugging)
echo 3. Run: flutter devices (to verify device is detected)
echo 4. Run: flutter run (to build and run on Android)
echo.
echo For Web/PC testing, run: flutter run -d chrome
echo.
echo ================================================
echo Backend server is running in separate window
echo ================================================
echo.
pause
