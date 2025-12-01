# Base Image
FROM python:3.11-slim

# Environment Configuration
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    XDG_DATA_HOME=/home/llmuser/.local/share

# Install System Dependencies (Xvfb is kept for headless=False execution)
RUN apt-get update && apt-get install -y \
    xvfb \
    curl \
    build-essential \
    libgtk-3-0 \
    libasound2 \
    libgbm1 \
    libnss3 \
    libxss1 \
    libxtst6 \
    fonts-liberation \
    libappindicator3-1 \
    xdg-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Playwright
RUN playwright install chromium
RUN playwright install-deps chromium

# App Code
COPY app ./app
COPY scripts ./scripts
RUN chmod +x ./scripts/start.sh

# --- SECURITY FIX: Non-Root User Setup ---
# 1. Create user
RUN useradd -m -u 1000 llmuser

# 2. Permissions for Playwright Browsers (Required so llmuser can access them)
RUN chown -R llmuser:llmuser /ms-playwright

# 3. Permissions for App & Output
RUN chown -R llmuser:llmuser /app

# 4. Persistence & Output Dirs (Setup in user home)
RUN mkdir -p /home/llmuser/.local/share/LLMSession && \
    chown -R llmuser:llmuser /home/llmuser

# --- FIX for Xvfb Socket Error ---
# Pre-create the X11 socket directory with global write permissions (sticky bit)
# so Xvfb can write the socket file (X99) without being root.
RUN mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix
# ---------------------------------

# 5. Switch User
USER llmuser
ENV HOME=/home/llmuser
# -----------------------------------------

EXPOSE 8000

ENTRYPOINT ["./scripts/start.sh"]