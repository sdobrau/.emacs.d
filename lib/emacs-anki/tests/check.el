;;; check.el --- Batch checks for emacs-anki.el -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'emacs-anki)

(unless (fboundp 'emacs-anki-mode)
  (error "emacs-anki-mode is not defined"))
(unless (fboundp 'emacs-anki-review-now)
  (error "emacs-anki-review-now is not defined"))
(unless (equal emacs-anki-deck "work::everything")
  (error "unexpected default deck: %S" emacs-anki-deck))
(unless (file-exists-p emacs-anki-python-file)
  (error "Python bridge not found: %s" emacs-anki-python-file))

(with-temp-buffer
  (emacs-anki-review-mode)
  (dolist (binding '(("SPC" . emacs-anki-show-answer)
                     ("1" . emacs-anki-again)
                     ("3" . emacs-anki-good)
                     ("q" . emacs-anki-dismiss)
                     ("g" . emacs-anki-refresh)))
    (let ((key (car binding))
          (command (cdr binding)))
      (unless (eq (key-binding (kbd key)) command)
        (error "key %s is bound to %S, expected %S"
               key (key-binding (kbd key)) command)))))

;; The terminal review keymap is what makes the echo-area review interactive.
;; It must not bind scrolling keys, which would act on the user's buffer.
(dolist (binding '(("SPC" . emacs-anki-show-answer)
                   ("RET" . emacs-anki-show-answer)
                   ("1" . emacs-anki-again)
                   ("2" . emacs-anki-hard)
                   ("3" . emacs-anki-good)
                   ("4" . emacs-anki-easy)
                   ("q" . emacs-anki-dismiss)
                   ("g" . emacs-anki-refresh)))
  (let ((key (car binding))
        (command (cdr binding)))
    (unless (eq (lookup-key emacs-anki-minibuffer-map (kbd key)) command)
      (error "terminal key %s is bound to %S, expected %S"
             key (lookup-key emacs-anki-minibuffer-map (kbd key)) command))))
(when (lookup-key emacs-anki-minibuffer-map (kbd "C-v"))
  (error "terminal review keymap should not bind C-v"))

;; The terminal keymap must survive review commands but be dropped as soon
;; as the user does something unrelated (including opening the minibuffer).
(let ((emacs-anki--minibuffer-active t))
  (let ((this-command 'emacs-anki-good))
    (unless (emacs-anki--minibuffer-keep-p)
      (error "terminal review keys were dropped after a review command")))
  (let ((this-command 'self-insert-command))
    (when (emacs-anki--minibuffer-keep-p)
      (error "terminal review keys survived an unrelated command"))))

;; Exercise the terminal backend used by `emacs -nw' and batch Emacs: the card
;; is shown in the echo area and review keys are installed temporarily.
(let ((card '((id . 999)
              (deck . "work::everything")
              (model . "Basic")
              (template . "Card 1")
              (question . "Terminal check question")
              (answer . "Terminal check answer")
              (buttons . (((ease . 1) (name . "Again") (next . "<1m"))
                          ((ease . 3) (name . "Good") (next . "10m")))))))
  (unwind-protect
      (progn
        (setq emacs-anki-focus-on-popup t)
        (emacs-anki--show-card card)
        (unless (emacs-anki--display-active-p)
          (error "terminal review did not become active"))
        (unless emacs-anki--minibuffer-active
          (error "terminal review did not mark the echo area active"))
        (unless (string-match-p "Terminal check question"
                                (or emacs-anki--minibuffer-text ""))
          (error "echo area does not contain the question: %S"
                 emacs-anki--minibuffer-text))
        (unless (functionp emacs-anki--minibuffer-exit-function)
          (error "terminal review keys were not installed"))
        (setq emacs-anki--revealed t)
        (emacs-anki--render)
        (unless (string-match-p "Terminal check answer"
                                (or emacs-anki--minibuffer-text ""))
          (error "echo area does not contain the answer: %S"
                 emacs-anki--minibuffer-text))
        (emacs-anki--close-display)
        (when (emacs-anki--display-active-p)
          (error "terminal review did not close"))
        (when emacs-anki--minibuffer-exit-function
          (error "terminal review keymap was not removed")))
    (ignore-errors (emacs-anki--close-display))))

;; A timer-opened popup must close after one answer, while a manual review
;; continues to the next card.
(let* ((card '((id . 1000)
               (deck . "work::everything")
               (model . "Basic")
               (template . "Card 1")
               (question . "Timer card question")
               (answer . "Timer card answer")
               (buttons . (((ease . 1) (name . "Again") (next . "<1m"))
                           ((ease . 3) (name . "Good") (next . "10m"))))))
       (next-card '((id . 1001)
                    (deck . "work::everything")
                    (model . "Basic")
                    (template . "Card 1")
                    (question . "Manual next question")
                    (answer . "Manual next answer")
                    (buttons . (((ease . 1) (name . "Again") (next . "<1m"))
                                ((ease . 3) (name . "Good") (next . "10m"))))))
       (answer-data (list (cons 'ok t) (cons 'card next-card))))
  (unwind-protect
      (progn
        ;; Timer popup: one answer closes the popup and ignores the next card.
        (setq emacs-anki-close-after-timer-review t)
        (emacs-anki--show-card card)
        (setq emacs-anki--timer-review t)
        (emacs-anki--handle-answered answer-data)
        (when (emacs-anki--display-active-p)
          (error "timer review did not close after one answer"))
        (when emacs-anki--timer-review
          (error "timer review flag was not cleared"))

        ;; Manual popup: one answer keeps the popup and shows the next card.
        (emacs-anki--show-card card)
        (setq emacs-anki--timer-review nil)
        (emacs-anki--handle-answered answer-data)
        (unless (emacs-anki--display-active-p)
          (error "manual review closed after one answer"))
        (unless (equal (alist-get 'id emacs-anki--card) 1001)
          (error "manual review did not advance to the next card"))
        (with-current-buffer emacs-anki--buffer
          (unless (string-match-p "Manual next question" (buffer-string))
            (error "manual review did not render the next card"))))
    (setq emacs-anki-close-after-timer-review t)
    (ignore-errors (emacs-anki--close-display))))

;; Externally deleting the popup frame must clear all frame-bound state and
;; cancel any in-flight request.
(let ((emacs-anki--frame (selected-frame))
      (emacs-anki--card '((id . 1)))
      (emacs-anki--revealed t)
      (emacs-anki--timer-review t))
  (emacs-anki--on-frame-deleted emacs-anki--frame)
  (when (or emacs-anki--frame emacs-anki--card
            emacs-anki--revealed emacs-anki--timer-review)
    (error "frame deletion did not clear review state")))

;; Losing focus must close the review rather than leaving it "already open".
(let ((emacs-anki--minibuffer-active t)
      (emacs-anki--display-frame (selected-frame))
      (emacs-anki--frame-focused t)
      (emacs-anki--card '((id . 1) (question . "Focus loss question")))
      (emacs-anki--focus-timer nil))
  (emacs-anki--ensure-buffer)
  (cl-letf (((symbol-function 'frame-focus-state) (lambda (&optional _) nil)))
    (unless (emacs-anki--review-unfocused-p)
      (error "review did not notice that it lost focus"))
    (emacs-anki--maybe-dismiss-on-focus-loss))
  (when (emacs-anki--display-active-p)
    (error "review stayed open after losing focus"))
  (when emacs-anki--frame-focused
    (error "focus flag was not cleared when the review closed")))

;; A focus-in event marks the review as having held focus.
(let ((emacs-anki--minibuffer-active t)
      (emacs-anki--display-frame (selected-frame))
      (emacs-anki--frame-focused nil))
  (unwind-protect
      (progn
        (emacs-anki--ensure-buffer)
        (cl-letf (((symbol-function 'frame-focus-state) (lambda (&optional _) t)))
          (emacs-anki--after-focus-change)
          (unless emacs-anki--frame-focused
            (error "focus-in event did not mark the review as focused"))))
    (ignore-errors (emacs-anki--close-display))))

;; In a terminal, doing something unrelated closes the echo-area review.
(let ((emacs-anki--minibuffer-active t)
      (emacs-anki--display-frame (selected-frame))
      (emacs-anki--frame-focused t)
      (emacs-anki--card '((id . 1) (question . "Unrelated key question"))))
  (unwind-protect
      (progn
        (emacs-anki--ensure-buffer)
        (emacs-anki--render)
        (unless (functionp emacs-anki--minibuffer-exit-function)
          (error "terminal review keys were not armed"))
        (execute-kbd-macro "x")
        (when emacs-anki--minibuffer-active
          (error "unrelated command left the terminal review open")))
    (ignore-errors (emacs-anki--close-display))))

;; The mute setting should be passed to the Python helper as --mute.
(let ((emacs-anki-mute-audio t))
  (unless (member "--mute" (emacs-anki--command '("card")))
    (error "mute is enabled but --mute is missing from the helper command")))
(let ((emacs-anki-mute-audio nil))
  (when (member "--mute" (emacs-anki--command '("card")))
    (error "mute is disabled but --mute is still present")))

;; The interactive deck chooser should update the session variable.
(when (null (commandp 'emacs-anki-set-deck))
  (error "emacs-anki-set-deck is not an interactive command"))
(let ((emacs-anki--deck-choices '("work::everything" "work::everything::sub"))
      (emacs-anki-deck "work::everything"))
  (cl-letf (((symbol-function 'completing-read)
             (lambda (&rest _) "work::everything::sub")))
    (emacs-anki--prompt-for-deck))
  (unless (equal emacs-anki-deck "work::everything::sub")
    (error "deck chooser did not update emacs-anki-deck")))

(princ "elisp checks passed\n")
;;; check.el ends here
