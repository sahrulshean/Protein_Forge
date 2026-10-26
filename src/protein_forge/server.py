"""Local HTTP server for the Protein Forge learning game."""

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from importlib.resources import files
from urllib.parse import urlsplit

from protein_forge.game import codon_entries, make_game

STATIC_ROUTES = {
    "/": ("index.html", "text/html; charset=utf-8"),
    "/styles.css": ("styles.css", "text/css; charset=utf-8"),
    "/app.js": ("app.js", "text/javascript; charset=utf-8"),
}


class GameHandler(BaseHTTPRequestHandler):
    """Serve only the game's public assets and read-only JSON endpoints."""

    def do_GET(self) -> None:
        self._respond(send_body=True)

    def do_HEAD(self) -> None:
        self._respond(send_body=False)

    def _respond(self, *, send_body: bool) -> None:
        path = urlsplit(self.path).path
        status = 200
        content_type = "application/json; charset=utf-8"
        if path == "/api/health":
            payload = {"status": "ok", "app": "protein-forge"}
        elif path == "/api/game":
            payload = make_game()
        elif path == "/api/codons":
            payload = {"entries": codon_entries()}
        elif path in STATIC_ROUTES:
            filename, content_type = STATIC_ROUTES[path]
            body = files("protein_forge").joinpath("web", filename).read_bytes()
            payload = None
        elif path == "/favicon.ico":
            status, body, payload = 204, b"", None
        else:
            status, payload = 404, {"error": "Halaman tidak ditemukan."}

        if payload is not None:
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store" if path.startswith("/api/") else "no-cache")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        if send_body:
            self.wfile.write(body)


def create_server(host: str = "127.0.0.1", port: int = 8000) -> ThreadingHTTPServer:
    return ThreadingHTTPServer((host, port), GameHandler)


def main() -> int:
    parser = argparse.ArgumentParser(description="Jalankan game edukasi Protein Forge.")
    parser.add_argument("--host", default="127.0.0.1", help="Alamat bind server.")
    parser.add_argument("--port", type=int, default=8000, help="Port server (default: 8000).")
    args = parser.parse_args()
    if not 0 <= args.port <= 65535:
        parser.error("Port harus berada di antara 0 dan 65535.")

    with create_server(args.host, args.port) as server:
        print(f"Protein Forge berjalan pada {args.host}:{server.server_port}", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
