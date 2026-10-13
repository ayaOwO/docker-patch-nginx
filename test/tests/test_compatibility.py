import json
import socket
import time
from http.client import HTTPResponse
from urllib.parse import urlsplit

import pytest
import requests


HOSTS = ("baseline", "rebuilt")
HEADERS = ("Content-Type", "Content-Length", "Location", "Allow")
BODY_LIMIT = 64 * 1024


def response_values(status, body, headers):
    return (
        status,
        body,
        {name: headers.get(name) for name in HEADERS},
    )


def request(host, method, path, body=None):
    with requests.request(
        method,
        f"http://{host}{path}",
        data=body,
        headers={"Host": "test.local"},
        timeout=5,
        allow_redirects=False,
    ) as response:
        return response_values(response.status_code, response.content, response.headers)


@pytest.fixture(scope="module", autouse=True)
def wait_for_nginx():
    deadline = time.monotonic() + 30
    for host in HOSTS:
        while time.monotonic() < deadline:
            try:
                if request(host, "GET", "/")[0] == 200:
                    break
            except requests.RequestException:
                pass
            time.sleep(0.2)
        else:
            pytest.fail(f"{host} did not become ready within the startup deadline")


def match_response(method, path, body=None, expected_status=200):
    baseline, rebuilt = [request(host, method, path, body) for host in HOSTS]
    assert baseline == rebuilt, "baseline and rebuilt responses differ"
    assert baseline[0] == expected_status
    return baseline


@pytest.mark.parametrize(
    "path",
    [pytest.param("/", id="root"), pytest.param("/test", id="custom-route")],
)
def test_get_echo(path):
    _, body, _ = match_response("GET", path)
    assert json.loads(body) == {"method": "GET", "path": path, "body": ""}


def test_redirect():
    _, _, headers = match_response("GET", "/a", expected_status=302)
    location = headers["Location"]
    assert location == "http://test.local/b"
    _, body, _ = match_response("GET", urlsplit(location).path)
    assert json.loads(body) == {"method": "GET", "path": "/b", "body": ""}


def test_post_at_body_limit():
    payload = b"x" * BODY_LIMIT
    _, body, _ = match_response("POST", "/test", payload)
    assert json.loads(body) == {
        "method": "POST", "path": "/test", "body": payload.decode("ascii")
    }


def test_post_over_body_limit():
    _, body, _ = match_response("POST", "/test", b"x" * (BODY_LIMIT + 1), 413)
    assert b"413 Request Entity Too Large" in body


def malformed_request(host):
    with socket.create_connection((host, 80), timeout=5) as connection:
        connection.sendall(
            b"GET / HTTP/INVALID\r\nHost: test.local\r\nConnection: close\r\n\r\n"
        )
        response = HTTPResponse(connection)
        try:
            response.begin()
            return response_values(response.status, response.read(), response.headers)
        finally:
            response.close()


def test_malformed_request():
    baseline, rebuilt = [malformed_request(host) for host in HOSTS]
    assert baseline == rebuilt, "baseline and rebuilt malformed responses differ"
    assert baseline[0] == 400
    assert b"400 Bad Request" in baseline[1]
