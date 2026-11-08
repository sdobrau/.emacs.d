#!/usr/bin/env python3
"""Small AnkiConnect bridge used by the Emacs package in this repository.

The GUI actions exposed by AnkiConnect are intentional: they make Anki render
the question and answer with the card's real template and let Anki's scheduler
record the review exactly as if the buttons had been clicked in Anki itself.

Run ``python3 emacs_anki.py --help`` for the command reference.
"""

from __future__ import annotations

import argparse
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from contextlib import contextmanager
from html.parser import HTMLParser
from typing import Any, Dict, Iterator, List, Mapping, Optional, Sequence


DEFAULT_URL = "http://127.0.0.1:8765"
DEFAULT_DECK = "work::everything"
API_VERSION = 6
EASE_NAMES = {1: "Again", 2: "Hard", 3: "Good", 4: "Easy"}


class BridgeError(RuntimeError):
    """An error that should be shown to the Emacs caller."""


class StaleCardError(BridgeError):
    """The card changed in Anki while Emacs was displaying it."""

    def __init__(self, message: str, current_card_id: Optional[int] = None) -> None:
        super().__init__(message)
        self.current_card_id = current_card_id


# ---------------------------------------------------------------------------
# AnkiConnect client


class AnkiConnect:
    def __init__(self, url: str, api_key: Optional[str], timeout: float) -> None:
        self.url = url.rstrip("/") or DEFAULT_URL
        self.api_key = api_key or None
        self.timeout = max(0.1, float(timeout))

    def invoke(self, action: str, **params: Any) -> Any:
        payload: Dict[str, Any] = {
            "action": action,
            "version": API_VERSION,
            "params": params,
        }
        if self.api_key:
            payload["key"] = self.api_key

        request = urllib.request.Request(
            self.url,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json; charset=utf-8"},
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                raw = response.read()
        except urllib.error.HTTPError as exc:
            detail = ""
            try:
                detail = exc.read().decode("utf-8", "replace").strip()
            except Exception:
                pass
            message = f"AnkiConnect returned HTTP {exc.code}"
            if detail:
                message += f": {detail[:500]}"
            raise BridgeError(message) from exc
        except urllib.error.URLError as exc:
            reason = getattr(exc, "reason", exc)
            raise BridgeError(
                "Cannot reach AnkiConnect at "
                f"{self.url}: {reason}. Is Anki running, and is the "
                "AnkiConnect add-on installed and enabled?"
            ) from exc
        except TimeoutError as exc:
            raise BridgeError(
                f"AnkiConnect at {self.url} timed out after {self.timeout:g}s."
            ) from exc
        except OSError as exc:
            raise BridgeError(f"Cannot talk to AnkiConnect at {self.url}: {exc}") from exc

        try:
            data = json.loads(raw.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise BridgeError(
                f"AnkiConnect returned invalid JSON: {raw[:300]!r}"
            ) from exc

        if not isinstance(data, dict):
            raise BridgeError("AnkiConnect returned an unexpected response.")

        error = data.get("error")
        if error:
            raise BridgeError(str(error))
        if "result" not in data:
            raise BridgeError("AnkiConnect response did not contain a result.")
        return data["result"]


# ---------------------------------------------------------------------------
# HTML to readable text


class _HTMLTextExtractor(HTMLParser):
    """Turn Anki's rendered HTML into text suitable for an Emacs buffer.

    It deliberately does not try to reproduce CSS or images.  The goal is a
    readable card in a child frame, not a web browser.
    """

    block_tags = {
        "address",
        "article",
        "aside",
        "blockquote",
        "dd",
        "div",
        "dl",
        "dt",
        "fieldset",
        "figcaption",
        "figure",
        "footer",
        "form",
        "h1",
        "h2",
        "h3",
        "h4",
        "h5",
        "h6",
        "header",
        "hr",
        "li",
        "main",
        "nav",
        "ol",
        "p",
        "pre",
        "section",
        "table",
        "tbody",
        "td",
        "tfoot",
        "th",
        "thead",
        "tr",
        "ul",
    }
    skip_tags = {"script", "style", "noscript", "template"}

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.parts: List[str] = []
        self.skip_depth = 0
        self._in_pre = 0
        self._last_was_newline = True

    def _newline(self, count: int = 1) -> None:
        if not self.parts:
            return
        text = "".join(self.parts)
        existing = len(text) - len(text.rstrip("\n"))
        if existing < count:
            self.parts.append("\n" * (count - existing))
            self._last_was_newline = True

    def handle_starttag(self, tag: str, attrs: Sequence[tuple[str, Optional[str]]]) -> None:
        tag = tag.lower()
        if tag in self.skip_tags:
            self.skip_depth += 1
            return
        if self.skip_depth:
            return

        if tag == "br":
            self.parts.append("\n")
            self._last_was_newline = True
        elif tag == "li":
            self._newline(1)
            self.parts.append("• ")
            self._last_was_newline = False
        elif tag in {"td", "th"}:
            if not self._last_was_newline:
                self.parts.append("  ")
        elif tag in self.block_tags:
            if tag == "pre":
                self._in_pre += 1
            self._newline(2 if tag in {"p", "div", "tr", "table", "h1", "h2", "h3",
                                       "h4", "h5", "h6", "blockquote", "pre"} else 1)
        elif tag == "img":
            alt = ""
            for key, value in attrs:
                if key.lower() == "alt" and value:
                    alt = value
                    break
            self.parts.append(f"[image: {alt}]" if alt else "[image]")
            self._last_was_newline = False

    def handle_startendtag(self, tag: str, attrs: Sequence[tuple[str, Optional[str]]]) -> None:
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag in self.skip_tags:
            self.skip_depth = max(0, self.skip_depth - 1)
            return
        if self.skip_depth:
            return

        if tag == "pre":
            self._in_pre = max(0, self._in_pre - 1)
        if tag in self.block_tags:
            self._newline(2 if tag in {"p", "div", "tr", "table", "h1", "h2", "h3",
                                       "h4", "h5", "h6", "blockquote", "pre"} else 1)

    def handle_data(self, data: str) -> None:
        if self.skip_depth or not data:
            return
        if self._in_pre:
            # Protect preformatted indentation from the whitespace pass in
            # text().  The non-breaking spaces are converted back at the end.
            data = data.replace("\t", "\xa0\xa0\xa0\xa0").replace(" ", "\xa0")
        else:
            data = re.sub(r"[ \t\r\n\f\v]+", " ", data)
        if not data:
            return
        if self._last_was_newline:
            data = data.lstrip(" ")
        if data:
            self.parts.append(data)
            self._last_was_newline = data.endswith("\n")

    def text(self) -> str:
        text = "".join(self.parts)
        text = re.sub(r"[ \t\f\v]+", " ", text)
        text = re.sub(r" *\n *", "\n", text)
        text = re.sub(r"\n{3,}", "\n\n", text)
        text = text.replace("\xa0", " ")
        return text.strip()


def html_to_text(value: Optional[str]) -> str:
    """Return a readable plain-text rendering of an HTML fragment."""
    if not value:
        return ""
    parser = _HTMLTextExtractor()
    try:
        parser.feed(value)
        parser.close()
        result = parser.text()
    except Exception:
        # A malformed card should not make the whole bridge fail.
        result = html.unescape(re.sub(r"<[^>]*>", " ", value))
        result = re.sub(r"\s+", " ", result).strip()
    return result


# ---------------------------------------------------------------------------
# Card and queue helpers


def _card_id(raw: Mapping[str, Any]) -> Optional[int]:
    value = raw.get("cardId")
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def normalize_card(raw: Mapping[str, Any]) -> Dict[str, Any]:
    """Normalize the legacy guiCurrentCard result for the Emacs side."""
    card_id = _card_id(raw)
    if card_id is None:
        raise BridgeError("AnkiConnect returned a card without a usable card ID.")

    raw_buttons = raw.get("buttons")
    if not isinstance(raw_buttons, list) or not raw_buttons:
        raw_buttons = [1, 2, 3, 4]
    raw_next = raw.get("nextReviews")
    if not isinstance(raw_next, list):
        raw_next = []

    buttons: List[Dict[str, Any]] = []
    for index, ease in enumerate(raw_buttons):
        try:
            ease_int = int(ease)
        except (TypeError, ValueError):
            continue
        buttons.append(
            {
                "ease": ease_int,
                "name": EASE_NAMES.get(ease_int, str(ease_int)),
                "next": raw_next[index] if index < len(raw_next) else "",
            }
        )

    question_html = raw.get("question") or ""
    answer_html = raw.get("answer") or ""
    return {
        "id": card_id,
        "deck": raw.get("deckName") or "",
        "model": raw.get("modelName") or "",
        "template": raw.get("template") or "",
        "question": html_to_text(question_html),
        "answer": html_to_text(answer_html),
        "question_html": question_html,
        "answer_html": answer_html,
        "buttons": buttons,
    }


def deck_tree(deck: str, names: Sequence[str]) -> set[str]:
    """Return the selected deck and its descendants."""
    prefix = deck + "::"
    return {name for name in names if name == deck or name.startswith(prefix)}


def ensure_deck(conn: AnkiConnect, deck: str) -> set[str]:
    names = conn.invoke("deckNames")
    if not isinstance(names, list):
        raise BridgeError("AnkiConnect returned an unexpected deck list.")
    names = [str(name) for name in names]
    if deck not in names:
        raise BridgeError(
            f'Deck "{deck}" was not found in Anki. '
            "Check the deck name in Anki's deck list."
        )
    return deck_tree(deck, names)


def current_card(conn: AnkiConnect) -> Optional[Mapping[str, Any]]:
    """Return Anki's current review card, or nil if no review is active.

    AnkiConnect versions differ here: some return null from ``guiCurrentCard``
    when no review is active, while older ones raise
    "Gui review is not currently active." for the same condition.  Treat both
    as "no current card" so `ensure_review' can enter the deck.
    """
    try:
        raw = conn.invoke("guiCurrentCard")
    except BridgeError as exc:
        if "gui review is not currently active" in str(exc).lower():
            return None
        raise
    return raw if isinstance(raw, dict) else None


def _wait_for_card(conn: AnkiConnect, attempts: int = 12) -> Optional[Mapping[str, Any]]:
    for index in range(attempts):
        raw = current_card(conn)
        if raw is not None:
            return raw
        if index + 1 < attempts:
            time.sleep(0.05)
    return None


def ensure_review(conn: AnkiConnect, deck: str) -> Optional[Mapping[str, Any]]:
    """Return the current card, entering the selected deck if necessary.

    If Anki is already reviewing a card in the selected deck (or one of its
    subdecks), that card is reused.  This matters for parent decks: navigating
    to the parent again for every card would restart the review queue.
    """
    allowed_decks = ensure_deck(conn, deck)

    raw = current_card(conn)
    if raw is not None and raw.get("deckName") in allowed_decks:
        return raw

    started = conn.invoke("guiDeckReview", name=deck)
    if not started:
        raise BridgeError(
            f'Anki refused to start a review for deck "{deck}". '
            "It may be a filtered deck that cannot be reviewed, or Anki may "
            "be showing a modal dialog."
        )

    raw = _wait_for_card(conn)
    if raw is None:
        return None
    if raw.get("deckName") not in allowed_decks:
        raise BridgeError(
            "Anki started a review, but its current card is not in deck "
            f'"{deck}" (it is in "{raw.get("deckName")}").'
        )
    return raw


def require_current_card(conn: AnkiConnect, card_id: Optional[int]) -> Mapping[str, Any]:
    raw = current_card(conn)
    if raw is None:
        raise BridgeError(
            "Anki is not in review mode. Press g in the popup to refresh."
        )
    current_id = _card_id(raw)
    if card_id is not None and current_id != card_id:
        raise StaleCardError(
            f"The current Anki card changed (expected {card_id}, "
            f"found {current_id}).",
            current_card_id=current_id,
        )
    return raw


def best_effort(conn: AnkiConnect, action: str, **params: Any) -> None:
    """Call a cosmetic GUI action without failing the review over it."""
    try:
        conn.invoke(action, **params)
    except BridgeError:
        pass


@contextmanager
def muted_deck(conn: AnkiConnect, deck: Optional[str], enabled: bool) -> Iterator[None]:
    """Temporarily disable automatic audio playback for DECK.

    Anki's reviewer plays answer-side sounds from ``guiShowAnswer``.  There is
    no AnkiConnect action that mutes the player directly, but audio playback is
    gated by the deck preset's ``autoplay`` option.  Flip that option for the
    duration of the GUI call and restore the original preset in ``finally``.

    This is best-effort: if a particular AnkiConnect version cannot read or
    write deck configs, the review still proceeds (otherwise a mute failure
    would make the whole bridge unusable).
    """
    if not enabled or not deck:
        yield
        return

    original_config: Optional[Mapping[str, Any]] = None
    original_autoplay = None
    muted = False

    try:
        config = conn.invoke("getDeckConfig", deck=deck)
        if isinstance(config, dict):
            original_config = config
            original_autoplay = bool(config.get("autoplay", True))
            if original_autoplay:
                silent = dict(config)
                silent["autoplay"] = False
                # Newer AnkiConnect versions reject client-provided metadata.
                silent.pop("mod", None)
                silent.pop("usn", None)
                muted = bool(conn.invoke("saveDeckConfig", config=silent))
    except BridgeError:
        original_config = None
        muted = False

    try:
        yield
    finally:
        if muted and original_config is not None:
            restored = dict(original_config)
            restored["autoplay"] = original_autoplay
            restored.pop("mod", None)
            restored.pop("usn", None)
            try:
                conn.invoke("saveDeckConfig", config=restored)
            except BridgeError:
                # The temporary setting is harmless but should not hide the
                # review result.  A later card operation will try again.
                pass


# ---------------------------------------------------------------------------
# CLI commands


def response_card(raw: Optional[Mapping[str, Any]], message: Optional[str] = None) -> Dict[str, Any]:
    result: Dict[str, Any] = {"ok": True, "card": normalize_card(raw) if raw else None}
    if message:
        result["message"] = message
    return result


def cmd_card(conn: AnkiConnect, deck: str, mute: bool = False) -> Dict[str, Any]:
    # Entering review can itself autoplay question audio, so keep the requested
    # deck muted through navigation as well.
    with muted_deck(conn, deck, mute):
        raw = ensure_review(conn, deck)
        if raw is None:
            return response_card(None, f'No cards are due in deck "{deck}".')

        actual_deck = raw.get("deckName")
        if actual_deck and actual_deck != deck:
            # The selected parent deck may contain subdecks that use a
            # different options preset.
            with muted_deck(conn, actual_deck, mute):
                best_effort(conn, "guiShowQuestion")
                best_effort(conn, "guiStartCardTimer")
        else:
            # If the card was already showing its answer in Anki, put the
            # question side back before Emacs displays it.  The timer starts
            # when we are about to display it, matching Anki's own timing.
            best_effort(conn, "guiShowQuestion")
            best_effort(conn, "guiStartCardTimer")
    return response_card(raw)


def cmd_show(conn: AnkiConnect, card_id: Optional[int], mute: bool = False) -> Dict[str, Any]:
    raw = require_current_card(conn, card_id)
    with muted_deck(conn, raw.get("deckName"), mute):
        shown = conn.invoke("guiShowAnswer")
    if not shown:
        raise BridgeError(
            "Anki would not show the answer. The card may no longer be in review."
        )
    return {"ok": True, "card_id": _card_id(raw), "shown": True}


def cmd_answer(
    conn: AnkiConnect,
    card_id: Optional[int],
    ease: int,
    mute: bool = False,
) -> Dict[str, Any]:
    raw = require_current_card(conn, card_id)
    current_id = _card_id(raw)

    # guiAnswerCard requires that the answer side is visible.  Calling this
    # twice is harmless and makes the command usable without pressing SPC.
    with muted_deck(conn, raw.get("deckName"), mute):
        shown = conn.invoke("guiShowAnswer")
        if not shown:
            raise BridgeError(
                "Anki would not show the answer, so it could not record the review."
            )

        accepted = conn.invoke("guiAnswerCard", ease=ease)
        if not accepted:
            raise BridgeError("Anki rejected the answer.")

        # `guiAnswerCard' may acknowledge the click before Anki's reviewer has
        # finished advancing.  Poll until a different card appears, or until
        # the review has been empty long enough to call it finished.
        next_raw: Optional[Mapping[str, Any]] = None
        empty_polls = 0
        for _index in range(30):
            candidate = current_card(conn)
            if candidate is None:
                empty_polls += 1
                if empty_polls >= 4:
                    break
            elif _card_id(candidate) != current_id:
                next_raw = candidate
                break
            else:
                empty_polls = 0
            time.sleep(0.1)

    if next_raw is None:
        return {
            "ok": True,
            "answered": current_id,
            "card": None,
            "message": "Anki accepted the answer; no next card is ready yet.",
        }

    best_effort(conn, "guiStartCardTimer")
    return {
        "ok": True,
        "answered": current_id,
        "card": normalize_card(next_raw),
    }


def cmd_decks(conn: AnkiConnect) -> Dict[str, Any]:
    names = conn.invoke("deckNames")
    if not isinstance(names, list):
        raise BridgeError("AnkiConnect returned an unexpected deck list.")
    return {"ok": True, "decks": sorted(str(name) for name in names)}


def cmd_check(conn: AnkiConnect, deck: str) -> Dict[str, Any]:
    version = conn.invoke("version")
    names = conn.invoke("deckNames")
    if not isinstance(names, list):
        raise BridgeError("AnkiConnect returned an unexpected deck list.")
    names = sorted(str(name) for name in names)
    raw = current_card(conn)
    return {
        "ok": True,
        "anki_connect_version": version,
        "deck": deck,
        "deck_exists": deck in names,
        "matching_decks": sorted(deck_tree(deck, names)),
        "reviewing": raw is not None,
        "current_card_id": _card_id(raw) if raw else None,
    }


# ---------------------------------------------------------------------------
# Argument parsing and entry point


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="emacs-anki",
        description=(
            "Review Anki cards from Emacs through AnkiConnect. JSON is written "
            "to stdout; errors are reported as {\"ok\": false, \"error\": ...}."
        ),
    )
    parser.add_argument(
        "--url",
        default=os.environ.get("EMACS_ANKI_URL", DEFAULT_URL),
        help=f"AnkiConnect URL (default: {DEFAULT_URL})",
    )
    parser.add_argument(
        "--deck",
        default=os.environ.get("EMACS_ANKI_DECK", DEFAULT_DECK),
        help=f'Deck to review (default: "{DEFAULT_DECK}")',
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=float(os.environ.get("EMACS_ANKI_TIMEOUT", "5")),
        help="HTTP timeout in seconds (default: 5)",
    )
    parser.add_argument(
        "--mute",
        action="store_true",
        help=(
            "Temporarily disable Anki's automatic deck audio while this "
            "command shows or answers a card."
        ),
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print the JSON output.",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("card", help="Enter the deck and return the current card.")
    show = subparsers.add_parser("show", help="Show the answer side in Anki.")
    show.add_argument("--card-id", type=int, default=None)
    answer = subparsers.add_parser("answer", help="Answer the current card.")
    answer.add_argument("ease", type=int, choices=sorted(EASE_NAMES))
    answer.add_argument("--card-id", type=int, default=None)
    subparsers.add_parser("decks", help="List deck names.")
    subparsers.add_parser("check", help="Check the AnkiConnect connection and deck.")

    return parser


def emit(data: Mapping[str, Any], pretty: bool = False) -> None:
    json.dump(
        data,
        sys.stdout,
        ensure_ascii=False,
        indent=2 if pretty else None,
        separators=None if pretty else (",", ":"),
    )
    sys.stdout.write("\n")
    sys.stdout.flush()


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    api_key = os.environ.get("EMACS_ANKI_KEY", "").strip() or None
    conn = AnkiConnect(args.url, api_key, args.timeout)

    try:
        if args.command == "card":
            result = cmd_card(conn, args.deck, args.mute)
        elif args.command == "show":
            result = cmd_show(conn, args.card_id, args.mute)
        elif args.command == "answer":
            result = cmd_answer(conn, args.card_id, args.ease, args.mute)
        elif args.command == "decks":
            result = cmd_decks(conn)
        elif args.command == "check":
            result = cmd_check(conn, args.deck)
        else:  # pragma: no cover - argparse prevents this
            raise BridgeError(f"Unknown command: {args.command}")
    except StaleCardError as exc:
        emit(
            {
                "ok": False,
                "error": str(exc),
                "stale": True,
                "current_card_id": exc.current_card_id,
            },
            args.pretty,
        )
        return 1
    except BridgeError as exc:
        emit({"ok": False, "error": str(exc)}, args.pretty)
        return 1
    except KeyboardInterrupt:
        emit({"ok": False, "error": "Interrupted."}, args.pretty)
        return 130

    emit(result, args.pretty)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
