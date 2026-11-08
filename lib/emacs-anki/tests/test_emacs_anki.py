#!/usr/bin/env python3
"""Integration tests for the AnkiConnect bridge.

The tests run the real CLI as a subprocess against a tiny in-process fake
AnkiConnect server.  They do not need Anki, Emacs, or any third-party Python
packages.
"""

from __future__ import annotations

import json
import os
import socket
import subprocess
import sys
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

import emacs_anki  # noqa: E402


def make_card(
    card_id: int,
    deck: str = "work::everything",
    question: str = "Question",
    answer: str = "Answer",
) -> Dict[str, Any]:
    return {
        "cardId": card_id,
        "deckName": deck,
        "modelName": "Basic",
        "template": "Card 1",
        "question": f"<div class=\"card\">{question}</div>",
        "answer": f"<div class=\"card\">{answer}</div>",
        "buttons": [1, 2, 3, 4],
        "nextReviews": ["<1m", "6m", "10m", "4d"],
        "fields": {},
    }


class FakeAnkiState:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.decks = ["work", "work::everything", "work::everything::sub"]
        self.queue: List[Dict[str, Any]] = []
        self.current: Optional[Dict[str, Any]] = None
        self.shown = False
        self.calls: List[str] = []
        self.answered: List[Tuple[int, int]] = []
        self.autoplay = True
        self.autoplay_during_show: Optional[bool] = None
        self.autoplay_during_answer: Optional[bool] = None
        self.autoplay_during_review: Optional[bool] = None
        self.autoplay_during_show_question: Optional[bool] = None
        self.config_saves = 0

    def reset(self, cards: List[Dict[str, Any]]) -> None:
        with self.lock:
            self.queue = list(cards)
            self.current = None
            self.shown = False
            self.calls = []
            self.answered = []
            self.autoplay = True
            self.autoplay_during_show = None
            self.autoplay_during_answer = None
            self.autoplay_during_review = None
            self.autoplay_during_show_question = None
            self.config_saves = 0

    def dispatch(self, action: str, params: Dict[str, Any]) -> Any:
        with self.lock:
            self.calls.append(action)
            if action == "version":
                return 6
            if action == "deckNames":
                return list(self.decks)
            if action == "guiCurrentCard":
                if self.current is None:
                    # Match older AnkiConnect releases, which raise instead of
                    # returning null when no review is active.
                    raise RuntimeError("Gui review is not currently active.")
                return dict(self.current)
            if action == "guiDeckReview":
                # A real review navigates to the requested deck.  The queue
                # below is already restricted to the deck under test.
                self.autoplay_during_review = self.autoplay
                self.shown = False
                self.current = dict(self.queue[0]) if self.queue else None
                return True
            if action == "guiShowQuestion":
                self.autoplay_during_show_question = self.autoplay
                self.shown = False
                return True
            if action == "guiStartCardTimer":
                return True
            if action == "getDeckConfig":
                return {
                    "id": 1,
                    "name": "Default",
                    "autoplay": self.autoplay,
                    "mod": 123,
                    "usn": -1,
                }
            if action == "saveDeckConfig":
                config = params.get("config") or {}
                if "autoplay" in config:
                    self.autoplay = bool(config["autoplay"])
                self.config_saves += 1
                return True
            if action == "guiShowAnswer":
                if self.current is None:
                    return False
                self.autoplay_during_show = self.autoplay
                self.shown = True
                return True
            if action == "guiAnswerCard":
                if self.current is None or not self.shown:
                    return False
                self.autoplay_during_answer = self.autoplay
                ease = int(params.get("ease", 0))
                card_id = int(self.current["cardId"])
                self.answered.append((card_id, ease))
                self.shown = False
                if self.queue and int(self.queue[0]["cardId"]) == card_id:
                    self.queue.pop(0)
                self.current = dict(self.queue[0]) if self.queue else None
                return True
            raise ValueError(f"Fake AnkiConnect does not handle {action!r}")


class FakeAnkiHandler(BaseHTTPRequestHandler):
    state: FakeAnkiState

    def log_message(self, fmt: str, *args: Any) -> None:
        pass

    def do_POST(self) -> None:  # noqa: N802 - BaseHTTPRequestHandler API
        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)
        try:
            payload = json.loads(body.decode("utf-8"))
            action = payload["action"]
            params = payload.get("params") or {}
            result = self.state.dispatch(action, params)
            response = {"result": result, "error": None}
            status = 200
        except Exception as exc:  # pragma: no cover - only test plumbing errors
            response = {"result": None, "error": str(exc)}
            status = 200

        raw = json.dumps(response).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)


class BridgeIntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.state = FakeAnkiState()
        handler = type("BoundFakeAnkiHandler", (FakeAnkiHandler,), {"state": cls.state})
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls) -> None:
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=5)

    def setUp(self) -> None:
        self.state.reset([])

    def run_cli(
        self,
        *args: str,
        url: Optional[str] = None,
        timeout: float = 10,
        extra_env: Optional[Dict[str, str]] = None,
    ) -> Tuple[subprocess.CompletedProcess[str], Dict[str, Any]]:
        cmd = [
            sys.executable,
            str(ROOT / "emacs_anki.py"),
            "--url",
            url or self.url,
            "--deck",
            "work::everything",
            "--timeout",
            "1",
            *args,
        ]
        env = dict(os.environ)
        env["EMACS_ANKI_KEY"] = ""
        if extra_env:
            env.update(extra_env)
        proc = subprocess.run(
            cmd,
            text=True,
            capture_output=True,
            timeout=timeout,
            env=env,
        )
        self.assertTrue(proc.stdout.strip(), f"no stdout; stderr={proc.stderr!r}")
        return proc, json.loads(proc.stdout)

    def test_review_flow_again_and_good(self) -> None:
        self.state.queue = [
            make_card(11, question="Q one", answer="A one"),
            make_card(12, question="Q two", answer="A two"),
        ]

        proc, data = self.run_cli("card")
        self.assertEqual(proc.returncode, 0, data)
        self.assertTrue(data["ok"])
        self.assertEqual(data["card"]["id"], 11)
        self.assertEqual(data["card"]["question"], "Q one")
        self.assertEqual(data["card"]["buttons"][0]["ease"], 1)
        self.assertEqual(data["card"]["buttons"][0]["next"], "<1m")
        self.assertIn("guiDeckReview", self.state.calls)

        proc, data = self.run_cli("show", "--card-id", "11")
        self.assertEqual(proc.returncode, 0, data)
        self.assertTrue(data["shown"])
        self.assertTrue(self.state.shown)

        proc, data = self.run_cli("answer", "3", "--card-id", "11")
        self.assertEqual(proc.returncode, 0, data)
        self.assertEqual(data["answered"], 11)
        self.assertEqual(data["card"]["id"], 12)
        self.assertEqual(self.state.answered, [(11, 3)])

        proc, data = self.run_cli("answer", "1", "--card-id", "12")
        self.assertEqual(proc.returncode, 0, data)
        self.assertIsNone(data["card"])
        self.assertEqual(self.state.answered, [(11, 3), (12, 1)])

    def test_subdeck_card_is_reused_without_renavigating(self) -> None:
        subdeck_card = make_card(
            21, deck="work::everything::sub", question="Subdeck question"
        )
        self.state.current = subdeck_card

        proc, data = self.run_cli("card")
        self.assertEqual(proc.returncode, 0, data)
        self.assertEqual(data["card"]["id"], 21)
        self.assertEqual(data["card"]["deck"], "work::everything::sub")
        self.assertNotIn("guiDeckReview", self.state.calls)

    def test_mute_covers_entering_review_and_showing_question(self) -> None:
        self.state.queue = [make_card(31)]

        proc, data = self.run_cli("--mute", "card")
        self.assertEqual(proc.returncode, 0, data)
        self.assertIs(self.state.autoplay_during_review, False)
        self.assertIs(self.state.autoplay_during_show_question, False)
        self.assertTrue(self.state.autoplay)
        self.assertEqual(self.state.config_saves, 2)

    def test_mute_disables_autoplay_for_show_and_restores_it(self) -> None:
        self.state.current = make_card(41)

        proc, data = self.run_cli("--mute", "show", "--card-id", "41")
        self.assertEqual(proc.returncode, 0, data)
        self.assertIs(self.state.autoplay_during_show, False)
        self.assertTrue(self.state.autoplay)
        self.assertEqual(self.state.config_saves, 2)

    def test_mute_disables_autoplay_for_answer_and_restores_it(self) -> None:
        self.state.current = make_card(51)
        self.state.queue = [make_card(51), make_card(52)]

        proc, data = self.run_cli("--mute", "answer", "3", "--card-id", "51")
        self.assertEqual(proc.returncode, 0, data)
        self.assertIs(self.state.autoplay_during_show, False)
        self.assertIs(self.state.autoplay_during_answer, False)
        self.assertTrue(self.state.autoplay)
        self.assertEqual(self.state.answered, [(51, 3)])
        self.assertEqual(data["card"]["id"], 52)

    def test_without_mute_autoplay_is_unchanged(self) -> None:
        self.state.current = make_card(61)

        proc, data = self.run_cli("show", "--card-id", "61")
        self.assertEqual(proc.returncode, 0, data)
        self.assertIs(self.state.autoplay_during_show, True)
        self.assertTrue(self.state.autoplay)
        self.assertEqual(self.state.config_saves, 0)

    def test_stale_card_is_rejected_before_showing(self) -> None:
        self.state.current = make_card(31)

        proc, data = self.run_cli("show", "--card-id", "999")
        self.assertEqual(proc.returncode, 1)
        self.assertFalse(data["ok"])
        self.assertTrue(data["stale"])
        self.assertEqual(data["current_card_id"], 31)
        self.assertNotIn("guiShowAnswer", self.state.calls)

    def test_empty_queue(self) -> None:
        proc, data = self.run_cli("card")
        self.assertEqual(proc.returncode, 0, data)
        self.assertTrue(data["ok"])
        self.assertIsNone(data["card"])
        self.assertIn("No cards", data["message"])

    def test_missing_deck_is_reported(self) -> None:
        proc, data = self.run_cli("--deck", "missing", "card")
        self.assertEqual(proc.returncode, 1)
        self.assertFalse(data["ok"])
        self.assertIn("not found", data["error"])

    def test_check_command(self) -> None:
        proc, data = self.run_cli("check")
        self.assertEqual(proc.returncode, 0, data)
        self.assertTrue(data["ok"])
        self.assertTrue(data["deck_exists"])
        self.assertEqual(data["anki_connect_version"], 6)
        self.assertIn("work::everything::sub", data["matching_decks"])

    def test_decks_command(self) -> None:
        proc, data = self.run_cli("decks")
        self.assertEqual(proc.returncode, 0, data)
        self.assertTrue(data["ok"])
        self.assertEqual(
            data["decks"],
            ["work", "work::everything", "work::everything::sub"],
        )

    def test_unreachable_ankiconnect(self) -> None:
        sock = socket.socket()
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
        sock.close()

        proc, data = self.run_cli(
            "card", url=f"http://127.0.0.1:{port}", timeout=5
        )
        self.assertEqual(proc.returncode, 1)
        self.assertFalse(data["ok"])
        self.assertIn("AnkiConnect", data["error"])


class HtmlTests(unittest.TestCase):
    def test_basic_html(self) -> None:
        self.assertEqual(
            emacs_anki.html_to_text("<div>A &amp; B<br>C</div>"),
            "A & B\nC",
        )

    def test_lists(self) -> None:
        self.assertEqual(
            emacs_anki.html_to_text("<ul><li>one</li><li>two</li></ul>"),
            "• one\n• two",
        )

    def test_script_and_style_are_dropped(self) -> None:
        self.assertEqual(
            emacs_anki.html_to_text(
                "<style>.x { color: red }</style><script>x()</script><p>ok</p>"
            ),
            "ok",
        )

    def test_preformatted_text_keeps_indentation(self) -> None:
        self.assertEqual(
            emacs_anki.html_to_text("<pre>line one\n    line two</pre>"),
            "line one\n    line two",
        )

    def test_empty(self) -> None:
        self.assertEqual(emacs_anki.html_to_text(None), "")
        self.assertEqual(emacs_anki.html_to_text(""), "")


if __name__ == "__main__":
    unittest.main()
