@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ── Go to project root (one level up from cmdS\) ─────────────────────────
cd /d "%~dp0.."
set "APP_DIR=%CD%\"
title Mail Quota Manager - Launcher

set "RUNTIME=%APP_DIR%.runtime"
set "VENV=%RUNTIME%\venv"
set "PYTHON=%VENV%\Scripts\python.exe"
set "PYTHONW=%VENV%\Scripts\pythonw.exe"
set "EMBED=%RUNTIME%\python"
set "EMBED_PY=%EMBED%\python.exe"
set "EMBED_PYW=%EMBED%\pythonw.exe"
set "PY_VER=3.12.10"
set "PY_ZIP=%RUNTIME%\python-embed.zip"
set "PY_URL=https://www.python.org/ftp/python/%PY_VER%/python-%PY_VER%-embed-amd64.zip"
set "GETPIP=%RUNTIME%\get-pip.py"
set "PIP_URL=https://bootstrap.pypa.io/get-pip.py"

if not exist "%RUNTIME%" mkdir "%RUNTIME%"
echo.
echo ============================================================
echo  Mail Quota Manager - Launcher
echo ============================================================

REM ── If the venv Python already exists, skip all setup ────────────────────
if exist "%PYTHON%" goto INSTALL

REM ── Try system Python first ───────────────────────────────────────────────
set "SYSTEM_PY="
where py >nul 2>&1
if not errorlevel 1 for /f "delims=" %%P in ('py -3 -c "import sys; print(sys.executable)" 2^>nul') do set "SYSTEM_PY=%%P"
if not defined SYSTEM_PY (
  where python >nul 2>&1
  if not errorlevel 1 for /f "delims=" %%P in ('python -c "import sys; print(sys.executable)" 2^>nul') do set "SYSTEM_PY=%%P"
)

if defined SYSTEM_PY (
  echo  Found system Python: !SYSTEM_PY!
  echo  Creating private environment...
  "!SYSTEM_PY!" -m venv "%VENV%" >nul 2>&1
  if exist "%PYTHON%" goto INSTALL
)

REM ── No system Python — download embedded Python ───────────────────────────
if not exist "%EMBED_PY%" (
  echo  Python not found. Downloading local Python %PY_VER%...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_ZIP%'"
  if errorlevel 1 goto ERROR
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%PY_ZIP%' -DestinationPath '%EMBED%' -Force"
  if errorlevel 1 goto ERROR
  del /q "%PY_ZIP%" >nul 2>&1

  REM Patch ._pth so that site-packages is importable
  for %%F in ("%EMBED%\python*._pth") do (
    >> "%%F" echo Lib\site-packages
    >> "%%F" echo import site
  )
)
if not exist "%EMBED_PY%" goto ERROR

REM ── Bootstrap pip into the embedded Python ───────────────────────────────
set "EMBED_PIP=%EMBED%\Scripts\pip.exe"
if not exist "%EMBED_PIP%" (
  if not exist "%GETPIP%" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue';Invoke-WebRequest -Uri '%PIP_URL%' -OutFile '%GETPIP%'"
    if errorlevel 1 goto ERROR
  )
  echo  Installing pip into embedded Python...
  "%EMBED_PY%" "%GETPIP%" --no-warn-script-location >nul 2>&1
  if errorlevel 1 goto ERROR
)
set "PYTHON=%EMBED_PY%"
set "PYTHONW=%EMBED_PYW%"

:INSTALL
echo  Installing/checking local dependencies...
"%PYTHON%" -m pip install --disable-pip-version-check -q -r "%APP_DIR%app\requirements.txt"
if errorlevel 1 goto ERROR

REM ── Launch app detached using pythonw (no console window tied to this CMD)
REM    This means closing this CMD window will NOT kill the app.
REM    The app will only stop when "Stop Application" is clicked in the browser.
echo.
echo  Launching Mail Quota Manager in background...
echo  The app will keep running even if you close this window.
echo.

REM Use pythonw.exe if available, otherwise fallback to wscript wrapper
set "LAUNCHER_PY=%PYTHONW%"
if not exist "%LAUNCHER_PY%" set "LAUNCHER_PY=%PYTHON%"

REM Start detached process - the /b flag + START in a new group detaches it
start "" /b "%LAUNCHER_PY%" "%APP_DIR%app\app.py"

REM Give the server 2 seconds to start then open browser
timeout /t 2 /nobreak >nul 2>&1
start "" "http://127.0.0.1:5000"

echo ============================================================
echo  Server is running at: http://127.0.0.1:5000
echo.
echo  - You can close this window safely
echo  - App will keep running in the background
echo  - To stop: click "Stop Application" in the browser
echo ============================================================
echo.
pause
exit /b 0

:ERROR
echo.
echo  Setup failed. Check your internet connection and try again.
pause
exit /b 1
