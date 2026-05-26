#!/bin/bash
# Employee Frontend - Bulletproof deployment script
# Ensures latest code is built and served (no Docker cache, no old container)

set -e

IMAGE_NAME="${IMAGE_NAME:-webnox-sprintly-employee-frontend}"
CONTAINER_NAME="${CONTAINER_NAME:-employee-frontend}"
PORT="${PORT:-80}"

echo "Building image: $IMAGE_NAME (--no-cache for fresh build)..."
docker build --no-cache \
  --build-arg BUILD_TIME="$(date +%s)" \
  -t "$IMAGE_NAME" .

echo "Stopping and removing old container (if any)..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "Starting new container..."
docker run -d -p "$PORT":80 --name "$CONTAINER_NAME" "$IMAGE_NAME"

echo "Done. App is at http://localhost:$PORT"
echo "Hard refresh (Cmd+Shift+R / Ctrl+Shift+R) to avoid browser cache."
