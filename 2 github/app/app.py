"""
Mail Quota Manager — Flask backend
Handles: add / list / delete / update emails, graceful shutdown.

Project layout
--------------
  app/app.py            ← this file
  app/requirements.txt  ← dependencies
  app/templates/        ← Jinja2 templates
  data/                 ← mail_quota.db (auto-created)
  cmdS/                 ← run.bat / run.sh / clean.bat / clean.sh
  .runtime/             ← Python venv / embedded Python (auto-created)
"""

from flask import Flask, render_template, request, jsonify
from pathlib import Path
import sqlite3
import threading
import os
import re
import signal
from datetime import datetime

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
# app/app.py → parent = app/ → parent.parent = project root
_PROJECT_ROOT = Path(__file__).resolve().parent.parent
DB_PATH = _PROJECT_ROOT / "data" / "mail_quota.db"

# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------
app = Flask(__name__)

# ---------------------------------------------------------------------------
# Validation helpers
# ---------------------------------------------------------------------------
_EMAIL_RE = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$")

def _valid_email(value: str) -> bool:
    """Basic RFC-compatible email sanity check (max 254 chars)."""
    return bool(value) and len(value) <= 254 and bool(_EMAIL_RE.match(value))

def _valid_date(value: str) -> bool:
    """Accept only ISO-8601 date strings: YYYY-MM-DD."""
    try:
        datetime.strptime(value, "%Y-%m-%d")
        return True
    except ValueError:
        return False

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
def get_db() -> sqlite3.Connection:
    """Open a new SQLite connection with WAL mode and FK enforcement."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn

def init_db() -> None:
    """Ensure the data/ directory and the mails table exist."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = get_db()
    try:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS mails (
                id         INTEGER PRIMARY KEY AUTOINCREMENT,
                email      TEXT NOT NULL UNIQUE COLLATE NOCASE,
                reset_date TEXT NOT NULL
            )
        """)
        conn.commit()
    finally:
        conn.close()

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/")
def index():
    return render_template("index.html")

@app.post("/add")
def add_mail():
    data = request.get_json(silent=True) or {}
    email      = str(data.get("email", "")).strip().lower()
    reset_date = str(data.get("reset_date", "")).strip()

    if not email or not reset_date:
        return jsonify(success=False, message="Email and reset date are required."), 400

    if not _valid_email(email):
        return jsonify(success=False, message="Invalid email address."), 422

    if not _valid_date(reset_date):
        return jsonify(success=False, message="Invalid date. Use YYYY-MM-DD format."), 422

    conn = get_db()
    try:
        conn.execute(
            "INSERT INTO mails (email, reset_date) VALUES (?, ?)",
            (email, reset_date),
        )
        conn.commit()
    except sqlite3.IntegrityError:
        return jsonify(success=False, message="This email already exists."), 409
    finally:
        conn.close()

    return jsonify(success=True, message="Email added successfully.")

@app.get("/get-mails")
def get_mails():
    conn = get_db()
    try:
        rows = conn.execute(
            "SELECT id, email, reset_date FROM mails ORDER BY reset_date ASC, id ASC"
        ).fetchall()
    finally:
        conn.close()
    return jsonify([dict(row) for row in rows])

@app.post("/delete/<int:mail_id>")
def delete_mail(mail_id):
    if mail_id <= 0:
        return jsonify(success=False, message="Invalid ID."), 400

    conn = get_db()
    try:
        cursor = conn.execute("DELETE FROM mails WHERE id = ?", (mail_id,))
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify(success=False, message="Record not found."), 404
    finally:
        conn.close()

    return jsonify(success=True, message="Record deleted.")

@app.post("/update/<int:mail_id>")
def update_mail(mail_id):
    """Update the reset_date of an existing email record."""
    if mail_id <= 0:
        return jsonify(success=False, message="Invalid ID."), 400

    data = request.get_json(silent=True) or {}
    reset_date = str(data.get("reset_date", "")).strip()

    if not reset_date:
        return jsonify(success=False, message="Reset date is required."), 400

    if not _valid_date(reset_date):
        return jsonify(success=False, message="Invalid date. Use YYYY-MM-DD format."), 422

    conn = get_db()
    try:
        cursor = conn.execute(
            "UPDATE mails SET reset_date = ? WHERE id = ?",
            (reset_date, mail_id),
        )
        conn.commit()
        if cursor.rowcount == 0:
            return jsonify(success=False, message="Record not found."), 404
    finally:
        conn.close()

    return jsonify(success=True, message="Reset date updated.")

@app.post("/shutdown")
def shutdown():
    """Gracefully stop the server. Only accessible from localhost."""
    if request.remote_addr not in ("127.0.0.1", "::1"):
        return jsonify(success=False, message="Local access only."), 403

    def _stop():
        # Allow the HTTP response to be sent before killing the process.
        os.kill(os.getpid(), signal.SIGTERM)

    threading.Timer(0.25, _stop).start()
    return jsonify(success=True, message="Server is shutting down...")

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    init_db()
    print("=" * 60)
    print("  Mail Quota Manager")
    print(f"  Database : {DB_PATH}")
    print("  URL      : http://127.0.0.1:5000")
    print("  Press Ctrl+C to stop the server.")
    print("=" * 60)
    app.run(host="127.0.0.1", port=5000, debug=False, use_reloader=False)
