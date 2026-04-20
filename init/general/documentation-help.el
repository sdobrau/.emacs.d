;; -*- lexical-binding: t -*-

;;; emacs native

(leaf shortdoc :bind ("C-h M-s" . shortdoc-display-group))

(leaf
  info
  :custom (info-lookup-other-window-flag . t)
  :bind (:Info-mode-map (("M-p" . backward-paragraph) ("M-n" . forward-paragraph))))

;; Better help buffer
(leaf
  helpful
  :ensure t
  :bind
  (([remap describe-function] . helpful-callable)
    ([remap describe-variable] . helpful-variable)
    ([remap describe-key] . helpful-key)
    ([remap describe-symbol] . helpful-symbol)
    ("C-c C-d" . helpful-at-point)
    (:helpful-mode-map (("q" . helpful-kill-buffers) ("g" . helpful-update))))
  :custom
  ((helpful-switch-buffer-function . #'pop-to-buffer)
    (help-window-select . t)
    (apropos-do-all . t))) ;; more extensively)

(leaf
  elisp-demos
  :ensure t
  :after helpful
  :config (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

;;; the mans and unix

(leaf
  man
  ;; TODO: lazy load
  :require t
  :commands man consult-man smartscan-mode
  :hook (Man-mode-hook . (lambda () (visual-fill-column-mode -1)))
  :custom
  ((Man-notify-method . 'thrifty) ;; in pop-up frame
    (Man-width . nil))
  :bind (:Man-mode-map (("g" . nil) ("g" . consult-imenu))))

;; alternative
(leaf
  woman
  ;; TODO lazy load
  :require t
  :custom
  ((woman-fill-frame . t)
    (woman-fill-column . 80)
    (woman-imenu . t)
    (woman-cache-level . 3))
  :bind (("C-h /" . woman) (:woman-mode-map (("g" . consult-imenu))))
  :hook (woman-mode-hook . (lambda () (visual-fill-column-mode -1)))
  :config
  (setq woman-cache-filename
    (no-littering-expand-var-file-name "woman-cache.el")))

;; cli -h|--help
(leaf
  noman
  :ensure t
  :bind
  (("C-h n" . noman)
    (:noman-mode-map (("n" . Man-next-section) ("p" . Man-previous-section))))
  :custom ((noman-reuse-buffers . nil)))

;;; online

(leaf
  howdoyou
  :if (executable-find "howdoi")
  :ensure t
  :bind ("C-h C-t" . howdoyou-query)
  :custom
  ((howdoyou-switch-to-answer-buffer . t)
    (howdoyou-number-of-answers . 10)
    (howdoyou-number-of-answers . 10)))

(leaf
  tldr
  :ensure t
  :bind ("C-h t" . tldr)
  :custom (tldr-use-word-at-point . t)
  ;; update if not existent. just on first
  :config
  (if (not (file-directory-p (concat user-emacs-directory "/data/tldr")))
    (tldr-update-docs)))

;; TODO: :pkg set-up what is this?
(leaf
  foldoc
  :disabled t
  :config (setq foldoc-file (no-littering-expand-var-file-name "foldoc")))

;;; Other

(leaf posix-manual :ensure t :bind ("C-h #" . posix-manual-entry))

;; Browse rfc-docs inside Emacs
(leaf
  rfc-mode
  :ensure t
  :custom
  ((rfc-mode-use-original-buffer-names . t)
    (rfc-mode-browse-input-function . 'completing-read))

  :bind
  (("C-h _" . rfc-mode-browse)
    (:rfc-mode-map
      (("M-n" . rfc-mode-forward-page) ("M-p" . rfc-mode-backward-page)))))

(leaf
  arxiv-mode
  :ensure t
  :custom ((arxiv-use-variable-pitch . nil) (arxiv-use-variable-pitch . nil))
  :bind (("M-s s a" . arxiv-search) ("M-s s M-a" . arxiv-complex-search))
  :config
  (setq arxiv-default-download-folder
    (no-littering-expand-var-file-name "arxiv/")))

;;; little helpers

;; TODO: bind to offline dictionary
(leaf
  define-word
  :ensure t
  :bind (("M-s w" . define-word) ("M-s C-w" . define-word-at-point)))
