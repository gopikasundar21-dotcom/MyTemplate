"""Fixtures for Playwright UI tests.

UI tests need a real, running server. We spin up the Flask app in a background
thread (Werkzeug's threaded WSGI server) backed by a freshly-seeded SQLite DB,
then hand Playwright the live base URL. This keeps the UI suite self-contained
and cross-platform (no external server or `flask run` subprocess required).
"""
import os
import socket
import threading
import time

import pytest

# ProdConfig reads DATABASE_URL at import time; give it a harmless default.
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")

from werkzeug.serving import make_server

from appname import create_app
from appname.models import db
from appname.models.user import User

# Seeded credentials used by the UI tests.
UI_USER_EMAIL = "user@example.com"
UI_USER_PASSWORD = "uitestpassword"


def _free_port():
    """Grab an available localhost port so parallel runs don't collide."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class _ServerThread(threading.Thread):
    def __init__(self, app, host, port):
        super().__init__(daemon=True)
        self._srv = make_server(host, port, app, threaded=True)
        self._ctx = app.app_context()
        self._ctx.push()

    def run(self):
        self._srv.serve_forever()

    def shutdown(self):
        self._srv.shutdown()


@pytest.fixture(scope="session")
def live_server():
    """Start the app on a free port with a seeded user; yield the base URL."""
    app = create_app("appname.settings.TestConfig")
    # A real browser posts forms; the app must accept them, so disable CSRF here
    # (already off in TestConfig) and make sessions work over plain HTTP.
    app.config["SESSION_COOKIE_SECURE"] = False

    with app.app_context():
        db.create_all()
        if User.lookup(UI_USER_EMAIL) is None:
            db.session.add(User(UI_USER_EMAIL, UI_USER_PASSWORD))
            db.session.commit()

    host, port = "127.0.0.1", _free_port()
    server = _ServerThread(app, host, port)
    server.start()

    base_url = f"http://{host}:{port}"
    _wait_until_up(base_url)

    yield base_url

    server.shutdown()


def _wait_until_up(base_url, timeout=15):
    """Poll the server until it answers or we give up."""
    import urllib.error
    import urllib.request

    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            urllib.request.urlopen(base_url, timeout=1)
            return
        except urllib.error.HTTPError:
            # Any HTTP response means the server is accepting connections.
            return
        except (urllib.error.URLError, ConnectionError, OSError):
            time.sleep(0.25)
    raise RuntimeError(f"Live server at {base_url} did not start in time")
