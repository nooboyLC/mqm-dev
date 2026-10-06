#!/usr/bin/env bash
set -e

# ── Go to project root (one level up from cmdS/) ────────────────────────
cd "$(dirname "$0")/.."
APP_DIR="$(pwd)"
RUNTIME="$APP_DIR/.runtime"

echo
echo "============================================================"
echo " Mail Quota Manager - Deep Clean Runtime & Cache"
echo "============================================================"
echo
echo " This will COMPLETELY REMOVE all downloaded support files:"
echo "  [x] .runtime/         (Downloaded Python, VirtualEnv, pip packages, zips)"
echo "  [x] app/__pycache__/  (Python compiled bytecode cache)"
echo "  [x] All temporary cache / build artifacts"
echo
echo " This will NEVER touch:"
echo "  [+] app/              (Application code, templates, requirements)"
echo "  [+] cmdS/             (Runners and scripts)"
echo "  [+] README.md         (Documentation)"
echo "  [+] data/mail_quota.db (YOUR SAVED DATABASE - COMPLETELY SAFE)"
echo

FOUND_ITEMS=0
if [ -d "$RUNTIME" ]; then FOUND_ITEMS=1; fi
if [ -d "$APP_DIR/app/__pycache__" ]; then FOUND_ITEMS=1; fi
if [ -d "$APP_DIR/__pycache__" ]; then FOUND_ITEMS=1; fi

if [ "$FOUND_ITEMS" -eq 0 ]; then
  echo " Everything is already clean! No runtime, packages or cache found."
  echo
  exit 0
fi

printf "  Type YES to wipe runtime & downloaded dependencies, anything else to cancel: "
read -r CONFIRM

if [ "$CONFIRM" != "YES" ]; then
  echo
  echo " Cancelled. Nothing was deleted."
  echo
  exit 0
fi

echo

# 1. Remove .runtime folder (embedded Python, venv, packages, source builds)
if [ -d "$RUNTIME" ]; then
  echo " Removing .runtime (Python binaries, venv, pip, packages)..."
  rm -rf "$RUNTIME"
  echo " [OK] .runtime completely removed."
fi

# 2. Remove app bytecode caches
if [ -d "$APP_DIR/app/__pycache__" ]; then
  rm -rf "$APP_DIR/app/__pycache__"
  echo " [OK] app/__pycache__ removed."
fi
if [ -d "$APP_DIR/__pycache__" ]; then
  rm -rf "$APP_DIR/__pycache__"
  echo " [OK] Root __pycache__ removed."
fi

# 3. Clean stray .pyc files
find "$APP_DIR" -type f -name "*.pyc" -delete 2>/dev/null || true

echo
echo "============================================================"
echo " CLEAN COMPLETE: All external downloads, Python environments,"
echo " packages, and cache have been wiped clean."
echo " Your database (data/mail_quota.db) and app code are safe."
echo
echo " Next time you run ./cmdS/run.sh, everything will be freshly"
echo " downloaded and configured."
echo "============================================================"
echo
