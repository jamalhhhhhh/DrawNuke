import ctypes
import http.server
import io
import json
import os
import random
import socket
import subprocess
import sys
import threading
import time

try:
    from PIL import ImageGrab
except ImportError:
    print("Pillow is required. Run:  pip install pillow")
    sys.exit(1)

user32 = ctypes.windll.user32

PORT = 8666
TOKEN = os.environ.get("REMOTETOUCH_TOKEN") or str(random.randint(100000, 999999))

APPS = {
    "calculator": lambda: subprocess.Popen("calc.exe"),
    "notepad": lambda: subprocess.Popen("notepad.exe"),
    "paint": lambda: subprocess.Popen("mspaint.exe"),
    "explorer": lambda: subprocess.Popen("explorer.exe"),
    "taskmanager": lambda: subprocess.Popen("taskmgr.exe"),
    "cmd": lambda: subprocess.Popen("cmd.exe"),
    "chrome": lambda: launch_chrome(),
    "steam": lambda: os.startfile("steam://open/games"),
}


def launch_chrome():
    for path in [
        r"C:\Program Files\Google\Chrome\Application\chrome.exe",
        r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    ]:
        if os.path.exists(path):
            subprocess.Popen([path])
            return
    subprocess.Popen(["cmd", "/c", "start", "chrome"])


VK = {"volumeup": 0xAF, "volumedown": 0xAE, "mute": 0xAD}


def press_key(vk):
    user32.keybd_event(vk, 0, 0, 0)
    user32.keybd_event(vk, 0, 2, 0)


def screen_size():
    return user32.GetSystemMetrics(0), user32.GetSystemMetrics(1)


def move_mouse(x_pct, y_pct):
    w, h = screen_size()
    user32.SetCursorPos(int(w * x_pct / 100.0), int(h * y_pct / 100.0))


def click_mouse():
    user32.mouse_event(2, 0, 0, 0, 0)
    user32.mouse_event(4, 0, 0, 0, 0)


def screenshot_jpeg():
    img = ImageGrab.grab()
    scale = min(1.0, 1000.0 / img.width)
    if scale < 1.0:
        img = img.resize((int(img.width * scale), int(img.height * scale)))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=55)
    return buf.getvalue()


def authorized(handler):
    return handler.headers.get("X-Auth-Token") == TOKEN


class Handler(http.server.BaseHTTPRequestHandler):
    def _json(self, code, obj):
        body = json.dumps(obj).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _body(self):
        length = int(self.headers.get("Content-Length") or 0)
        if length <= 0:
            return {}
        try:
            return json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception:
            return {}

    def do_GET(self):
        if self.path == "/screenshot.jpg":
            if not authorized(self):
                return self._json(401, {"error": "bad token"})
            try:
                data = screenshot_jpeg()
            except Exception as e:
                return self._json(500, {"error": str(e)})
            self.send_response(200)
            self.send_header("Content-Type", "image/jpeg")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
        elif self.path == "/status":
            if not authorized(self):
                return self._json(401, {"error": "bad token"})
            self._json(200, {"ok": True, "pc": socket.gethostname()})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self):
        if not authorized(self):
            return self._json(401, {"error": "bad token"})
        body = self._body()
        try:
            if self.path == "/tap":
                move_mouse(float(body.get("x", 0)), float(body.get("y", 0)))
                click_mouse()
                return self._json(200, {"ok": True})
            if self.path == "/move":
                move_mouse(float(body.get("x", 0)), float(body.get("y", 0)))
                return self._json(200, {"ok": True})
            if self.path == "/key":
                name = body.get("name", "")
                if name in VK:
                    press_key(VK[name])
                    return self._json(200, {"ok": True})
                return self._json(400, {"error": "unknown key"})
            if self.path == "/app":
                name = body.get("name", "")
                fn = APPS.get(name)
                if fn:
                    fn()
                    return self._json(200, {"ok": True})
                return self._json(400, {"error": "unknown app"})
            if self.path == "/command":
                cmd = body.get("cmd", "")
                if not cmd:
                    return self._json(400, {"error": "no command"})
                result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=15)
                out = (result.stdout or "") + (result.stderr or "")
                return self._json(200, {"ok": True, "out": out[:4000]})
        except subprocess.TimeoutExpired:
            return self._json(200, {"ok": True, "out": "(command timed out after 15s)"})
        except Exception as e:
            return self._json(500, {"error": str(e)})
        self._json(404, {"error": "not found"})

    def log_message(self, fmt, *args):
        pass


def broadcaster():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    msg = json.dumps({"app": "RemoteTouch", "name": socket.gethostname(), "port": PORT}).encode()
    while True:
        try:
            s.sendto(msg, ("255.255.255.255", 8667))
        except Exception:
            pass
        time.sleep(2)


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def main():
    server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    threading.Thread(target=broadcaster, daemon=True).start()
    ip = lan_ip()
    print("=" * 52)
    print("  REMOTE TOUCH - PC server running")
    print(f"  Your PC IP:  {ip}")
    print(f"  Port:        {PORT}")
    print(f"  PIN:         {TOKEN}")
    print("  Enter that IP + PIN in the RemoteTouch iPhone app.")
    print("  Keep this window open. Ctrl+C to stop.")
    print("=" * 52)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
