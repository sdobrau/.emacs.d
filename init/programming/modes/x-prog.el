;; -*- lexical-binding: t -*-

;;; requirements

;; Browse documentation

(leaf adoc-mode :ensure t :mode "\\.adoc\\'")

(leaf meson-mode :ensure t :mode "\\.meson\\'")

;; Tooltip
(leaf eldoc :ensure t :custom ((eldoc-echo-area-use-multiline-p nil)
                                (eldoc-documentation-strategy . #'eldoc-documentation-compose))
                                (eldoc-idle-delay . 0.5))

(leaf eldoc-box :ensure t)

;; look

(leaf pretty-symbols :ensure t)

(leaf
  symbol-overlay
  :ensure t
  :bind ("M-s h @" . symbol-overlay-put)
  :custom (symbol-overlay-idle-timer . 5))

;; main config

(leaf
  prog-mode
  :preface
  ;; spaces but tabs if available
  ;; https://www.emacswiki.org/emacs/SiteMap

  (defun tempel-setup-capf ()
    ;; Add the Tempel Capf to `completion-at-point-functions'.
    ;; `tempel-expand' only triggers on exact matches. Alternatively use
    ;; `tempel-complete' if you want to see all matches, but then you
    ;; should also configure `tempel-trigger-prefix', such that Tempel
    ;; does not trigger too often when you don't expect it. NOTE: We add
    ;; `tempel-expand' *before* the main programming mode Capf, such
    ;; that it will be tried first.
    (setq-local completion-at-point-functions
      (cons #'tempel-expand completion-at-point-functions)))

  (defun infer-indentation-style ()
    ;; if our source file uses tabs, we use tabs, if spaces spaces, and if
    ;; neither, we use the current indent-tabs-mode
    (let
      (
        (space-count (how-many "^  " (point-min) (point-max)))
        (tab-count (how-many "^\t" (point-min) (point-max))))
      (if (> space-count tab-count)
        (setq indent-tabs-mode nil))
      (if (> tab-count space-count)
        (setq indent-tabs-mode t))))

  (defun sd/prog-mode-hook (&optional arg)
    "My setup for `prog-mode'."
    (interactive "P")
    ;; things to disable
    (ispell-minor-mode -1)
    ;; global in after-init
    (eldoc-box-hover-at-point-mode)
    ;; start
    ;; (flymake-mode)
    ;; COMPLETION AND SNIPPETS
    ;; for completions, add in this order:
    ;; - usual completions provided by `corfu'.
    ;; - file, dabbrev, keyword, symbol using `cape'.
    ;; - snippets from yasnippet using `yasnippet-capf'.
    ;; - snippets from tempel
    (add-to-list 'completion-at-point-functions #'cape-file)
    (add-to-list 'completion-at-point-functions #'cape-dabbrev)
    (add-to-list 'completion-at-point-functions #'cape-keyword)
    (add-to-list 'completion-at-point-functions #'yasnippet-capf)
    (yas-minor-mode)
    (corfu-mode)
    ;; setup capf for tempel
    (tempel-setup-capf)
    ;; others
    (bug-reference-github-set-url-format)
    ;;(electric-operator-mode) buggy?
    ;; visual
    (smart-hungry-delete-add-default-hooks)
    (display-line-numbers-mode)
    (column-number-mode)
    (symbol-overlay-mode)
    (page-break-lines-mode)
    (hl-todo-mode)
    (prettify-symbols-mode)
    (visual-line-mode)
    (push '("<=" . ?≤) prettify-symbols-alist)
    (push '(">=" . ?≥) prettify-symbols-alist)

    (setq-local fill-column 80)
    (display-fill-column-indicator-mode)
    ;; general
    (diff-hl-mode)
    ;;(electric-quote-local-mode -1)
    ;;(electric-pair-local-mode -1)
    ;;(electric-layout-local-mode -1)
    (smart-hungry-delete-default-prog-mode-hook)
    (outline-minor-mode)
    (hs-minor-mode)
    (goto-address-prog-mode)
    (outshine-mode)
    (whitespace-cleanup-mode)
    (ws-butler-mode)
    ;;(move-dup-mode)
    (smartscan-mode)
    (show-paren-mode)
    (auto-fill-mode)
    ;; indentation
    (setq-local indent-tabs-mode nil)
    (infer-indentation-style)
    (electric-indent-local-mode)
    (dtrt-indent-mode)
    (goggles-mode)
    (aggressive-indent-mode)
    (smerge-mode))
  :hook (prog-mode-hook . sd/prog-mode-hook))

(leaf
  ts-fold
  :ensure t
  :custom
  :bind*
  (("C-c <" . ts-fold-close)
    ("C-c >" . ts-fold-open)
    ("C-c M-<" . ts-fold-close-all)
    ("C-c M->" . ts-fold-open-all)))

(leaf apparmor-mode :ensure t)
