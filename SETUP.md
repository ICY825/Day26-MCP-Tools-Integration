# Hướng dẫn cài đặt & chạy trên Windows

README gốc viết cho macOS/Linux. Trên Windows + PowerShell có ba chỗ sai khác đủ để làm
hỏng bước cài đặt. File này ghi lại môi trường đã dựng thành công, kèm ba lỗi thực tế đã
gặp và cách xử lý.

## Yêu cầu

| Thành phần | Bản đã dùng | Ghi chú |
|---|---|---|
| Python | 3.11.9 | Cho `01`–`03` và `04-lab/mcp-server` |
| Python | 3.14.2 | Cho `04-lab/mcp-client` (`requires-python >=3.12`) |
| uv | 0.12.7 | Chỉ cần cho `04-lab` |
| Git | 2.52.0 | |

## Ba môi trường ảo tách biệt

Repo cần **ba** venv riêng, không dùng chung được. Lý do ở mục "Xung đột phiên bản mcp"
bên dưới.

| Vị trí | Python | Phục vụ |
|---|---|---|
| `.venv/` | 3.11 | `01-function-calling`, `02-mcp-basics`, `03-production` |
| `04-lab/mcp-server/.venv/` | 3.11 | MCP server |
| `04-lab/mcp-client/.venv/` | 3.14 | ADK agent |

### Cài đặt

```powershell
# Môi trường gốc cho 01-03
Set-Location "<đường-dẫn-repo>"
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m pip install uv

# Hai project của lab (dùng uv.lock có sẵn)
Set-Location "<đường-dẫn-repo>\04-lab\mcp-server"
..\..\.venv\Scripts\uv.exe sync --locked

Set-Location "<đường-dẫn-repo>\04-lab\mcp-client"
..\..\.venv\Scripts\uv.exe sync --locked
```

Dùng `--locked` để cài đúng phiên bản trong `uv.lock`.

---

## Ba lỗi thực tế đã gặp

### 1. Console Windows crash khi in tiếng Việt

Chạy `02-mcp-basics/weather_client.py` báo lỗi ngay khi in dòng tiếng Việt đầu tiên:

```
UnicodeEncodeError: 'charmap' codec can't encode character 'ấ'
  File "...\encodings\cp1252.py", line 19, in encode
```

Console Windows mặc định dùng bảng mã cp1252, không biểu diễn được tiếng Việt và emoji.
Kết nối MCP thực ra đã thành công — nó chỉ chết đúng lúc in kết quả ra màn hình.

**Cách xử lý:** bật chế độ UTF-8 của Python bằng biến `PYTHONUTF8=1`. Để khỏi phải nhớ,
thêm dòng sau vào cuối cả ba file activate của mỗi venv:

```powershell
# .venv\Scripts\Activate.ps1
$env:PYTHONUTF8 = "1"
```
```bat
REM .venv\Scripts\activate.bat
set PYTHONUTF8=1
```
```bash
# .venv/Scripts/activate
export PYTHONUTF8=1
```

Sau đó cứ activate là tự có. Nếu gọi `uv run` thẳng mà không activate thì vẫn phải tự set.

### 2. Lệnh tạo `.env` trong README hỏng trên PowerShell

`04-lab/mcp-client/README.md` hướng dẫn:

```bash
echo "GOOGLE_API_KEY=your_google_api_key_here" > .env
```

Trên PowerShell, `>` ghi file kèm **BOM** (ba byte `EF BB BF` ở đầu). Thư viện `dotenv`
đọc tên biến thành `﻿GOOGLE_API_KEY` chứ không phải `GOOGLE_API_KEY`, nên
`verify_setup.py` báo:

```
❌ GOOGLE_API_KEY not configured in .env
```

dù mở file ra thấy nội dung đúng y hệt. Đây là lỗi khó đoán vì file trông hoàn toàn bình thường.

**Cách xử lý** — ghi UTF-8 không BOM:

```powershell
$key = "khoá-Gemini-của-bạn"
[System.IO.File]::WriteAllText(
    "$PWD\.env",
    "GOOGLE_API_KEY=$key`n",
    (New-Object System.Text.UTF8Encoding($false))
)
```

Kiểm tra lại — ba byte đầu phải là `71,79,79` (`G`,`O`,`O`), không phải `239,187,191`:

```powershell
[System.IO.File]::ReadAllBytes("$PWD\.env")[0..2] -join ','
```

### 3. Xung đột phiên bản `mcp` giữa các phần

Đây là lý do phải tách ba venv.

| Phần | API dùng | Import | Phiên bản |
|---|---|---|---|
| `01`–`03` | mcp 2.x | `from mcp.server.mcpserver import MCPServer` | 2.1.1 |
| `04-lab` | mcp 1.x | `from mcp.server.fastmcp import FastMCP` | 1.28.1 |

Ở mcp 2.x, `FastMCP` đã được đổi tên thành `MCPServer` và module `mcp.server.fastmcp`
bị xoá hẳn. Cài chung một venv thì chắc chắn một trong hai phần sẽ hỏng.

Hai file `uv.lock` của `04-lab` đã ghim sẵn `mcp 1.28.1` nên `uv sync --locked` cho kết
quả đúng.

> **Đừng chạy `uv sync --upgrade` trong `04-lab`.** Nó kéo `mcp` lên 2.x và làm vỡ
> `weather.py` ngay ở dòng import.

---

## Chạy từng phần

Dùng đường dẫn tuyệt đối cho chắc, và nhớ tiền tố `.\` — PowerShell không chạy script ở
thư mục hiện tại nếu thiếu nó (lỗi `The module '.venv' could not be loaded`).

### 01 — Function Calling (cần khoá Gemini)

```powershell
Set-Location "<repo>\01-function-calling"
. ..\.venv\Scripts\Activate.ps1
$env:GEMINI_API_KEY = "khoá-của-bạn"
python weather_function_calling.py
```

### 02 — MCP Basics (không cần khoá)

```powershell
Set-Location "<repo>\02-mcp-basics"
. ..\.venv\Scripts\Activate.ps1
python weather_client.py
```

### 03 — Production (không cần khoá)

Phần Auth cần hai cửa sổ terminal vì server phải chạy nền:

```powershell
# Terminal 1
python auth_server.py      # lắng nghe http://localhost:8000/mcp

# Terminal 2
python auth_client.py
```

Nhớ `Ctrl+C` tắt server khi xong — nó chiếm cổng 8000, trùng cổng của `adk web` ở phần 04.

Hai demo còn lại chạy một lệnh, client tự khởi động server qua stdio:

```powershell
python registry_client.py
python versioned_client.py
```

### 04 — Lab (cần cả hai khoá)

```powershell
# Terminal 1 — MCP server
Set-Location "<repo>\04-lab\mcp-server"
. .\.venv\Scripts\Activate.ps1
$env:WEATHERAPI_KEY = "khoá-weatherapi"
python weather.py

# Terminal 2 — ADK agent
Set-Location "<repo>\04-lab\mcp-client"
. .\.venv\Scripts\Activate.ps1
adk web
```

Mở http://localhost:8000, chọn `weather_agent` ở ô chọn agent.

**Thứ tự quan trọng:** khởi động MCP server trước. `agent.py` kết nối ngay lúc import; nếu
server chưa chạy, nó rơi vào fallback mode — agent vẫn trả lời được nhưng **không có tool
nào**, dễ tưởng nhầm là agent hỏng.

---

## Khoá API cần chuẩn bị

| Biến | Dùng ở | Lấy tại |
|---|---|---|
| `GEMINI_API_KEY` | `01-function-calling` | https://aistudio.google.com/apikey |
| `GOOGLE_API_KEY` | `04-lab/mcp-client/.env` | cùng khoá Gemini ở trên |
| `WEATHERAPI_KEY` | `04-lab/mcp-server` | https://www.weatherapi.com (miễn phí) |

Xem `.env.example` trong từng thư mục để biết định dạng.

### Chẩn đoán khoá hỏng

Kiểm tra khoá **trước** khi chạy cả pipeline, đỡ mất công đoán:

```powershell
# WeatherAPI — mở thẳng trên trình duyệt cũng được
Invoke-RestMethod "https://api.weatherapi.com/v1/current.json?key=<KHOÁ>&q=Hanoi"
```

Ý nghĩa các mã lỗi đã gặp thật:

| Lỗi | Nghĩa | Xử lý |
|---|---|---|
| WeatherAPI `2006 API key is invalid` | Khoá chưa hiệu lực | Xác minh email tài khoản weatherapi.com; nếu nhiều khoá cùng lỗi thì vấn đề ở tài khoản chứ không ở khoá |
| Gemini `400 API_KEY_INVALID` | Khoá sai hoặc đã thu hồi | Tạo khoá mới |
| Gemini `403 API_KEY_IP_ADDRESS_BLOCKED` | Khoá bị giới hạn theo IP | Google Cloud Console → Credentials → khoá → Application restrictions → **None** |

Với lỗi giới hạn IP, nên chọn hẳn **None** thay vì thêm IP hiện tại: IP nhà thường là IP
động, thêm hôm nay thì mai đổi lại hỏng. Thay đổi cấu hình khoá mất tới 5 phút để có hiệu
lực, và trong lúc đó kết quả có thể chập chờn — lúc gọi được lúc không.

---

## Kiểm tra nhanh toàn bộ

```powershell
Set-Location "<repo>\04-lab\mcp-client"
. .\.venv\Scripts\Activate.ps1
python verify_setup.py
```

Lưu ý: script này kiểm tra một URL Cloud Run được ghi cứng từ bài gốc, **không phải server
của bạn**. Agent trong repo trỏ tới `http://localhost:8085/mcp`. Dòng đó báo xanh hay đỏ
đều không phản ánh tình trạng server bạn đang chạy.
