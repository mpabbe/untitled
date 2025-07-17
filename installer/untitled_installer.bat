@echo off
title untitled Installer
color 0A

echo.
echo ===============================================
echo    untitled Installer
echo ===============================================
echo.

set "INSTALL_DIR=%PROGRAMFILES%\untitled"

echo Installing untitled...
echo.

if not exist "%INSTALL_DIR%" (
    echo Creating installation directory...
    mkdir "%INSTALL_DIR%"
)

echo Copying application files...
xcopy /E /I /H /Y "..\build\windows\runner\Release\*" "%INSTALL_DIR%\" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Files copied successfully
) else (
    echo ✗ Error copying files
    pause
    exit /b 1
)

echo Creating desktop shortcut...
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\untitled.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\untitled.exe'; $Shortcut.Save()" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Desktop shortcut created
) else (
    echo ✗ Error creating desktop shortcut
)

echo Creating start menu shortcut...
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\untitled" (
    mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\untitled"
)
powershell -Command "$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\untitled\untitled.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\untitled.exe'; $Shortcut.Save()" > nul

if %ERRORLEVEL% EQU 0 (
    echo ✓ Start menu shortcut created
) else (
    echo ✗ Error creating start menu shortcut
)

echo.
echo ===============================================
echo    Installation completed successfully!
echo ===============================================
echo.
echo You can find untitled on your desktop
echo and in the start menu.
echo.
pause
