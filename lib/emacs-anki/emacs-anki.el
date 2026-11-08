;;; emacs-anki.el --- Review Anki cards in an Emacs child frame -*- lexical-binding: t; -*-

;; Version: 0.6.1
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, education
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; This package is the Emacs half of a tiny Anki review bridge.  The Python
;; program `emacs_anki.py' talks to AnkiConnect, and this file periodically
;; opens a child frame near point in graphical Emacs, or shows the card in the
;; echo area in terminal Emacs.  Press SPC to reveal the answer, 1 for Again,
;; 3 for Good, and q to dismiss the review.
;;
;; Anki must be running with the AnkiConnect add-on installed.  The default
;; deck is "Default"; customize `emacs-anki-deck' to change it.
;;
;; Enable the timer with:
;;
;;   (require 'emacs-anki)
;;   (emacs-anki-mode 1)
;;
;; Use `M-x emacs-anki-review-now' to start a review immediately.

;;; Code:

(require 'json)
(require 'nadvice)
(require 'seq)
(require 'subr-x)

(defvar emacs-anki--directory
  (file-name-directory
   (or load-file-name buffer-file-name
       (expand-file-name "emacs-anki.el")))
  "Directory containing this package and the Python bridge.")

(defgroup emacs-anki nil
  "Review Anki cards from Emacs."
  :group 'applications
  :prefix "emacs-anki-")

(defcustom emacs-anki-python-file
  (expand-file-name "emacs_anki.py" emacs-anki--directory)
  "Path to the `emacs_anki.py' helper program."
  :type 'file
  :group 'emacs-anki)

(defcustom emacs-anki-python-command "python3"
  "Python interpreter used to run `emacs-anki-python-file'."
  :type 'string
  :group 'emacs-anki)

(defcustom emacs-anki-deck "Default"
  "Anki deck to review.

Subdecks are included when Anki's review queue includes them."
  :type 'string
  :group 'emacs-anki)

(defun emacs-anki--set-interval (symbol value)
  "Set SYMBOL to VALUE and restart the review timer if the mode is active."
  (set-default symbol value)
  (when (and (boundp 'emacs-anki-mode) emacs-anki-mode)
    (emacs-anki--start-timer)))

(defcustom emacs-anki-interval 15
  "Minutes between automatic review popups.

The timer is only started while `emacs-anki-mode' is enabled."
  :type 'number
  :set #'emacs-anki--set-interval
  :group 'emacs-anki)

(defcustom emacs-anki-close-after-timer-review t
  "Whether a timer-opened popup closes after a single review.

When non-nil, answering a card that appeared because the timer fired closes
the popup, even if more cards are due.  A manually opened review keeps showing
the next card.  Set this to nil to let both kinds of popup continue through the
queue."
  :type 'boolean
  :group 'emacs-anki)

(defcustom emacs-anki-url "http://127.0.0.1:8765"
  "AnkiConnect URL."
  :type 'string
  :group 'emacs-anki)

(defcustom emacs-anki-key nil
  "Optional AnkiConnect API key.

It is passed to the Python helper through the environment, not through its
command line.  For most local installations this is nil."
  :type '(choice (const :tag "No API key" nil) string)
  :group 'emacs-anki)

(defcustom emacs-anki-connect-timeout 5
  "Seconds the Python helper waits for AnkiConnect."
  :type 'number
  :group 'emacs-anki)

(defcustom emacs-anki-mute-audio t
  "Whether to suppress Anki's automatic audio while using the bridge.

The Python helper temporarily turns off the current deck preset's `autoplay'
option while it shows or answers a card, then restores it.  This prevents card
audio from playing when a review is submitted through Emacs.  Set this to nil
to leave Anki's audio behavior untouched."
  :type 'boolean
  :group 'emacs-anki)

(defcustom emacs-anki-frame-width 72
  "Width of the review child frame in characters."
  :type 'integer
  :group 'emacs-anki)

(defcustom emacs-anki-frame-min-height 5
  "Minimum height of the review child frame in lines."
  :type 'integer
  :group 'emacs-anki)

(defcustom emacs-anki-frame-max-height 28
  "Maximum height of the review child frame in lines.

If a card is longer than this, C-v and M-v scroll inside the popup."
  :type 'integer
  :group 'emacs-anki)

(defcustom emacs-anki-focus-on-popup t
  "Whether the review popup should take keyboard focus when it appears.

Set this to nil if the timer must never steal focus.  You can then click the
popup to review it.  Keys 1, 3, SPC, and q work once it has focus."
  :type 'boolean
  :group 'emacs-anki)

(defcustom emacs-anki-skip-during-minibuffer t
  "Whether a timer-triggered popup is skipped while the minibuffer is active."
  :type 'boolean
  :group 'emacs-anki)

(defcustom emacs-anki--process-grace 5
  "Extra seconds before the Emacs side kills a stuck Python helper."
  :type 'number
  :group 'emacs-anki)

(defface emacs-anki-header-face
  '((t :weight bold :height 1.08))
  "Face for the review popup heading."
  :group 'emacs-anki)

(defface emacs-anki-controls-face
  '((t :inherit font-lock-keyword-face))
  "Face for the key hints."
  :group 'emacs-anki)

(defface emacs-anki-meta-face
  '((t :inherit shadow))
  "Face for deck and model information."
  :group 'emacs-anki)

(defface emacs-anki-question-face
  '((t :inherit default))
  "Face for the question text."
  :group 'emacs-anki)

(defface emacs-anki-answer-heading-face
  '((t :inherit font-lock-function-name-face :weight bold))
  "Face for the answer heading."
  :group 'emacs-anki)

(defface emacs-anki-answer-face
  '((t :inherit default))
  "Face for the answer text."
  :group 'emacs-anki)

(defface emacs-anki-error-face
  '((t :inherit error))
  "Face for errors shown in the popup."
  :group 'emacs-anki)

(defvar emacs-anki--timer nil
  "Repeating review timer.")

(defvar emacs-anki--process nil
  "Currently running Python helper, if any.")

(defvar emacs-anki--busy nil
  "Non-nil while a Python request is in flight.")

(defvar emacs-anki--timer-review nil
  "Non-nil when the current popup was opened by the review timer.")

(defvar emacs-anki--deck-choices nil
  "Deck names most recently returned by AnkiConnect.")

(defvar emacs-anki-deck-history nil
  "Minibuffer history for `emacs-anki-set-deck'.")

(defvar emacs-anki--frame nil
  "Current review child frame.")

(defvar emacs-anki--buffer nil
  "Buffer holding the rendered review text.")

(defvar emacs-anki--card nil
  "Normalized card currently displayed.")

(defvar emacs-anki--revealed nil
  "Non-nil when the answer is visible in the popup.")

(defvar emacs-anki--parent-frame nil
  "Frame that owns the review child frame.")

(defvar emacs-anki--minibuffer-active nil
  "Non-nil while the terminal review is displayed in the echo area.")

(defvar emacs-anki--minibuffer-text nil
  "Text last shown for the terminal review.")

(defvar emacs-anki--minibuffer-exit-function nil
  "Function that removes the terminal review keymap, if installed.")

(defvar emacs-anki--minibuffer-disarming nil
  "Non-nil while the terminal review keymap is being removed on purpose.")

(defvar emacs-anki--display-frame nil
  "Frame showing the terminal echo-area review.")

(defvar emacs-anki--frame-focused nil
  "Non-nil once the active review has held input focus.")

(defvar emacs-anki--focus-timer nil
  "Debounce timer for closing a review that lost focus.")

(defvar emacs-anki--closing-for-focus-loss nil
  "Non-nil while closing a review because it lost input focus.")

(defun emacs-anki--interval-seconds ()
  "Return the configured interval in seconds, with a small safety floor."
  (max 1 (round (* 60 (float emacs-anki-interval)))))

(defun emacs-anki--start-timer ()
  "Start or restart the periodic review timer."
  (emacs-anki--stop-timer)
  (setq emacs-anki--timer
        (run-at-time (emacs-anki--interval-seconds)
                     (emacs-anki--interval-seconds)
                     #'emacs-anki--on-timer)))

(defun emacs-anki--stop-timer ()
  "Stop the periodic review timer."
  (when (timerp emacs-anki--timer)
    (cancel-timer emacs-anki--timer))
  (setq emacs-anki--timer nil))

;;;###autoload
(define-minor-mode emacs-anki-mode
  "Periodically show due Anki cards in a child frame or the echo area.

This is a global minor mode.  Anki must be running with AnkiConnect
installed, and the Python helper must be available at
`emacs-anki-python-file'."
  :global t
  :lighter nil
  :group 'emacs-anki
  (if emacs-anki-mode
      (progn
        (emacs-anki--start-timer)
        (message "Anki review every %s minute(s); next popup at %s (%s)"
                 emacs-anki-interval
                 (format-time-string "%H:%M"
                                     (time-add
                                      (current-time)
                                      (seconds-to-time
                                       (emacs-anki--interval-seconds))))
                 (if (display-graphic-p) "child frame" "echo area")))
    (emacs-anki--stop-timer)))

;;;###autoload
(defun emacs-anki-review-now ()
  "Show the next due Anki card immediately."
  (interactive)
  (cond
   ((emacs-anki--display-active-p)
    (if (emacs-anki--review-unfocused-p)
        ;; The popup was left behind by a focus change that we did not
        ;; observe in time.  Drop it and start a fresh review.
        (progn
          (emacs-anki--close-review)
          (setq emacs-anki--timer-review nil)
          (emacs-anki--request '("card") #'emacs-anki--handle-card))
      (emacs-anki--focus-display)
      (message "Anki review popup is already open")))
   (emacs-anki--busy
    (message "Anki review: still waiting for Anki"))
   (t
    (setq emacs-anki--timer-review nil)
    (emacs-anki--request '("card") #'emacs-anki--handle-card))))

(defun emacs-anki--on-timer ()
  "Timer callback for periodic reviews."
  (unless (or emacs-anki--busy
              (emacs-anki--display-active-p)
              (and emacs-anki-skip-during-minibuffer
                   (active-minibuffer-window)))
    (setq emacs-anki--timer-review t)
    (condition-case err
        (emacs-anki--request '("card") #'emacs-anki--handle-card)
      (error
       (setq emacs-anki--timer-review nil)
       (message "Anki review: %s" (error-message-string err))))))

;;;###autoload
(defun emacs-anki-dismiss ()
  "Close the review popup and cancel any pending request."
  (interactive)
  (emacs-anki--cancel-request)
  (emacs-anki--close-display)
  (message "Anki review dismissed"))

;;;###autoload
(defun emacs-anki-refresh ()
  "Reload the current card from Anki."
  (interactive)
  (cond
   (emacs-anki--busy
    (message "Anki review: still waiting for Anki"))
   (t
    (unless (emacs-anki--display-active-p)
      (setq emacs-anki--timer-review nil))
    (emacs-anki--request '("card") #'emacs-anki--handle-card))))

;;;###autoload
(defun emacs-anki-set-deck (&optional save)
  "Choose the Anki deck to review from Anki's deck list.

With a prefix argument, also save the choice through Customize.  Without it,
the change lasts for the current Emacs session.  If a review popup is open, it
is refreshed against the newly selected deck."
  (interactive "P")
  (cond
   (emacs-anki--busy
    (message "Anki review: wait for the current request before changing decks"))
   (t
    (emacs-anki--request
     '("decks")
     (lambda (data)
       (if (eq (alist-get 'ok data) t)
           (let ((decks (alist-get 'decks data)))
             (if decks
                 (progn
                   (setq emacs-anki--deck-choices decks)
                   (run-at-time
                    0.01 nil
                    (lambda () (emacs-anki--prompt-for-deck save))))
               (message "Anki returned an empty deck list")))
         (message "Anki review: %s"
                  (or (alist-get 'error data) "could not list decks"))))))))

(defun emacs-anki--prompt-for-deck (&optional save)
  "Prompt for a deck from `emacs-anki--deck-choices'.

When SAVE is non-nil, persist the selected value through Customize."
  (let ((decks emacs-anki--deck-choices))
    (if (null decks)
        (message "Anki returned an empty deck list")
      (let* ((default (and (member emacs-anki-deck decks) emacs-anki-deck))
             (choice (completing-read "Anki deck: " decks nil t nil
                                      'emacs-anki-deck-history default)))
        (when (and choice (not (string-empty-p choice)))
          (if save
              (customize-save-variable 'emacs-anki-deck choice)
            (setq emacs-anki-deck choice))
          (message "Anki deck: %s%s" choice
                   (if save " (saved)" " (this session only)"))
          (when (emacs-anki--display-active-p)
            (emacs-anki-refresh)))))))

;;;###autoload
(defun emacs-anki-show-answer ()
  "Reveal the answer for the current card."
  (interactive)
  (cond
   ((null emacs-anki--card)
    (message "Anki review: no card is displayed"))
   (emacs-anki--revealed
    (message "Answer is already shown"))
   (emacs-anki--busy
    (message "Anki review: still waiting for Anki"))
   (t
    (emacs-anki--request
     (list "show" "--card-id" (number-to-string (alist-get 'id emacs-anki--card)))
     #'emacs-anki--handle-shown))))

(defun emacs-anki-again ()
  "Answer the current card with Again."
  (interactive)
  (emacs-anki--answer 1))

(defun emacs-anki-hard ()
  "Answer the current card with Hard."
  (interactive)
  (emacs-anki--answer 2))

(defun emacs-anki-good ()
  "Answer the current card with Good."
  (interactive)
  (emacs-anki--answer 3))

(defun emacs-anki-easy ()
  "Answer the current card with Easy."
  (interactive)
  (emacs-anki--answer 4))

(defun emacs-anki--answer (ease)
  "Submit EASE for the current card."
  (let ((card emacs-anki--card))
    (cond
     ((null card)
      (message "Anki review: no card is displayed"))
     (emacs-anki--busy
      (message "Anki review: still waiting for Anki"))
     ((not (emacs-anki--ease-available-p card ease))
      (message "Anki did not offer the %s button for this card"
               (or (alist-get ease '((1 . "Again") (2 . "Hard")
                                     (3 . "Good") (4 . "Easy")))
                   (number-to-string ease))))
     (t
      (emacs-anki--request
       (list "answer"
             (number-to-string ease)
             "--card-id"
             (number-to-string (alist-get 'id card)))
       #'emacs-anki--handle-answered)))))

(defun emacs-anki--ease-available-p (card ease)
  "Return non-nil if CARD offers a button with EASE."
  (seq-some (lambda (button)
              (equal (alist-get 'ease button) ease))
            (alist-get 'buttons card)))

(defvar emacs-anki-minibuffer-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "SPC") #'emacs-anki-show-answer)
    (define-key map (kbd "RET") #'emacs-anki-show-answer)
    (define-key map (kbd "1") #'emacs-anki-again)
    (define-key map (kbd "2") #'emacs-anki-hard)
    (define-key map (kbd "3") #'emacs-anki-good)
    (define-key map (kbd "4") #'emacs-anki-easy)
    (define-key map (kbd "g") #'emacs-anki-refresh)
    (define-key map (kbd "q") #'emacs-anki-dismiss)
    map)
  "Keymap active while the terminal review is shown in the echo area.")

(defun emacs-anki--handle-card (data)
  "Handle a `card' response in DATA."
  (if (eq (alist-get 'ok data) t)
      (let ((card (alist-get 'card data))
            (msg (alist-get 'message data)))
        (if card
            (emacs-anki--show-card card)
          (emacs-anki--finish (or msg "No cards are due."))))
    (emacs-anki--handle-error data)))

(defun emacs-anki--handle-shown (data)
  "Handle a `show' response in DATA."
  (if (eq (alist-get 'ok data) t)
      (progn
        (setq emacs-anki--revealed t)
        (emacs-anki--render)
        (emacs-anki--fit-frame))
    (emacs-anki--handle-error data)))

(defun emacs-anki--handle-answered (data)
  "Handle an `answer' response in DATA."
  (if (eq (alist-get 'ok data) t)
      (let ((card (alist-get 'card data))
            (msg (alist-get 'message data))
            (timer-close (and emacs-anki-close-after-timer-review
                              emacs-anki--timer-review)))
        (cond
         (timer-close
          (emacs-anki--finish "Timer review complete."))
         (card
          (emacs-anki--show-card card))
         (t
          (emacs-anki--finish (or msg "Review finished.")))))
    (if (alist-get 'stale data)
        (progn
          (message "Anki changed cards; reloading the review popup")
          (emacs-anki-refresh))
      (emacs-anki--handle-error data))))

(defun emacs-anki--handle-error (data)
  "Display the error contained in DATA."
  (let ((err (or (alist-get 'error data) "Unknown AnkiConnect error.")))
    (if (emacs-anki--display-active-p)
        (progn
          (setq emacs-anki--revealed nil)
          (emacs-anki--render-error err))
      (progn
        (setq emacs-anki--timer-review nil)
        (message "Anki review: %s" err)))))

(defun emacs-anki--finish (msg)
  "Close the review popup and report MSG."
  (emacs-anki--close-display)
  (message "Anki review: %s" msg))

;; ---------------------------------------------------------------------------
;; Python helper process

(defun emacs-anki--child-environment ()
  "Return a process environment for the Python helper."
  (let ((env (copy-sequence process-environment)))
    (setq env (cons (concat "EMACS_ANKI_KEY=" (or emacs-anki-key "")) env))
    (setq env (cons "PYTHONIOENCODING=utf-8" env))
    env))

(defun emacs-anki--command (args)
  "Build the Python command line for ARGS."
  (append (list emacs-anki-python-command
                emacs-anki-python-file
                "--url" emacs-anki-url
                "--deck" emacs-anki-deck
                "--timeout" (number-to-string emacs-anki-connect-timeout))
          (when emacs-anki-mute-audio
            '("--mute"))
          args))

(defun emacs-anki--request (args callback)
  "Run the Python helper with ARGS and call CALLBACK with parsed JSON.

CALLBACK always receives an alist.  Successful responses have `ok' set to t;
failures have it set to nil and an `error' string."
  (if emacs-anki--busy
      (message "Anki review: still waiting for Anki")
    (let* ((outbuf (generate-new-buffer " *emacs-anki-stdout*"))
           (errbuf (generate-new-buffer " *emacs-anki-stderr*"))
           (env (emacs-anki--child-environment))
           (cmd (emacs-anki--command args))
           (proc nil)
           (timer nil))
      (condition-case err
          (let ((process-environment env))
            (setq proc
                  (make-process
                   :name "emacs-anki-helper"
                   :buffer outbuf
                   :stderr errbuf
                   :command cmd
                   :coding 'utf-8-unix
                   :connection-type 'pipe
                   :noquery t
                   :sentinel #'ignore)))
        (error
         (kill-buffer outbuf)
         (kill-buffer errbuf)
         (funcall callback
                  (list (cons 'ok nil)
                        (cons 'error
                              (format "Cannot start the Python helper: %s"
                                      (error-message-string err)))))))

      (when proc
        (setq emacs-anki--busy t
              emacs-anki--process proc)
        (process-put proc 'emacs-anki-output outbuf)
        (process-put proc 'emacs-anki-error errbuf)
        (process-put proc 'emacs-anki-callback callback)
        (set-process-sentinel proc #'emacs-anki--sentinel)
        (setq timer
              (run-at-time
               (+ (max 1 emacs-anki-connect-timeout) emacs-anki--process-grace)
               nil
               (lambda ()
                 (when (process-live-p proc)
                   (process-put proc 'emacs-anki-timed-out t)
                   (delete-process proc)))))
        (process-put proc 'emacs-anki-timer timer)))))

(defun emacs-anki--sentinel (proc _event)
  "Handle the completion of helper process PROC."
  (when (memq (process-status proc) '(exit signal))
    (let ((timer (process-get proc 'emacs-anki-timer)))
      (when (timerp timer)
        (cancel-timer timer)))

    (let* ((outbuf (process-get proc 'emacs-anki-output))
           (errbuf (process-get proc 'emacs-anki-error))
           (callback (process-get proc 'emacs-anki-callback))
           (cancelled (process-get proc 'emacs-anki-cancelled))
           (timed-out (process-get proc 'emacs-anki-timed-out))
           (current (eq proc emacs-anki--process))
           (stdout (if (buffer-live-p outbuf)
                       (with-current-buffer outbuf
                         (buffer-substring-no-properties (point-min) (point-max)))
                     ""))
           (stderr (if (buffer-live-p errbuf)
                       (with-current-buffer errbuf
                         (buffer-substring-no-properties (point-min) (point-max)))
                     ""))
           (data nil))

      (when current
        (setq emacs-anki--busy nil
              emacs-anki--process nil))

      (unless cancelled
        (setq data
              (cond
               (timed-out
                (list (cons 'ok nil)
                      (cons 'error
                            (format "No response from AnkiConnect within %s seconds. \
Is Anki busy or showing a dialog?"
                                    (+ (max 1 emacs-anki-connect-timeout)
                                       emacs-anki--process-grace)))))
               (t
                (emacs-anki--parse-output proc stdout stderr))))
        (when (and data callback current)
          (funcall callback data)))

      (when (buffer-live-p outbuf) (kill-buffer outbuf))
      (when (buffer-live-p errbuf) (kill-buffer errbuf)))))

(defun emacs-anki--parse-output (proc stdout stderr)
  "Parse STDOUT from PROC, falling back to STDERR and the exit status."
  (let ((data nil)
        (stderr (string-trim (or stderr ""))))
    (when (and stdout (not (string-empty-p (string-trim stdout))))
      (setq data
            (condition-case nil
                (json-parse-string stdout
                                   :object-type 'alist
                                   :array-type 'list
                                   :null-object nil
                                   :false-object nil)
              (error nil))))

    (if (and (listp data)
             (assq 'ok data)
             (alist-get 'ok data))
        data
      (let ((base (cond
                   ((and (listp data) (assq 'ok data))
                    (or (alist-get 'error data) "Anki request failed."))
                   ((not (zerop (process-exit-status proc)))
                    (format "The Python helper exited with status %s."
                            (process-exit-status proc)))
                   (t
                    "The Python helper returned no usable JSON."))))
        (when (and stderr (not (string-empty-p stderr)))
          (let ((lines (split-string stderr "\n" t)))
            (setq base
                  (concat base " "
                          (string-join (last lines (min 3 (length lines))) " ")))))
        (list (cons 'ok nil) (cons 'error base))))))

(defun emacs-anki--cancel-request ()
  "Cancel the currently running helper, if any."
  (when (process-live-p emacs-anki--process)
    (process-put emacs-anki--process 'emacs-anki-cancelled t)
    (delete-process emacs-anki--process))
  (setq emacs-anki--busy nil
        emacs-anki--process nil))

(defun emacs-anki--on-frame-deleted (frame)
  "Reset review state when the popup FRAME is deleted externally.

Without this, `emacs-anki--frame' can keep pointing at a dead frame while a
request is still running.  The callback would then resurrect the popup or
operate on stale state."
  (when (eq frame emacs-anki--frame)
    (emacs-anki--cancel-focus-timer)
    (setq emacs-anki--frame nil
          emacs-anki--frame-focused nil
          emacs-anki--card nil
          emacs-anki--revealed nil
          emacs-anki--timer-review nil)
    (emacs-anki--cancel-request)))

;; ---------------------------------------------------------------------------
;; Display backends and rendering

(defun emacs-anki--ensure-buffer ()
  "Create or prepare the review buffer and return it."
  (unless (buffer-live-p emacs-anki--buffer)
    (setq emacs-anki--buffer (get-buffer-create " *emacs-anki-review*")))
  (with-current-buffer emacs-anki--buffer
    (unless (derived-mode-p 'emacs-anki-review-mode)
      (emacs-anki-review-mode)))
  emacs-anki--buffer)

(defun emacs-anki--display-active-p ()
  "Return non-nil if a usable review popup is currently visible."
  (if (display-graphic-p)
      (and (frame-live-p emacs-anki--frame)
           (eq (frame-visible-p emacs-anki--frame) t)
           (buffer-live-p emacs-anki--buffer)
           (eq (window-buffer (frame-root-window emacs-anki--frame))
               emacs-anki--buffer))
    (and emacs-anki--minibuffer-active
         (buffer-live-p emacs-anki--buffer))))

(defun emacs-anki--review-display-frame ()
  "Return the frame displaying the active review, or nil."
  (if (display-graphic-p)
      emacs-anki--frame
    emacs-anki--display-frame))

(defun emacs-anki--cancel-focus-timer ()
  "Cancel the pending focus-loss timer, if any."
  (when (timerp emacs-anki--focus-timer)
    (cancel-timer emacs-anki--focus-timer))
  (setq emacs-anki--focus-timer nil))

(defun emacs-anki--review-unfocused-p ()
  "Return non-nil if the active review has lost input focus."
  (and emacs-anki--frame-focused
       (fboundp 'frame-focus-state)
       (let ((frame (emacs-anki--review-display-frame)))
         (and (frame-live-p frame)
              (null (frame-focus-state frame))))))

(defun emacs-anki--close-review ()
  "Close the active review without reporting anything."
  (when (emacs-anki--display-active-p)
    (emacs-anki--cancel-request)
    (emacs-anki--close-display)))

(defun emacs-anki--dismiss-on-focus-loss ()
  "Close the review because its frame no longer has input focus."
  (when (emacs-anki--display-active-p)
    (let ((emacs-anki--closing-for-focus-loss t))
      (emacs-anki--close-review))
    (message "Anki review closed because it lost focus")))

(defun emacs-anki--maybe-dismiss-on-focus-loss ()
  "Close the review if it is still unfocused."
  (setq emacs-anki--focus-timer nil)
  (when (emacs-anki--review-unfocused-p)
    (emacs-anki--dismiss-on-focus-loss)))

(defun emacs-anki--schedule-focus-dismiss ()
  "Arrange to close the review shortly after it loses focus."
  (unless (timerp emacs-anki--focus-timer)
    (setq emacs-anki--focus-timer
          (run-at-time 0.1 nil
                       #'emacs-anki--maybe-dismiss-on-focus-loss))))

(defun emacs-anki--after-focus-change ()
  "Track focus of the review frame and close the review when it is lost."
  (when (emacs-anki--display-active-p)
    (let ((frame (emacs-anki--review-display-frame)))
      (when (and (frame-live-p frame)
                 (fboundp 'frame-focus-state))
        (let ((state (frame-focus-state frame)))
          (cond
           ((eq state t)
            (setq emacs-anki--frame-focused t)
            (emacs-anki--cancel-focus-timer))
           ((and emacs-anki--frame-focused (null state))
            (emacs-anki--schedule-focus-dismiss))))))))

(defun emacs-anki--ensure-frame ()
  "Create the GUI review child frame if needed and return it."
  (unless (display-graphic-p)
    (user-error "Child frames require graphical Emacs"))
  (emacs-anki--ensure-buffer)
  (unless (frame-live-p emacs-anki--frame)
    (let* ((parent (selected-frame))
           (background (face-background 'default parent))
           (foreground (face-foreground 'default parent))
           (buffer emacs-anki--buffer)
           (frame (make-frame
                   `((parent-frame . ,parent)
                     (name . "emacs-anki-review")
                     (width . ,(max 30 emacs-anki-frame-width))
                     (height . ,(max 3 emacs-anki-frame-min-height))
                     (minibuffer . nil)
                     (undecorated . t)
                     (no-special-glyphs . t)
                     (skip-taskbar . t)
                     (tool-bar-lines . 0)
                     (menu-bar-lines . 0)
                     (tab-bar-lines . 0)
                     (vertical-scroll-bars . nil)
                     (horizontal-scroll-bars . nil)
                     (left-fringe . 0)
                     (right-fringe . 0)
                     (internal-border-width . 1)
                     (border-width . 1)
                     (border-color . ,foreground)
                     (background-color . ,background)
                     (foreground-color . ,foreground)
                     (visibility . nil)
                     (no-accept-focus . nil)))))
      (setq emacs-anki--frame frame
            emacs-anki--parent-frame parent
            emacs-anki--buffer buffer)))
  (let ((window (frame-root-window emacs-anki--frame)))
    (unless (eq (window-buffer window) emacs-anki--buffer)
      (set-window-buffer window emacs-anki--buffer))
    (set-frame-selected-window emacs-anki--frame window))
  emacs-anki--frame)

(defun emacs-anki--minibuffer-card-text ()
  "Return the compact review text shown in the echo area."
  (let* ((card emacs-anki--card)
         (revealed emacs-anki--revealed)
         (question (alist-get 'question card))
         (answer (alist-get 'answer card))
         (meta (string-join
                (seq-filter
                 (lambda (part) (and part (not (string-empty-p part))))
                 (list (alist-get 'deck card)
                       (alist-get 'model card)
                       (alist-get 'template card)))
                "  |  ")))
    (concat
     (propertize
      (if revealed
          "[1] Again   [3] Good   [q] dismiss   [g] refresh"
        "[SPC] show answer   [1] Again   [3] Good   [q] dismiss")
      'face 'emacs-anki-controls-face)
     (when (not (string-empty-p meta))
       (concat "\n" (propertize meta 'face 'emacs-anki-meta-face)))
     "\n\n"
     (propertize
      (if (and question (not (string-empty-p question)))
          question
        "(the question is empty)")
      'face 'emacs-anki-question-face)
     (when revealed
       (concat
        "\n\n"
        (propertize "Answer" 'face 'emacs-anki-answer-heading-face)
        "\n"
        (propertize
         (if (and answer (not (string-empty-p answer)))
             answer
           "(the answer is empty)")
         'face 'emacs-anki-answer-face))))))

(defun emacs-anki--display-minibuffer-card (&optional text)
  "Show the terminal review in the echo area.
TEXT overrides the compact card text, for error messages."
  (when (buffer-live-p emacs-anki--buffer)
    (setq emacs-anki--minibuffer-text
          (or text (emacs-anki--minibuffer-card-text)))
    (message "%s" emacs-anki--minibuffer-text)))

(defun emacs-anki--disarm-minibuffer-keys ()
  "Remove the terminal review keymap, if installed."
  (let ((emacs-anki--minibuffer-disarming t))
    (when (functionp emacs-anki--minibuffer-exit-function)
      (funcall emacs-anki--minibuffer-exit-function))
    (setq emacs-anki--minibuffer-exit-function nil)))

(defun emacs-anki--minibuffer-keep-p ()
  "Return non-nil when the next command is a terminal review command.

This lets `set-transient-map' keep the review keys after a review command
but drop them as soon as the user does something unrelated, so ordinary
typing and the minibuffer are not captured."
  (and emacs-anki--minibuffer-active
       (memq this-command
             '(emacs-anki-show-answer
               emacs-anki-again
               emacs-anki-hard
               emacs-anki-good
               emacs-anki-easy
               emacs-anki-refresh
               emacs-anki-dismiss))))

(defun emacs-anki--arm-minibuffer-keys ()
  "Install the review keymap for the echo-area review."
  (emacs-anki--disarm-minibuffer-keys)
  (setq emacs-anki--minibuffer-exit-function
        (set-transient-map
         emacs-anki-minibuffer-map
         #'emacs-anki--minibuffer-keep-p
         (lambda ()
           (setq emacs-anki--minibuffer-exit-function nil)
           ;; The map also exits when an unrelated command is run.  Treat
           ;; that as losing focus and close the echo-area review.
           (unless emacs-anki--minibuffer-disarming
             (when emacs-anki--minibuffer-active
               (emacs-anki--close-review)
               (message "Anki review closed")))))))

(defun emacs-anki--show-card (card)
  "Display CARD in the review popup."
  (let ((new-popup (not (emacs-anki--display-active-p))))
    (setq emacs-anki--card card
          emacs-anki--revealed nil)
    (emacs-anki--ensure-buffer)
    (if (display-graphic-p)
        (progn
          (emacs-anki--render)
          (emacs-anki--ensure-frame)
          (emacs-anki--fit-frame)
          (when new-popup
            (setq emacs-anki--frame-focused nil)
            (emacs-anki--position-frame)
            (make-frame-visible emacs-anki--frame)
            (emacs-anki--focus-display)))
      (setq emacs-anki--minibuffer-active t
            emacs-anki--display-frame (selected-frame)
            emacs-anki--frame-focused t)
      (emacs-anki--render))))

(defun emacs-anki--render ()
  "Render the current card, respecting `emacs-anki--revealed'."
  (when (buffer-live-p emacs-anki--buffer)
    (with-current-buffer emacs-anki--buffer
      (let ((inhibit-read-only t)
            (card emacs-anki--card)
            (revealed emacs-anki--revealed))
        (erase-buffer)
        (insert (propertize " Anki review  " 'face 'emacs-anki-header-face))
        (insert (propertize
                 (if revealed
                     "[1] Again   [3] Good   [q] dismiss   [g] refresh"
                   "[SPC] show answer   [1] Again   [3] Good   [q] dismiss")
                 'face 'emacs-anki-controls-face))
        (insert "\n")
        (let ((deck (alist-get 'deck card))
              (model (alist-get 'model card))
              (template (alist-get 'template card)))
          (insert (propertize
                   (string-join
                    (seq-filter (lambda (part) (and part (not (string-empty-p part))))
                                (list deck model template))
                    "  |  ")
                   'face 'emacs-anki-meta-face))
          (insert "\n"))
        (insert (propertize (make-string 34 ?─) 'face 'emacs-anki-meta-face))
        (insert "\n\n")
        (let ((question (alist-get 'question card)))
          (insert (propertize
                   (if (and question (not (string-empty-p question)))
                       question
                     "(the question is empty)")
                   'face 'emacs-anki-question-face)))
        (when revealed
          (insert "\n\n")
          (insert (propertize "Answer" 'face 'emacs-anki-answer-heading-face))
          (insert "\n")
          (let ((answer (alist-get 'answer card)))
            (insert (propertize
                     (if (and answer (not (string-empty-p answer)))
                         answer
                       "(the answer is empty)")
                     'face 'emacs-anki-answer-face))))
        (goto-char (point-min))))
    (when emacs-anki--minibuffer-active
      (emacs-anki--display-minibuffer-card)
      (emacs-anki--arm-minibuffer-keys))))

(defun emacs-anki--render-error (err)
  "Render ERR in the review popup."
  (when (buffer-live-p emacs-anki--buffer)
    (with-current-buffer emacs-anki--buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (propertize " Anki review  " 'face 'emacs-anki-header-face))
        (insert (propertize "[g] retry   [q] dismiss"
                            'face 'emacs-anki-controls-face))
        (insert "\n\n")
        (insert (propertize "The Anki request failed"
                            'face 'emacs-anki-answer-heading-face))
        (insert "\n\n")
        (insert (propertize (or err "Unknown error.")
                            'face 'emacs-anki-error-face))
        (goto-char (point-min))))
    (if emacs-anki--minibuffer-active
        (progn
          (emacs-anki--display-minibuffer-card
           (with-current-buffer emacs-anki--buffer
             (buffer-string)))
          (emacs-anki--arm-minibuffer-keys))
      (emacs-anki--fit-frame))))

(defun emacs-anki--fit-frame ()
  "Resize the graphical review popup to fit its contents."
  (when (display-graphic-p)
    (emacs-anki--fit-graphical-frame)))

(defun emacs-anki--fit-graphical-frame ()
  "Resize the GUI review frame to fit its contents."
  (when (frame-live-p emacs-anki--frame)
    (let* ((frame emacs-anki--frame)
           (window (frame-root-window frame))
           (width (max 30 emacs-anki-frame-width))
           (char-width (max 1 (frame-char-width frame)))
           (char-height (max 1 (frame-char-height frame)))
           (x-limit (* width char-width)))
      ;; Set the requested width first; `window-text-pixel-size' then wraps
      ;; long lines at the same width the frame will use.
      (set-frame-size frame width (max 3 emacs-anki-frame-min-height))
      (let* ((size (window-text-pixel-size window nil nil x-limit nil))
             (lines (ceiling (cdr size) (float char-height)))
             (height (max emacs-anki-frame-min-height
                          (min emacs-anki-frame-max-height
                               (+ lines 1)))))
        (set-frame-size frame width height)))))

(defun emacs-anki--position-frame ()
  "Place the review frame just below point, keeping it on screen."
  (when (frame-live-p emacs-anki--frame)
    (let* ((frame emacs-anki--frame)
           (parent (or (frame-parent frame) emacs-anki--parent-frame))
           (point-pos (window-absolute-pixel-position))
           (x (or (car-safe point-pos) 20))
           (y (or (cdr-safe point-pos) 20))
           (frame-width (frame-pixel-width frame))
           (frame-height (frame-pixel-height frame))
           (parent-width (if (frame-live-p parent)
                             (frame-pixel-width parent)
                           (display-pixel-width)))
           (parent-height (if (frame-live-p parent)
                              (frame-pixel-height parent)
                            (display-pixel-height)))
           (gap (if (frame-live-p parent)
                    (frame-char-height parent)
                  16))
           (x (max 0 (min x (- parent-width frame-width))))
           (y (if (> (+ y gap frame-height) parent-height)
                  (max 0 (- y frame-height))
                (+ y gap))))
      (set-frame-position frame x y))))

(defun emacs-anki--focus-display ()
  "Give the review popup keyboard focus when configured to do so."
  (if (display-graphic-p)
      (when emacs-anki-focus-on-popup
        (when (frame-live-p emacs-anki--frame)
          (condition-case nil
              (select-frame-set-input-focus emacs-anki--frame)
            (error
             (condition-case nil
                 (x-focus-frame emacs-anki--frame)
               (error nil))))))
    (when emacs-anki--minibuffer-active
      (emacs-anki--display-minibuffer-card)
      (emacs-anki--arm-minibuffer-keys))))

(defun emacs-anki--close-graphical-frame ()
  "Delete the GUI review child frame and restore focus to its parent."
  (let ((frame emacs-anki--frame)
        (parent emacs-anki--parent-frame))
    (setq emacs-anki--frame nil)
    (when (frame-live-p frame)
      (condition-case nil
          (delete-frame frame t)
        (error nil))
      ;; Do not steal focus back to the parent when the popup is closing
      ;; because the user deliberately moved focus elsewhere.
      (when (and (frame-live-p parent)
                 (not emacs-anki--closing-for-focus-loss)
                 (not (eq parent frame)))
        (condition-case nil
            (select-frame-set-input-focus parent)
          (error nil))))))

(defun emacs-anki--close-minibuffer ()
  "Clear the echo-area review and remove its keymap."
  (setq emacs-anki--minibuffer-active nil
        emacs-anki--minibuffer-text nil)
  (emacs-anki--disarm-minibuffer-keys)
  (message nil))

(defun emacs-anki--close-display ()
  "Close whichever review popup backend is active."
  (if (display-graphic-p)
      (emacs-anki--close-graphical-frame)
    (emacs-anki--close-minibuffer))
  (emacs-anki--cancel-focus-timer)
  (setq emacs-anki--frame-focused nil
        emacs-anki--display-frame nil
        emacs-anki--card nil
        emacs-anki--revealed nil
        emacs-anki--timer-review nil))

;; ---------------------------------------------------------------------------
;; Review mode and keys

(defvar emacs-anki-review-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "SPC") #'emacs-anki-show-answer)
    (define-key map (kbd "RET") #'emacs-anki-show-answer)
    (define-key map (kbd "1") #'emacs-anki-again)
    (define-key map (kbd "2") #'emacs-anki-hard)
    (define-key map (kbd "3") #'emacs-anki-good)
    (define-key map (kbd "4") #'emacs-anki-easy)
    (define-key map (kbd "g") #'emacs-anki-refresh)
    (define-key map (kbd "q") #'emacs-anki-dismiss)
    (define-key map (kbd "C-v") #'scroll-up-command)
    (define-key map (kbd "M-v") #'scroll-down-command)
    map)
  "Keymap used in the Anki review popup.")

(define-derived-mode emacs-anki-review-mode special-mode "Anki-Review"
  "Major mode for the Anki review popup."
  (setq buffer-read-only t
        cursor-type nil
        mode-line-format nil
        truncate-lines nil
        word-wrap t
        indicate-empty-lines nil
        display-line-numbers nil
        header-line-format nil)
  (setq-local buffer-undo-list t))

(add-hook 'delete-frame-functions #'emacs-anki--on-frame-deleted)

(defvar emacs-anki--focus-tracking-installed nil
  "Non-nil once focus tracking has been added.")

(unless emacs-anki--focus-tracking-installed
  (when (and (boundp 'after-focus-change-function)
             (fboundp 'frame-focus-state))
    (add-function :after after-focus-change-function
                  #'emacs-anki--after-focus-change)
    (setq emacs-anki--focus-tracking-installed t)))

(provide 'emacs-anki)
;;; emacs-anki.el ends here
