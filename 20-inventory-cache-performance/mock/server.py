#!/usr/bin/env python3
"""A fake Proxmox VE API for the examples: answers the calls the inventory plugin makes.

Serves the recorded responses in api.json, keyed by path under /api2/json, and
logs each request as "METHOD path" to the file given as second argument.

    mock/server.py PORT LOG [API_JSON [LATENCY_MS]]

POST /access/ticket returns a ticket for any user and password. Every other
request needs that ticket as a cookie, or an API token header, as the real API
does; without one it gets 401. A path absent from api.json gets 404, and a
path whose value is {"_status": N} gets that status code.

Every response waits LATENCY_MS milliseconds first (0 by default), as a
remote API would, and a path whose value is {"_delay": S, "_data": BODY}
waits S more seconds before it answers BODY.
"""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PREFIX = "/api2/json"
TICKET = "PVE:mock@pve:00000000::mock-ticket"


class Handler(BaseHTTPRequestHandler):
    api = {}
    log = None
    latency = 0.0

    def _reply(self, status, body):
        payload = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _record(self):
        time.sleep(self.latency)
        with open(self.log, "a", encoding="utf-8") as log:
            log.write(f"{self.command} {self.path.removeprefix(PREFIX)}\n")

    def do_POST(self):  # noqa: N802 (http.server naming)
        self._record()
        length = int(self.headers.get("Content-Length", 0))
        self.rfile.read(length)
        if self.path == f"{PREFIX}/access/ticket":
            self._reply(200, {"data": {"ticket": TICKET, "CSRFPreventionToken": "mock"}})
        else:
            self._reply(404, {"data": None})

    def do_GET(self):  # noqa: N802
        self._record()
        authed = TICKET in self.headers.get("Cookie", "") or self.headers.get(
            "Authorization", ""
        ).startswith("PVEAPIToken=")
        if not authed:
            self._reply(401, {"data": None})
            return
        path = self.path.removeprefix(PREFIX)
        if path not in self.api:
            self._reply(404, {"data": None})
            return
        body = self.api[path]
        if isinstance(body, dict) and "_delay" in body:
            time.sleep(body["_delay"])
            body = body["_data"]
        if isinstance(body, dict) and "_status" in body:
            self._reply(body["_status"], {"data": None})
            return
        self._reply(200, {"data": body})

    def log_message(self, *args):
        pass  # the request log above is enough


def main():
    port, log = int(sys.argv[1]), sys.argv[2]
    api_file = Path(sys.argv[3]) if len(sys.argv) > 3 else Path(__file__).with_name("api.json")
    Handler.api = json.loads(api_file.read_text(encoding="utf-8"))
    Handler.log = log
    Handler.latency = int(sys.argv[4]) / 1000 if len(sys.argv) > 4 else 0.0
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()


if __name__ == "__main__":
    main()
