# Khởi động ADK web UI cho weather_agent (Windows/PowerShell).
# MCP server phải chạy TRƯỚC, xem SETUP.md.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".env")) {
    Write-Error "Thiếu .env — sao chép .env.example rồi điền GOOGLE_API_KEY."
}

try {
    Invoke-WebRequest -Uri "http://localhost:8085/mcp" -Method Head -TimeoutSec 3 | Out-Null
} catch {
    Write-Warning "Không thấy MCP server ở localhost:8085. Khởi động nó trước, nếu không agent sẽ không có tool."
}

$env:PYTHONUTF8 = "1"
& ".\.venv\Scripts\adk.exe" web
