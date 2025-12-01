#!/bin/bash
set -e

DISPLAY_PORT=":99"
# Use environment variable for session dir or default to user home
SESSION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/LLMSession"

echo "--- Starting LLM Session Service (Production) ---"

# 1. CLEANUP: Remove Chrome Singleton Locks & Xvfb Locks
# Prevents crash loops if the container was killed abruptly
if [ -d "$SESSION_DIR" ]; then
    echo "[Startup] Cleaning up stale Chrome locks in $SESSION_DIR..."
    find "$SESSION_DIR" -name "SingletonLock" -delete
    find "$SESSION_DIR" -name "SingletonCookie" -delete
    find "$SESSION_DIR" -name "SingletonSocket" -delete
fi

# Clean up Xvfb lock (Fixes 'Server is already active' error)
if [ -f "/tmp/.X99-lock" ]; then
    echo "[Startup] Removing stale Xvfb lock..."
    rm -f /tmp/.X99-lock
fi

# 2. Start Xvfb
# Required because the providers run with headless=False to avoid detection
echo "[Startup] Launching Xvfb on $DISPLAY_PORT..."
Xvfb $DISPLAY_PORT -ac -screen 0 1280x1024x24 &

# 3. Export DISPLAY
export DISPLAY=$DISPLAY_PORT

echo "[Startup] Waiting for Xvfb..."
sleep 2

# 4. Start FastAPI
echo "[Startup] Launching Uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000