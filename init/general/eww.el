;; -*- lexical-binding: t -*-

;; First, rendering library
(leaf
  shr
  :custom
  ((shr-max-width . 80)
    (shr-max-image-proportion . 0.7)
    (shr-width . 80) ;
    ;; don’t render aria-hidden=true tags
    (shr-discard-aria-hidden . t)
    (shr-image-animate . nil) ; don’t animate gifs!
    (shr-use-colors . nil) ; don’t use colors! too flashy!
    (shr-cookie-policy . t) ;; for google search, etc
    (shr-folding-mode . t)
    (shr-offer-extend-specpdl . nil)
    (url-privacy-level . 'none)
    (browse-url-new-window-flag . nil) ;; never use a new window
    (url-automatic-caching . t)
    (browse-url-browser-function . #'eww-browse-url)))

(leaf
  dnt
  :quelpa (dnt :fetcher codeberg :repo "emacs-weirdware/dnt")
  ;; TODO: lazy
  :require t
  :config (dnt-browse-url) (dnt-shr))
;;(dnt-elfeed))

;; loaded when running eww
(leaf shr-extras)

;; TODO: test
;; C-u -> open in chromium
(leaf
  open-web
  :quelpa (open-web :fetcher github :repo "larsmagne/open-web.el")
  :require t
  :custom
  ((open-web-browser . #'browse-url-chromium)
    (open-web-methods
      .
      '(eww-browse-url open-web-new-window open-web-same-window)))
  :config
  (setq
    browse-url-browser-function #'open-web
    browse-url-secondary-browser-function #'open-web))

;; Then, browser
(leaf
  eww
  ;; TODO: lazy
  :require t
  :commands eww
  :preface
  (defun sd/eww-visit-clip-link (&optional arg)
    "Visit link in clipboard using EWW."
    (interactive "P")
    (eww (substring-no-properties (pop kill-ring))))
  (defun sd/eww-up-to-w3m (&optional arg)
    "Jump up to w3m see if the page works"
    (interactive "P")
    (w3m (eww-current-url)))
  (defun shrface-eww-setup ()
    (unless shrface-toggle-bullets
      (shrface-regexp)
      (setq-local imenu-create-index-function #'shrface-imenu-get-tree))
    ;; (add-function :before-until (local 'eldoc-documentation-function) #'paw-get-eldoc-note)
    ;; workaround to show annotations in eww
    (when (bound-and-true-p paw-annotation-mode)
      (paw-clear-annotation-overlay)
      (paw-show-all-annotations)
      (if paw-annotation-show-wordlists-words-p
        (paw-focus-find-words :wordlist t))
      (if paw-annotation-show-unknown-words-p
        (paw-focus-find-words))))

  (defun shrface-eww-advice (orig-fun &rest args)
    (require 'eww)
    (let
      (
        (shrface-org nil)
        (shr-bullet (concat (char-to-string shrface-item-bullet) " "))
        (shr-table-vertical-line "|")
        (shr-width 65)
        (shr-indentation 0)
        (shr-external-rendering-functions
          (append
            '
            ((title . eww-tag-title)
              (form . eww-tag-form)
              (input . eww-tag-input)
              (button . eww-form-submit)
              (textarea . eww-tag-textarea)
              (select . eww-tag-select)
              (link . eww-tag-link)
              (meta . eww-tag-meta)
              ;; (a . eww-tag-a)
              (code . shrface-tag-code)
              (pre . shr-tag-pre-highlight))
            shrface-supported-faces-alist))
        (shrface-toggle-bullets nil)
        (shrface-href-versatile t)
        (shr-use-fonts nil))
      (apply orig-fun args)))

  (defun sd/eww-hook ()
    (sd/remove-electrics)
    ;;(eldoc-overlay-mode -1)
    (setq-local fill-column 80)
    ;; to take new column-width for nice filling
    ;; when changing window size
    )
  (defun sd/eww-after-render-hook (&optional arg)
    ;; (org-indent-mode)
    (eldoc-mode)
    (eldoc-box-hover-at-point-mode)
    (shrface-eww-setup)
    ;;(eww-readable)
    ;; TODO: make this nicer
    ;; (add-hook 'window-configuration-change-hook #'(lambda () (eww-reload t))
    ;;   nil
    ;;   t)
    (shrface-mode))
  :hook
  ((eww-mode-hook . sd/eww-hook)
    (eww-after-render-hook . sd/eww-after-render-hook))
  :bind
  (("M-s C-M-w" . sd/eww-visit-clip-link)
    (:eww-mode-map
      (("W" . sd/eww-up-to-w3m)
        ("C-M-a" . backward-paragraph)
        ("C-M-e" . forward-paragraph)
        ("M-RET" . eww-open-in-new-buffer)
        ("h" . eww-list-histories)
        ("v" . nil) ;; to stop accidental hitting of 'eww-view-source'
        ("r" . eww-reload)
        ("g" . consult-imenu)
        ("i" . consult-imenu)
        ;; ("." . sd/browse-chrome)
        ("C-q" . kill-this-buffer)
        (";" . eww-forward-url) ;; after l
        ("n" . shr-next-link)
        ("p" . shr-previous-link)
        ("," . eww-reload)))
    (:dired-mode-map (("e" . eww-open-file))))
  :custom
  ;; don't delete history?
  ((eww-before-browse-history-function . 'ignore)
    (eww-header-line-format . nil)
    (eww-history-limit . 99999)
    (eww-restore-desktop . t)
    ;; tab support
    (browse-url-new-window-flag . t)
    (eww-browse-url-new-window-is-tab . nil)
    (eww-desktop-remove-duplicates . t)
    (eww-auto-rename-buffer . nil) ;; covered by 'epithet'
    (eww-form-checkbox-selected-symbol . "[x]")
    (eww-form-checkbox-symbol . "[ ]")
    ;; TODO: fix
    (eww-search-prefix . "https://www.google.com/search?ion=1&q="))
  :config
  ;; for shrface
  (require 'shrface)
  (advice-add 'eww-display-html :around #'shrface-eww-advice)
  (defun mw-start-eww-for-url (plist)
    "Raise Emacs and call eww with the url in PLIST."
    (eww (plist-get plist :url))
    nil)

  (setq browse-url-secondary-browser-function 'browse-url-default-browser)

  ;; make button/form/input styling consistent with theme
  (mapc
    (lambda (x)
      (set-face-attribute x nil
        :foreground (face-attribute 'custom-button-unraised :foreground)
        :background (face-attribute 'custom-button-unraised :background)))

    '
    (eww-form-file
      eww-form-checkbox
      eww-form-select
      eww-form-submit
      eww-form-text
      eww-form-textarea))

  (setq eww-download-directory
    (no-littering-expand-var-file-name "eww/downloads/"))
  ;; inhibit images by default
  ;; use my/eww-toggle-images to toggle them back on (bound to i)
  (setq-default shr-inhibit-images t)
  (setq eww-bookmarks-directory
    (no-littering-expand-var-file-name "eww/bookmarks/"))
  :if (executable-find "rdrview")
  :custom
  ;; TODO: filter for domain/s
  ;; (eww-retrieve-command
  ;;   .
  ;;   '
  ;;   ("rdrview"
  ;;     "-H"
  ;;     "-E"
  ;;     "utf-8"
  ;;     "-P"
  ;;     "-A"
  ;;     "Firefox"
  ;;     "-T"
  ;;     "title,sitename,url,body,byline,excerpt"))
  )

(leaf
  eww-extras
  ;; TODO: lazy
  :require t
  :bind (:eww-mode-map (("D" . sd/h2o-current-eww-url))))

;; (leaf
;;   eww-plz
;;   :quelpa (eww-plz :fetcher github :repo "9viz/eww-plz.el")
;;   :commands eww)
