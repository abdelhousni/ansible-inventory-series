#!/usr/bin/env python3
"""A fake CMDB for the example: one JSON endpoint behind a bearer token.

GET /api/servers answers with the file given as first argument, if the request
carries "Authorization: Bearer test-only-token", and 401 otherwise.
GET /html answers with an HTML page, as a login portal or a proxy would.
Every request is logged, one line each, to the file given as second argument.
"""
import http.server
import sys

TOKEN = "test-only-token"  # a test value, committed on purpose
DATA, LOG, PORT = sys.argv[1], sys.argv[2], int(sys.argv[3])


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        authorized = self.headers.get("Authorization") == f"Bearer {TOKEN}"
        with open(LOG, "a", encoding="utf-8") as log:
            log.write(f"GET {self.path} token={'ok' if authorized else 'missing or wrong'}\n")
        if self.path == "/html":
            self.reply(200, "text/html", b"<html><body>Please log in</body></html>")
        elif self.path != "/api/servers":
            self.reply(404, "application/json", b'{"error": "not found"}')
        elif not authorized:
            self.reply(401, "application/json", b'{"error": "a bearer token is required"}')
        else:
            with open(DATA, "rb") as data:
                self.reply(200, "application/json", data.read())

    def reply(self, status, content_type, body):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):  # keep stderr quiet; the log file is enough
        pass


http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
