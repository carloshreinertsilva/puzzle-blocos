"""Serves the test build with the same isolation headers as Vercel
(vercel.json), so the browser runs the WebAssembly renderer the same way."""

import functools
import http.server
import sys

port, directory = int(sys.argv[1]), sys.argv[2]


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".mjs": "text/javascript",
    }

    def do_GET(self):
        # Like vercel.json: /duelo is the game page (challenge links).
        if self.path == "/duelo" or self.path.startswith("/duelo?"):
            self.path = "/index.html"
        super().do_GET()

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, *args):
        pass


http.server.ThreadingHTTPServer(
    ("127.0.0.1", port), functools.partial(Handler, directory=directory)
).serve_forever()
