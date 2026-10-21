@echo off
setlocal enabledelayedexpansion


:START_LOOP


echo ========================================================
echo       Starting Texas Hold'em BDD Automation Flow (HTTP)
echo ========================================================

:: 1. Static port 50051 and db poker
set /a PORT=50051
set DBNAME="poker"

echo [INFO] HTTP Port:       %PORT%
echo [INFO] Dynamic DB Name: %DBNAME%

:: 4. Wait for server to listen on the port
echo [INFO] Waiting for server to become ready on port %PORT%...
powershell -NoProfile -Command ^
    "$port = %PORT%; " ^
    "$ready = $false; " ^
    "for ($i=0; $i -lt 40; $i++) { " ^
    "    try { " ^
    "        $client = New-Object System.Net.Sockets.TcpClient('127.0.0.1', $port); " ^
    "        if ($client.Connected) { " ^
    "            $client.Close(); " ^
    "            $ready = $true; " ^
    "            break; " ^
    "        } " ^
    "    } catch {} " ^
    "    Start-Sleep -Milliseconds 500; " ^
    "} " ^
    "if (-not $ready) { exit 1 }"

if %ERRORLEVEL% neq 0 (
    echo [ERROR] Server failed to start on port %PORT% within 20 seconds.
    goto cleanup
)

echo [INFO] Server is ready!

:: 5. Run BDD Tests with environment variables
echo ========================================================
echo       Running .NET 10 BDD Tests (Reqnroll + xUnit)
echo ========================================================
set "HTTP_PORT=%PORT%"
set "GRPC_PORT=%PORT%"
set "MYSQL_DB=%DBNAME%"

cd /d "%~dp0BDD"
dotnet test --logger "console;verbosity=normal"
set TEST_EXIT_CODE=%ERRORLEVEL%
cd /d "%~dp0"

:cleanup
echo ========================================================
echo       Cleaning Up Server Process on Port %PORT%
echo ========================================================
for /f "tokens=5" %%a in ('netstat -aon ^| findstr /r /c:":%PORT% " ^| findstr LISTENING') do (
    echo [INFO] Terminating PID %%a listening on port %PORT%...
    taskkill /F /T /PID %%a >nul 2>&1
)

:: Also close the cmd window that launched it if any
taskkill /FI "WINDOWTITLE eq Go_Poker_Server_%PORT%*" /F >nul 2>&1

echo [INFO] Done. Test Exit Code: %TEST_EXIT_CODE%
PAUSE
goto START_LOOP
