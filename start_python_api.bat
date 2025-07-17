@echo off
echo 🚀 Starting Python AI Material Detection API...
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python not found! Please install Python 3.9+
    pause
    exit /b 1
)

REM Check if requirements are installed
echo 📦 Checking dependencies...
pip show flask >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 Installing dependencies...
    pip install flask opencv-python pytesseract pillow requests easyocr torch transformers ultralytics numpy
)

REM Start the API
echo 🤖 Starting AI API on http://localhost:5000
echo.
echo ✅ Ready for Flutter app!
echo.
python material_detection_api.py

pause
