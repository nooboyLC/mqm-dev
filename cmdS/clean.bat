@echo off
setlocal EnableExtensions

REM ── Go to project root (one level up from cmdS\) ─────────────────────────
cd /d "%~dp0.."
set "APP_DIR=%CD%\"
set "RUNTIME=%APP_DIR%.runtime"

title Mail Quota Manager - Deep Clean Runtime and Cache

echo.
echo ============================================================
echo  Mail Quota Manager - Deep Clean Runtime and Cache
echo ============================================================
echo.
echo  This will COMPLETELY REMOVE all downloaded support files:
echo   [x] .runtime\          - Downloaded Python, VirtualEnv, pip packages
echo   [x] app\__pycache__\   - Python compiled bytecode cache
echo   [x] All temporary cache and build artifacts
echo.
echo  This will NEVER touch:
echo   [+] app\               - Application code, templates, requirements
echo   [+] cmdS\              - Runners and scripts
echo   [+] README.md          - Documentation
echo   [+] data\mail_quota.db - YOUR SAVED DATABASE [COMPLETELY SAFE]
echo.

set "FOUND_ITEMS=0"
if exist "%RUNTIME%" set "FOUND_ITEMS=1"
if exist "%APP_DIR%app\__pycache__" set "FOUND_ITEMS=1"
if exist "%APP_DIR%__pycache__" set "FOUND_ITEMS=1"

if "%FOUND_ITEMS%"=="0" (
  echo  Everything is already clean! No runtime, packages or cache found.
  echo.
  pause
  exit /b 0
)

set "CONFIRM="
set /p CONFIRM="  Type YES to wipe runtime and downloaded dependencies, anything else to cancel: "
if defined CONFIRM set "CONFIRM=%CONFIRM: =%"

if /i not "%CONFIRM%"=="YES" if /i not "%CONFIRM%"=="Y" (
  echo.
  echo  Cancelled. Nothing was deleted.
  echo.
  pause
  exit /b 0
)

echo.
REM 1. Remove .runtime folder
if exist "%RUNTIME%" (
  echo  Removing .runtime folder...
  rd /s /q "%RUNTIME%"
  if errorlevel 1 (
    echo.
    echo  ERROR: Could not completely remove .runtime.
    echo  Please ensure the application server is stopped and no files are open.
    echo.
    pause
    exit /b 1
  )
  echo  [OK] .runtime completely removed.
)

REM 2. Remove app bytecode caches
if exist "%APP_DIR%app\__pycache__" (
  rd /s /q "%APP_DIR%app\__pycache__"
  echo  [OK] app\__pycache__ removed.
)
if exist "%APP_DIR%__pycache__" (
  rd /s /q "%APP_DIR%__pycache__"
  echo  [OK] Root __pycache__ removed.
)

REM 3. Clean any stray .pyc files if present
del /s /q "%APP_DIR%*.pyc" >nul 2>&1

echo.
echo ============================================================
echo  CLEAN COMPLETE: All external downloads, Python environments,
echo  packages, and cache have been wiped clean.
echo  Your database [data\mail_quota.db] and app code are safe.
echo.
echo  Next time you run cmdS\run.bat, everything will be freshly
echo  downloaded and configured.
echo ============================================================
echo.
pause
exit /b 0
