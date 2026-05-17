#!/usr/bin/env bash
export HF_HUB_ENABLE_HF_TRANSFER=1
pkill -f "python main.py" || true
pkill -f "watchdog.py" || true
sleep 1
if [ -f /workspace/watchdog.py ]; then
  WATCHDOG_GRACE=12000 python3 /workspace/watchdog.py --port 3030 &
fi
cd /workspace/ComfyUI && exec /workspace/comfy-env/bin/python main.py --listen --port 3001 --enable-cors-header
