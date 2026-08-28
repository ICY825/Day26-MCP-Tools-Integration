#!/usr/bin/env bash
# Khởi động ADK web UI cho weather_agent.
# MCP server phải chạy TRƯỚC (cd ../mcp-server && uv run python weather.py),
# vì agent.py kết nối ngay lúc import; server chưa lên thì agent chạy fallback
# mode và không có tool nào.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Thiếu .env — sao chép .env.example rồi điền GOOGLE_API_KEY." >&2
  exit 1
fi

if ! curl -sf -o /dev/null "http://localhost:8085/mcp" 2>/dev/null; then
  echo "Cảnh báo: không thấy MCP server ở localhost:8085." >&2
  echo "          Khởi động nó trước, nếu không agent sẽ không có tool." >&2
fi

export PYTHONUTF8=1
exec uv run adk web
