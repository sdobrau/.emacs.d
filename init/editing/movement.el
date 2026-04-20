;; -*- lexical-binding: t -*-

;; the register

(leaf register :custom (register-use-preview . 'never))

;; TODO: change key not compat with ubuntu M-1 M-2 etc
;; 1. register for quick - ctrl
(leaf
  register-quicknav
  :bind
  (("M-1" . register-quicknav-prev-register)
    ("M-2" . register-quicknav-next-register)
    ("M-3" . register-quicknav-point-to-unused-register)
    ("C-x r C-c" . register-quicknav-clear-current-register)))

;; 2. bookmark for bookmark-wide - alt
;; TODO: replace with harpoon?
;; https://github.com/otavioschwanck/harpoon.el

(leaf
  bookmark-in-project
  :ensure t
  :bind
  (("M-)" . bookmark-in-project-jump-next)
    ("M-(" . bookmark-in-project-jump-previous)
    ("M-0" . bookmark-in-project-toggle)
    ("M-9" . bookmark-in-project-jump)))

;; 3. torus for most advanced (still project) - shift
(leaf
  torus
  :ensure t
  :custom
  ((torus-history-maximum-elements . 800)
    (torus-load-on-startup . t)
    (torus-save-on-exit . t)
    (torus-maximum-horizontal-split . 6)
    (torus-maximum-vertical-split . 4)
    (torus-dirname . "~/.emacs.d/torus")
    (torus-autowrite-file . "~/.emacs.d/torus/torus.el")
    (torus-autoread-file . "~/.emacs.d/torus/torus.el"))
  :bind
  (
    (("S-<up>" . torus-add-location)
      ("S-<down>" . torus-switch-location)
      ("S-<left>" . torus-previous-location)
      ("S-<right>" . torus-next-location)
      ("C-c C-<up>" . torus-add-circle)
      ("C-c C-<down>" . torus-switch-circle)
      ("C-c C-<left>" . torus-previous-circle)
      ("C-c C-<right>" . torus-next-circle)
      ("C-c S-<up>" . torus-add-torus)
      ("C-c S-<down>" . torus-switch-torus)
      ("C-c S-<left>" . torus-previous-torus)
      ("C-c S-<right>" . torus-next-torus)
      ("C-x M-t i" . torus-info))))

;; 4. buffer-ring for buffer tori - C-c C-b
(leaf
  buffer-ring
  :ensure t
  :bind
  (:buffer-ring-mode-map
    (("C-c C-b <up>" . buffer-ring-add)
      ("C-c C-b <down>" . buffer-ring-drop-buffer)
      ("C-c C-b <left>" . buffer-ring-prev-buffer)
      ("C-c C-b <right>" . buffer-ring-next-buffer)
      ("C-c C-b S-<down>" . buffer-ring-torus-switch-to-ring))))

(setq-default line-move-visual nil)

(leaf visible-mark :ensure t)

(leaf
  rings
  :custom
  ((global-mark-ring-max . 15000)
    (mark-ring-max . 1500)
    (kill-ring-max . 1500)
    (kill-do-not-save-duplicates . t)))

;; Pop mark again after being popped on subsequent c-spc
;; (setq set-mark-command-repeat-pop t)

;; Mark-ring movement in both directions.
;;
;; =C--=: toggle forward direction.
;; =C-u SPC x2=: reverse direction.
;; =C-SPC=: go towards direction.

(leaf
  bd-set-mark
  :quelpa (bd-set-mark :fetcher github :repo "lewang/bd-set-mark")
  :bind ([remap set-mark-command] . bd-set-mark-command))

;; When popping mark, skip consecutive identical marks # koekelas
;; (define-advice pop-to-mark-command (:around (f) koek-mark/ensure-move)
;; (let ((start (point))
;; (n (length mark-ring)))
;; ;; Move point to current mark
;; (funcall f)
;; ;; Move point to previous marks in mark ring
;; (while (and (= (point) start) (> n 0))
;; (funcall f)
;; (setq n (1- n)))))

;; The following keys modify the selection:
;;
;; 1. @: append selection to previous kill and exit. for example, m-w d @ will
;;    append current function to last kill.
;; 2. C-w: kill selection and exit
;; 3. +, - and 1..9: expand/shrink selection
;; 4. 0 shrink the selection to the initial size i.e. before any expansion
;; 5. SPC: cycle through things in easy-kill-alist
;; 6. C-SPC: turn selection into an active region
;; 7. C-g: abort
;; 8. ?: help

(leaf
  movement-extras
  :bind
  (
    (:prog-mode-map
      (([remap next-line] . zk-phi-next-line)
        ([remap previous-line] . zk-phi-previous-line)))
    (:text-mode-map
      (([remap next-line] . zk-phi-next-line)
        ([remap previous-line] . zk-phi-previous-line)))
    ;; 'python-mode-map' void error when loading this
    ;; do i have to?
    ;; (:python-mode-map
    ;;  (([remap next-line] . zk-phi-next-line)
    ;;   ([remap previous-line] . zk-phi-previous-line)))
    ;; only forward, backward is default.
    ("M-f" . koek-mtn/next-word)))

;; =M-del=: delete subword.
;; =C-m-<backspace>=: delete superword.

(leaf subword-extras :bind (("C-M-<backspace>" . backward-kill-superword)))

;; TODO: is-in-stash-p ignored functions
;; TODO: see how try-vc works, does remember work onto every dir ?
(leaf
  dogears
  :disabled t
  :ensure t
  :preface
  :bind (("C-<" . dogears-back) ("C->" . dogears-forward) ("M-g d" . dogears-list))
  :custom ((dogears-idle . 20) (dogears-limit . 50))
  :config
  ;; https://github.com/alphapapa/dogears.el/issues/4
  (add-to-list 'dogears-ignore-modes 'eww-mode)
  (add-to-list 'dogears-ignore-modes 'org-mode))

(leaf goto-address :ensure nil :hook (global-goto-address-mode))

;; https://www.yahoo.com
;; https://www.google.com

(leaf
  goto-char-preview
  :ensure t
  :bind (("M-g c" . nil) ("M-g c" . goto-char-preview)))

(leaf
  goto-line-preview
  :ensure t
  :bind (("M-g g" . nil) ("M-g g" . goto-line-preview)))

(leaf
  ace-jump-mode
  :ensure t
  :bind ("C-M-j" . ace-jump-char-mode)
  :custom (ace-jump-mode-gray-background . nil))

;; for multiple types of links anywhere
(leaf
  link-hint
  :ensure t
  :bind
  (("C-c C-_" . link-hint-open-link) ;; C-c C-/
    ("C-c /" . link-hint-open-link-at-point)
    (:eww-mode-map
      (("F" . link-hint-open-link) ("f" . link-hint-open-link-at-point)))
    (:nov-mode-map
      (("F" . link-hint-open-link) ("f" . link-hint-open-link-at-point))))
  :custom ((link-hint-message . nil) (link-hint-restore . t)))

(leaf
  ace-jump-zap
  :ensure t
  :custom (zzz-to-char-reach . 800)
  :bind ("M-z" . ace-jump-zap-up-to-char-dwim))

(leaf
  smartscan
  :ensure t
  :bind
  (
    (:special-mode-map
      (("M-n" . smartscan-symbol-go-forward)
        ("M-p" . smartscan-symbol-go-backward)))
    (:Man-mode-map
      (("M-n" . smartscan-symbol-go-forward)
        ("M-p" . smartscan-symbol-go-backward))))

  :custom ((smartscan-symbol-selector . "symbol") (smartscan-use-extended-syntax . t)))
(leaf smart-mark :ensure t)

(leaf
  goto-chg
  :ensure t
  :bind (("M-g l" . goto-last-change) ("M-g C-l" . goto-last-change-reverse)))

;; some binds
;; TODO: lazy

(leaf beginend :ensure t)

(leaf
  simple
  :bind (("C-x f 2" . end-of-buffer) ("C-x f 1" . beginning-of-buffer)))

(leaf
  spatial-navigate
  :ensure t
  :bind
  (:prog-mode-map
    (("M-K" . spatial-navigate-backward-vertical-bar)
      ("M-J" . spatial-navigate-forward-vertical-bar)
      ("M-H" . spatial-navigate-backward-horizontal-bar)
      ("M-L" . spatial-navigate-forward-horizontal-bar))))

(leaf
  scroll
  :hook
  ((eshell-mode-hook erc-mode-hook telega-chat-mode-hook)
    .
    (lambda ()
      (setq-local scroll-margin 0)
      (setq-local scroll-up-aggressively 0.0))))

(setq-default
  scroll-conservatively 10000
  maximum-scroll-margin 0.5
  scroll-error-top-bottom nil
  ;; Preserve screen point position when scrolling
  scroll-preserve-screen-position t
  fast-but-imprecise-scrolling t
  ;; counter emacs sluggishness when scrolling very fast
  scroll-margin 5)
