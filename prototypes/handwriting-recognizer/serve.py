"""PROTOTYPE, throwaway. Serves this folder and saves an uploaded test set.

python3 -I -B prototypes/handwriting-recognizer/serve.py <bind-address> [port]
POST /upload writes the JSON body to handwriting-testset.json next to this file. It refuses a set
smaller than the one already saved, so a partial re-send can't replace a full one.
Binds only to a Tailscale (100.64.0.0/10) or loopback address.
"""

import functools
import http.server
import ipaddress
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "handwriting-testset.json"
MAX_BYTES = 20 * 1024 * 1024


class Handler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/upload":
            self.send_error(404)
            return
        if self.headers.get_content_type() != "application/json":
            self.send_error(415)
            return
        host = self.headers.get("Host", "")
        if self.headers.get("Origin") not in (None, f"http://{host}"):
            self.send_error(403, "cross-origin upload")
            return
        try:
            length = int(self.headers.get("Content-Length", 0))
        except ValueError:
            self.send_error(400, "bad Content-Length")
            return
        if not 0 < length <= MAX_BYTES:
            self.send_error(413)
            return
        try:
            data = json.loads(self.rfile.read(length))
            samples = data["samples"]
            if not isinstance(samples, list) or not all(
                isinstance(x, dict) and isinstance(x.get("target"), str) and isinstance(x.get("strokes"), list)
                for x in samples
            ):
                raise TypeError
            count = len(samples)
        except (ValueError, KeyError, TypeError):
            self.send_error(400, "not a test set")
            return
        if OUT.exists() and count < len(json.loads(OUT.read_text())["samples"]):
            self.send_error(409, "smaller than the saved test set")
            return
        OUT.write_text(json.dumps(data, ensure_ascii=False))
        body = json.dumps({"saved": count}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print(f"saved {count} samples to {OUT}", flush=True)


if __name__ == "__main__":
    bind = sys.argv[1]
    address = ipaddress.ip_address(bind)
    if not (address.is_loopback or address in ipaddress.ip_network("100.64.0.0/10")):
        sys.exit(f"refusing to bind {bind}: use a Tailscale or loopback address")
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8000
    handler = functools.partial(Handler, directory=str(HERE))
    print(f"serving {HERE} on http://{bind}:{port}", flush=True)
    http.server.ThreadingHTTPServer((bind, port), handler).serve_forever()
