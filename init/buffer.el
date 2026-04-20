;; -*- lexical-binding: t -*-

;; Don't ask for confirmation when reverting a buffer
(setq-default
  revert-without-query '(".*")
  whitespace-line-column 120
  require-final-newline t)

(leaf
  ibuffer
  :hook
  (ibuffer-mode-hook
    .
    (lambda () (ibuffer-switch-to-saved-filter-groups "default")))
  :custom
  ((ibuffer-default-display-maybe-show-predicates . nil)
    (ibuffer-expert . t) ;; don’t warn of dangerous operations
    ;; don’t show empty filter groups
    (ibuffer-show-empty-filter-groups . nil)
    (ibuffer-shrink-to-minimum-size . t)
    (ibuffer-user-other-window . t)
    ;; redguardtoo
    (ibuffer-saved-filter-groups
      .
      '
      (
        ("default"
          ("term"
            (or (mode . term-mode)
              (mode . eshell-mode)
              (mode . vterm-mode)
              (mode . shell-mode)
              (mode . compilation-mode)))
          ("code"
            (or (mode . emacs-lisp-mode)
              (mode . cperl-mode)
              (mode . c-mode)
              (mode . java-mode)
              (mode . idl-mode)
              (mode . web-mode)
              (mode . lisp-mode)
              (mode . js2-mode)
              (mode . c++-mode)
              (mode . lua-mode)
              (mode . cmake-mode)
              (mode . ruby-mode)
              (mode . css-mode)
              (mode . objc-mode)
              (mode . sql-mode)
              (mode . python-mode)
              (mode . php-mode)
              (mode . sh-mode)
              (mode . json-mode)
              (mode . scala-mode)
              (mode . go-mode)
              (mode . erlang-mode)))

          ("dired" (or (mode . dired-mode) (mode . sr-mode)))

          ("erc" (mode . erc-mode))

          ("planner"
            (or (name . "^\\*calendar\\*$")
              (name . "^diary$")
              (mode . muse-mode)
              (mode . org-agenda-mode)))

          ("emacs" (or (name . "^\\*scratch\\*$") (name . "^\\*messages\\*$")))

          ("gnus"
            (or (mode . message-mode)
              (mode . bbdb-mode)
              (mode . mail-mode)
              (mode . gnus-group-mode)
              (mode . gnus-summary-mode)
              (mode . gnus-article-mode)
              (name . "^\\.bbdb$")
              (name . "^\\.newsrc-dribble")))
          ("doc"
            (or (mode . Info-mode)
              (mode . woman-mode)
              (mode . Man-mode)
              (mode . noman-mode)
              (mode . eww-mode)
              (mode . nov-mode)
              (mode . helpful-mode)
              (mode . help-mode)
              (mode . org-mode)))))))

  :bind
  (("C-x C-b" . ibuffer)
    (:ibuffer-mode-map
      (("M-o" . nil)))) ;; ibuffer-visit-buffer-1-window conflict with M-o

  :config
  (setq ibuffer-formats
    '
    (
      (mark
        modified
        read-only
        " "
        (name 40 40 :left :elide)
        " "
        (size 10 -1 :right)
        " "
        (mode 16 16 :left :elide)
        " "
        filename)
      (mark " " (name 16 -1) " " filename))))

(leaf ibuffer-extras :commands ibuffer)

(setq large-file-warning-threshold 500000000)

(leaf
  auto-revert-mode
  :bind ("C-x f _" . auto-revert-tail-mode)
  :custom
  ((auto-revert-interval . 999999999) ;;  sec between checks
    (auto-revert-verbose . nil))
  :config (auto-revert-mode -1) (global-auto-revert-mode -1))

(leaf
  uniquify
  :custom
  ( ;; file/dirb/dirc + file/dirc/dird =
    ;; file/dirb/dirc/,
    ;; file/dirc/dird/ buffer names
    (uniquify-buffer-name-style . 'forward)
    ;; strip common dir suffix from unique buffers
    (uniquify-strip-common-suffix . t)
    ;; rename buffers after uniq buffer killed
    (uniquify-after-kill-buffer-p . t)
    ;; buffer names which should be uniquified
    (uniquify-ignore-buffers-re . "^\\*")
    ;; separator for uniquified buffers
    (uniquify-separator . "/")))

;; helpful functions:
;;
;; =C-x b=: switch to a buffer, listing only buffers with the same mode as the
;;   current buffer. (=jao=)
;;
;; =C-x o=: switch to the previous buffer of this window. repeated
;;   invocations return to the initial buffer. (=malb=)
;;
;; =C-x k= kills the buffer by default, =c-u c-x -k= prompts for a buffer.

(leaf buffer :bind (("M-<" . previous-buffer) ("M->" . next-buffer)))

(leaf
  buffer-extras
  :bind
  (("C-x k" . ol/kill-buffer-dwim)
    ("C-x C-M-s" . daanturo-save-unsaved-buffers-with-files)
    ("C-x M-s" . daanturo-save-buffer-no-hook)
    ("C-x M-b" . switch-to-buffer-other-window)
    ;; fast switch
    ("C-x C-z" . pop-to-buffer)
    ("C-x B" . jao-buffer-same-mode)
    ("C-x o" . malb/switch-to-previous-buffer)))

;; TODO: try :pkg 'shortcuts'

;; TODO: what?
(leaf b)

;; List-oriented buffer operations
(leaf m-buffer :ensure t)

;; Unobtrusively remove whitespace
(leaf ws-butler :ensure t)

(leaf buffer-sets :ensure t :require ibuffer)

;; TODO: test and tweak
;; TODO: add erc
(leaf
  buffer-terminator
  :ensure t
  :custom
  ((buffer-terminator-verbose . t)
    (buffer-terminator-rules-alist
      .
      '
      ((keep-buffer-property . special)
        (keep-buffer-property . process)
        (keep-buffer-property . visible)
        (kill-buffer-property . inactive)
        (kill-buffer-major-modes . helpful-mode)
        (kill-buffer-major-modes . help-mode))))
  :config
  (setq
    buffer-terminator-inactivity-timeout (* 3600 8)
    buffer-terminator-interval (* 3600 2)))
