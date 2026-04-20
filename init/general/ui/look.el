;; -*- lexical-binding: t -*-

(set-face-attribute 'font-lock-comment-face nil :slant 'normal)
(set-face-attribute 'font-lock-comment-face nil :slant 'normal)

;; also show fonts in .ttf/otf
(leaf
  show-font
  :if (display-graphic-p)
  :ensure t
  :bind ("C-h C-f" . show-font-list))

;; global, from emacs 31.1
(leaf tty-tip) ;; font lock settings that are reasonably decent

;; (setq-default jit-lock-defer-contextually t ;; syntactically true
;;               jit-lock-stealth-nice 0.3 ;; do in this many time-chunks
;;               jit-lock-stealth-time 0.2 ;; start stealth font after this long
;;               font-lock-multi-line t)

(setq-default what-cursor-show-names t)

(setq-default
  indicate-empty-lines t
  what-cursor-show-names t
  cursor-in-non-selected-windows nil
  text-quoting-style 'straight ;; use 'straight-quote'
  visible-bell nil ;; don't beep

  x-underline-at-descent-line t
  narrow-to-defun-include-comments t
  echo-keystrokes 0
  use-short-answers t
  mode-line-compact t)

;; beacon on switch
;; TODO: built-in 'pulse'
(leaf
  beacon
  :ensure t
  :custom
  ((beacon-blink-when-window-scrolls . t)
    (beacon-blink-when-focused . t)
    (beacon-blink-when-point-moves-horizontally . t)
    (beacon-blink-when-point-moves-vertically . t)
    (beacon-blink-when-window-scrolls . nil)))

(leaf atl-long-lines :ensure t)

;; TODO: temp remove and consider olivetti
;; ;; TODO: refactor center function and hook to package-mode-menu ?
;; (leaf
;;   visual-fill-column
;;   :ensure t
;;   :hook
;;   (
;;     (
;;       (helpful-mode-hook
;;         help-mode-hook
;;         Info-mode-hook
;;         Man-mode-hook
;;         woman-mode-hook
;;         ibuffer-mode-hook
;;         package-menu-mode-hook
;;         noman-mode-hook)
;;       .
;;       (lambda ()
;;         (toggle-word-wrap)
;;         (setq-local fill-column 80)
;;         (visual-fill-column-mode)
;;         (turn-on-visual-line-mode)
;;         (visual-line-fill-column-mode))))
;;   :custom
;;   ((visual-fill-column-fringes-outside-margins . t)
;;     (visual-fill-column-enable-sensible-window-split . t)
;;     (visual-fill-column-width . 80)
;;     (visual-fill-column-center-text . t)
;;     (visual-fill-column-extra-text-width . '(1 . 1))
;;     (visual-fill-column--use-split-window-parameter . t))
;;   :config (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust))
;; ;; * Theming

;; TODO: auto-dark

;; When interactively changing the theme (using M-x load-theme), the current custom
;; theme is not disabled. This often gives weird-looking results; we can advice
;; load-theme to always disable themes currently enabled themes.

(defun disable-custom-themes (theme &optional no-confirm no-enable)
  (mapc 'disable-theme custom-enabled-themes))

(advice-add 'load-theme :before #'disable-custom-themes)

(leaf
  kaolin-themes
  :ensure t
  :require t
  :custom ((kaolin-themes-distinct-parentheses . t) (kaolin-themes-modeline-padded . t))
  :config (load-theme 'kaolin-mono-dark t nil))

;; * Cursor

(blink-cursor-mode 0)

;; try and center without ‘centered-cursor-mode‘.

(setq-default
  scroll-preserve-screen-position t
  scroll-conservatively 0
  maximum-scroll-margin 0.5
  scroll-margin 99999
  auto-window-vscroll nil)

;; fast scrolling
;; better than native
;; also scrolls across images etc.

(leaf
  ultra-scroll
  :if (display-graphic-p)
  :quelpa (ultra-scroll :fetcher github :repo "jdtsmith/ultra-scroll"))

;; * Filling and fringes

(setq-default fringe-mode '(0 .0))

;; * Focusing

(leaf
  dimmer
  :ensure t
  :custom
  ((dimmer-adjustment-mode . :foreground)
    (dimmer-fraction . 0.7)
    (dimmer-use-colorspace . :cielab)
    (dimmer-watch-frame-focus-events . t)
    (dimmer-buffer-exclusion-regexps
      .
      '
      ("^\\*[h|h]elm.*\\*$"
        "^\\*embark.*\\*$ "
        "^\\*vertico*\\*$"
        " \\*\\(lv\\|transient\\)\\*"
        "^\\*Minibuf-[0-9]+\\*"
        "^\\*Minibuf-1+\\*"
        "^.\\*which-key\\*$"
        "^.\\*echo.*\\*"
        "^.\\*corfu.*\\*"
        "^.\\*eldoc-box.*\\*")))

  :config
  ;; (dimmer-configure-helm)
  (dimmer-configure-which-key)
  (dimmer-configure-magit)
  (if (display-graphic-p)
    (dimmer-configure-posframe))
  (add-to-list 'dimmer-buffer-exclusion-predicates #'window-minibuffer-p)
  (dimmer-configure-org))

(leaf
  focus
  :ensure t
  :custom
  (focus-mode-to-thing
    .
    '
    ((prog-mode . defun)
      (text-mode . paragraph)
      (eww-mode . paragraph)
      (org-mode . paragraph)
      (org-src-mode . defun)
      (outline-mode . defun)
      (outline-mode . defun)
      (Info-mode . paragraph)
      (persistent-scratch-mode . paragraph))))

;; * Mode-line
(setq-default mode-line-compact t)

;; ;; extra echo
;; ;; TODO: tshoot/wtf
;; (leaf
;;   echo-bar
;;   :ensure t
;;   :disabled t
;;   :custom
;;   ((echo-bar-update-interval . 60)
;;     (echo-bar-timer . 60)
;;     (echo-bar-format
;;       . '
;;       ;; TODO: wrap with err handling
;;       (:eval
;;         (concat
;;           (if (executable-find "notmuch")
;;             (concat
;;               "@"
;;               (
;;                 (shell-command-to-string
;;                   "notmuch count tag:unread | tr --delete '\n'")
;;                 " | ")))
;;           ;; (cl-destructuring-bind
;;           ;;   (tr fr ts fs)
;;           ;;   (mapcar #'(lambda (n) (/ n 1024)) (memory-info))
;;           ;;   (format "tr:%s fr:%s ts:%s fs:%s" tr fr ts fs))
;;           (format-time-string "%b %d | %H:%M"))))))

(leaf minions :ensure t :hook (minions-mode-hook . force-mode-line-update))

;; disable for the moment
;; (leaf mode-line-extras
;;   :require t
;;   :custom (mode-line-compact . t))

;; (:eval (breadcrumb-imenu-crumbs))
;; (:eval (breadcrumb-project-crumbs))
(leaf breadcrumb :ensure t)

;; disable
;; (leaf
;;   which-func
;;   :ensure t
;;   :custom
;;   (which-func-modes
;;     .
;;     '
;;     (emacs-lisp-mode
;;       c-mode
;;       c++-mode
;;       objc-mode
;;       perl-mode
;;       cperl-mode
;;       python-mode
;;       makefile-mode
;;       sh-mode
;;       fortran-mode
;;       f90-mode
;;       ada-mode
;;       diff-mode))
;;   (which-func-non-auto-modes . '(eww-mode org-mode))
;;   (which-func-display . 'mode-and-header)
;;   (which-func-update-delay . 1.0))

;; * Little & Extra

(defalias 'yes-or-no-p 'y-or-n-p)

(leaf page-break-lines :ensure t)

(leaf alert :ensure t :commands alert :custom (alert-default-style . 'message))

(leaf
  default-text-scale
  :ensure t
  :bind
  (("C-x C--" . nil) ;; text-scale-adjust
    ("C-x C--" . default-text-scale-decrease)
    ("C-x C-=" . nil) ;; text-scale-adjust
    ("C-x C-=" . default-text-scale-increase) ("C-x C-M--" . viewing-2))
  :custom ((default-text-scale-amount . 5) (text-scale-mode-step . 1.1)))

(leaf line-spacing :custom (line-spacing . 0.0))

(leaf show-eol :ensure t)

(setq-default tab-bar-show nil)

(leaf
  indent-bars
  :ensure t
  :custom
  ((indent-bars-no-descend-lists . t)
    (indent-bars-treesit-suppot . t)
    (indent-bars-tree-ignore-blank-lines-types '("module"))
    (indent-bars-treesit-scope
      .
      '
      (
        (python
          function_definition
          class_definition
          for_statement
          if_statement
          with_statement
          while_statement))))
  ;; Note: wrap may not be needed if no-descend-list is enough
  ;;(indent-bars-treesit-wrap '((python argument_list parameters ; for python, as an example
  ;;             list list_comprehension
  ;;             dictionary dictionary_comprehension
  ;;             parenthesized_expression subscript)))
  :config (require 'indent-bars-ts))

;;; pulse

(leaf goggles :ensure t :custom (goggles-pulse . t))

;;; crosshair

;; requires vline, hl-line+ (lib) and col-highlight (lib)

(leaf vline :ensure t)

(leaf col-highlight)

(leaf
  crosshairs
  :bind ("C-x f |" . crosshairs-mode)
  :config (set-face-attribute 'col-highlight nil :inherit 'hl-line :background))
