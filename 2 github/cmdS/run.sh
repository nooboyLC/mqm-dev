#!/usr/bin/env bash
set -e

# ── Go to project root (one level up from cmdS/) ────────────────────────
cd "$(dirname "$0")/.."
APP_DIR="$(pwd)"
RUNTIME="$APP_DIR/.runtime"
VENV="$RUNTIME/venv"
PYTHON="$VENV/bin/python"
EMBED="$RUNTIME/python"
PY_VER="3.12.10"
PIDFILE="$RUNTIME/app.pid"

mkdir -p "$RUNTIME"

echo
echo "============================================================"
echo " Mail Quota Manager - Launcher"
echo "============================================================"

# ── Prefer a usable system Python ────────────────────────────────────────
if [ ! -x "$PYTHON" ]; then
    SYSTEM_PY=""
    for CMD in python3 python; do
        if command -v "$CMD" >/dev/null 2>&1; then
            if "$CMD" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3,9) else 1)' >/dev/null 2>&1; then
                SYSTEM_PY="$(command -v "$CMD")"
                break
            fi
        fi
    done

    if [ -n "$SYSTEM_PY" ]; then
        echo " Found system Python: $SYSTEM_PY"
        echo " Creating private environment inside .runtime..."
        "$SYSTEM_PY" -m venv "$VENV"
    fi
fi

# ── Fallback: build CPython from source (Linux x86_64 only) ──────────────
if [ ! -x "$PYTHON" ]; then
    ARCH="$(uname -m)"
    OS="$(uname -s)"

    if [ "$OS" = "Linux" ] && [ "$ARCH" = "x86_64" ]; then
        TARBALL="$RUNTIME/Python-$PY_VER.tgz"
        SRC="$RUNTIME/Python-$PY_VER"
        URL="https://www.python.org/ftp/python/$PY_VER/Python-$PY_VER.tgz"
        if [ ! -d "$SRC" ]; then
            command -v curl >/dev/null 2>&1 || { echo " curl is required."; exit 1; }
            curl -L "$URL" -o "$TARBALL"
            tar -xzf "$TARBALL" -C "$RUNTIME"
            rm -f "$TARBALL"
        fi
        cd "$SRC"
        ./configure --prefix="$EMBED" --with-ensurepip=install
        make -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
        make install
        cd "$APP_DIR"
        PYTHON="$EMBED/bin/python3"
    else
        echo " Please install Python 3.9+ and run this launcher again."
        exit 1
    fi
fi

echo " Installing/checking dependencies..."
"$PYTHON" -m pip install --disable-pip-version-check -q -r "$APP_DIR/app/requirements.txt"

# ── Launch detached with nohup so closing terminal won't kill app ─────────
echo
echo " Launching Mail Quota Manager in background..."
nohup "$PYTHON" "$APP_DIR/app/app.py" > "$RUNTIME/app.log" 2>&1 &
APP_PID=$!
echo $APP_PID > "$PIDFILE"

sleep 1.5

# Open browser
if command -v open >/dev/null 2>&1; then
    open "http://127.0.0.1:5000" >/dev/null 2>&1 &
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://127.0.0.1:5000" >/dev/null 2>&1 &
fi

echo "============================================================"
echo " Server is running at: http://127.0.0.1:5000  (PID: $APP_PID)"
echo
echo " - You can close this terminal safely"
echo " - App will keep running in the background"
echo " - To stop: click \"Stop Application\" in the browser"
echo " - Logs: $RUNTIME/app.log"
echo "============================================================"
echo
