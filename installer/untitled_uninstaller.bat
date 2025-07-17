@echo off
title untitled Uninstaller
color 0C

echo.
echo ===============================================
echo    untitled Uninstaller
echo ===============================================
echo.

set "INSTALL_DIR=%PROGRAMFILES%\untitled"

echo Uninstalling untitled...
echo.

if exist "%INSTALL_DIR%" (
    echo Removing application files...
    rmdir /S /Q "%INSTALL_DIR%"
    echo ✓ Application files removed
) else (
    echo Application not found in Program Files
)

echo Removing desktop shortcut...
if exist "%USERPROFILE%\Desktop\untitled.lnk" (
    del "%USERPROFILE%\Desktop\untitled.lnk"
    echo ✓ Desktop shortcut removed
) else (
    echo Desktop shortcut not found
)

echo Removing start menu shortcut...
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\untitled" (
    rmdir /S /Q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\untitled"
    echo ✓ Start menu shortcut removed
) else (
    echo Start menu shortcut not found
)

echo.
echo ===============================================
echo    Uninstallation completed successfully!
echo ===============================================
echo.
pause
