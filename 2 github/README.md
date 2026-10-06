# Mail Quota Manager — Cross-Platform Portable Local App

A lightweight local web application built with Python, Flask, SQLite and vanilla JavaScript.

## Supported Launchers

| File | Platform | Purpose |
|------|-----------|---------|
| `cmdS/run.bat` | Windows | Start the application |
| `cmdS/run.sh` | macOS / Linux | Start the application |
| `cmdS/clean.bat` | Windows | Deep clean `.runtime` & cache (downloaded Python, packages, bytecode) |
| `cmdS/clean.sh` | macOS / Linux | Deep clean `.runtime` & cache (downloaded Python, packages, bytecode) |

## Project Layout

```text
mail_quota_cross_platform/
├── app/                        # Application Source Code & Dependencies
│   ├── app.py                  # Flask backend & API routes
│   ├── requirements.txt        # Python dependency specifications (Flask)
│   └── templates/
│       └── index.html          # Web UI & client-side dashboard
│
├── cmdS/                       # Launchers & Utility Command Scripts
│   ├── run.bat                 # Windows one-click launcher
│   ├── run.sh                  # macOS / Linux terminal launcher
│   ├── clean.bat               # Windows runtime & dependency cleaner
│   └── clean.sh                # macOS / Linux runtime & dependency cleaner
│
├── data/                       # User Data Folder (auto-created)
│   └── mail_quota.db           # SQLite database (YOUR DATA - SAFE)
│
├── .runtime/                   # Downloaded Runtime & Cache Folder (auto-created)
│   ├── venv/                   # Private virtual environment
│   └── python/                 # Embedded Python package (if downloaded on Windows)
│
└── README.md                   # Project documentation
```

### File Categories & Safety

| Category | Location / Files | Can Delete? | Notes |
|----------|-------------------|:-----------:|-------|
| **Core App** | `app/` (`app.py`, `requirements.txt`, `templates/`), `README.md` | ❌ No | Essential program files. |
| **Launchers** | `cmdS/` | ❌ No | Command scripts to launch and manage the app. |
| **Your Data** | `data/mail_quota.db` | ⚠️ Only to reset | Contains all your saved emails and reset dates. Never touched by clear scripts. |
| **Supporting Downloads & Cache**| `.runtime/`, `app/__pycache__/` | ✅ Safe to delete | Downloaded Python, pip packages, virtual environments, and cache. `clean.bat` wipes them completely clean. |

## How to Run

### Windows
Double-click `cmdS\run.bat`.

- The launcher automatically detects Python. If found, it creates an isolated `.runtime\venv` and installs dependencies from `app\requirements.txt`.
- If no Python is installed on your computer, it automatically downloads official Python 3.12.10 Windows embeddable package into `.runtime\python` and configures everything automatically.
- Your browser opens automatically at `http://127.0.0.1:5000`.

### macOS / Linux
Open your Terminal inside this project folder and run:

```bash
chmod +x cmdS/run.sh cmdS/clean.sh
./cmdS/run.sh
```

- The script searches for `python3`/`python` and creates an isolated `.runtime/venv`.
- On Linux x86_64 without Python, it can bootstrap a local build inside `.runtime`.
- On macOS or other architectures, install Python 3.9+ once and run `./cmdS/run.sh`.

## Security & Local Privacy

- **URL:** The app runs strictly on `http://127.0.0.1:5000` (loopback only, not exposed to your local network or internet).
- **No external telemetry:** All data stays locally on your device.

## Stopping the Application

Click **Stop Application** in the web interface (or press `Ctrl+C` in the terminal/console window).
- Stopping the server **preserves all your data** in `data/mail_quota.db`.

## Backup & Restore

- **Backup:** Simply copy the `data/mail_quota.db` file to your backup location.
- **Restore:** Place your backup `mail_quota.db` back into the `data/` folder.

## Clearing Runtime / Freeing Disk Space

If you want to completely reset the environment, free up disk space, or remove all downloaded external packages and Python binaries:
- **Windows:** Double-click `cmdS\clean.bat` and type `YES`.
- **macOS / Linux:** Run `./cmdS/clean.sh` and type `YES`.

This will completely delete `.runtime/` (including any downloaded Python, venvs, and pip packages) and all bytecode cache (`__pycache__`). 
Your database (`data/mail_quota.db`) and all core program files (`app/`, `cmdS/`) are **never touched**.
When you run `cmdS\run.bat` again, it will freshly initialize everything.
