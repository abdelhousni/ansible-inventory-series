"""A fake Foreman API for the example: serves recorded responses, logs requests.

Usage: python3 mock/foreman.py PORT LOG

GET /a/b answers with mock/a/b.json, POST answers with mock/a/b.post.json.
Each request is appended to LOG as "METHOD /path?query". A URL under /plain/
is a Foreman without the foreman_ansible plugin: the same API, minus /ansible/.
Facts are paginated: the plugin asks for pages until one is empty, so any
page after the first gets an empty "results".
"""
import json
import pathlib
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit

ROOT = pathlib.Path(__file__).resolve().parent
LOG = pathlib.Path(sys.argv[2])


class Handler(BaseHTTPRequestHandler):
    def answer(self, suffix):
        url = urlsplit(self.path)
        path = "/" + "/".join(part for part in url.path.split("/") if part)
        with LOG.open("a") as log:
            log.write(f"{self.command} {path}{'?' + url.query if url.query else ''}\n")
        if path.startswith("/plain/"):
            path = path[len("/plain"):]
            if path.startswith("/ansible/"):
                return self.send(404, {"error": {"message": "Route not found"}})
        file = ROOT / (path.lstrip("/") + suffix)
        if not file.is_file():
            return self.send(404, {"error": {"message": "Resource not found"}})
        body = json.loads(file.read_text())
        page = int(parse_qs(url.query).get("page", ["1"])[0])
        if page > 1 and isinstance(body.get("results"), dict):
            body["results"] = {}
        return self.send(200, body)

    def send(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):  # noqa: N802 (http.server's naming)
        self.answer(".json")

    def do_POST(self):  # noqa: N802
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        self.answer(".post.json")

    def log_message(self, *args):
        pass


HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
