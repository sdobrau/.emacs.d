# emacs-anki

Review Anki cards in emacs.

## Requirements

* Anki Desktop, running, with the
  [AnkiConnect add-on](https://ankiweb.net/shared/info/2055492159) installed
  (add-on code `2055492159`).
* Python 3.8 or newer. The bridge uses only the standard library.
* Emacs 27.1 or newer, either graphical or terminal. Graphical Emacs uses a
  child frame near point; terminal Emacs uses the echo area.
* A configured deck different name you configure.
```
## Emacs setup

Add the directory to `load-path`, require the package, set at least the deck
and interval, and enable the global mode:

```elisp

(use-package emacs-anki
  :vc (:url "https://github.com/sdobrau/emacs-anki"
            :rev :newest)

  :config
  (require 'emacs-anki)

  (setq emacs-anki-deck "Default")       ; your deck here
  (setq emacs-anki-interval 15)          ; minutes

  (emacs-anki-mode 1))
```

The first review appears after `emacs-anki-interval` minutes. To review
immediately, run:

```text
M-x emacs-anki-review-now
```

A convenient global binding:

```elisp
(global-set-key (kbd "C-c a r") #'emacs-anki-review-now)
```

### Choosing the deck interactively

You can change the deck without editing your init file:

```text
M-x emacs-anki-set-deck
```

This asks AnkiConnect for the live deck list and prompts with completion. It
updates `emacs-anki-deck` for the current Emacs session. If a review is
open, it is refreshed against the newly selected deck.

Use a prefix argument to persist the choice through Customize:

```text
C-u M-x emacs-anki-set-deck
```
You can still set the default directly, which is useful for init files:

```elisp
(setq emacs-anki-deck "Default")
```
## Using the review UI

In graphical Emacs the child frame appears just below point. In a terminal the
card is shown in the echo area (the minibuffer window) and the review keys are
temporarily bound. Both show the question and these keys:

|Key           |Action                            |
|--------------|----------------------------------|
|`SPC` or `RET`|Show the answer                   |
|`1`           |Again                             |
|`2`           |Hard (if Anki offers it)          |
|`3`           |Good                              |
|`4`           |Easy (if Anki offers it)          |
|`g`           |Reload the current card           |
|`q`           |Dismiss the review                |
|`C-v` / `M-v` |Scroll long cards (graphical only)|

After `1`, `2`, `3`, or `4`, the next card is fetched and displayed. When the
queue is empty, the review closes.

In a terminal the temporary keys stay active while you use them. Running an
unrelated command closes the echo-area review, so normal typing is not
captured; `M-x emacs-anki-review-now` starts a fresh review. Very long cards
are limited by the echo area height; raise `max-mini-window-height` if you
need more room.

