import json
from threading import Thread
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import pytest

from protein_forge.server import create_server


@pytest.fixture(scope="module")
def game_url():
    server = create_server(port=0)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()
    server.server_close()
    thread.join(timeout=5)


def test_health(game_url):
    with urlopen(f"{game_url}/api/health", timeout=5) as response:
        assert response.status == 200
        assert json.load(response) == {"status": "ok", "app": "protein-forge"}
        assert response.headers["Cache-Control"] == "no-store"


def test_playable_game_and_reference(game_url):
    with urlopen(f"{game_url}/api/game", timeout=5) as response:
        questions = json.load(response)["questions"]
    with urlopen(f"{game_url}/api/codons", timeout=5) as response:
        entries = json.load(response)["entries"]

    reference = {entry["codon"]: entry["code"] for entry in entries}
    assert len(reference) == 64
    assert len(questions) == 6
    assert questions[0]["codon"] == "AUG"
    assert questions[-1]["answer"] == "*"
    for question in questions:
        assert question["answer"] == reference[question["codon"]]
        assert question["answer"] in {option["code"] for option in question["options"]}


@pytest.mark.parametrize(
    ("path", "content_type", "expected"),
    [
        ("/", "text/html", b"Protein Forge"),
        ("/styles.css", "text/css", b"{"),
        ("/app.js", "text/javascript", b"/api/game"),
    ],
)
def test_public_assets(game_url, path, content_type, expected):
    with urlopen(game_url + path, timeout=5) as response:
        assert response.status == 200
        assert response.headers.get_content_type() == content_type
        assert response.headers["X-Content-Type-Options"] == "nosniff"
        assert expected in response.read()


def test_head_has_headers_without_body(game_url):
    request = Request(f"{game_url}/", method="HEAD")
    with urlopen(request, timeout=5) as response:
        assert response.status == 200
        assert int(response.headers["Content-Length"]) > 0
        assert response.read() == b""


@pytest.mark.parametrize("path", ["/missing", "/../pyproject.toml", "/%2e%2e/pyproject.toml", "/.git/config", "/src/protein_forge/server.py"])
def test_private_files_and_unknown_routes_are_not_served(game_url, path):
    with pytest.raises(HTTPError) as error:
        urlopen(game_url + path, timeout=5)
    assert error.value.code == 404
