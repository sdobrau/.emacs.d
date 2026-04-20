;; -*- lexical-binding: t -*-

;; tempel

(leaf
  tempel
  :ensure t
  :require t
  :bind
  ((:prog-mode-map (("C-c t t" . tempel-complete) ("C-o" . tempel-expand)))
    (:text-mode-map (("C-c t t" . tempel-complete) ("C-o" . tempel-expand)))
    (:tempel-map
      (("TAB" . tempel-next)
        ("<backtab>" . tempel-previous)
        ("C-g" . tempel-abort)
        ("RET" . tempel-done))))
  :config
  ;; .emacs.d/config/templates/*/*.eld"
  (setq-default tempel-path
    (no-littering-expand-etc-file-name "templates/*/*.eld")))

(leaf
  tempel-snippets
  :quelpa
  (tempel-snippets
    :fetcher github
    :repo "gs-101/tempel-snippets"
    ;; fetch snippets folder
    :files ("*")))
;; yasnippet for everything else

(leaf
  yasnippet
  :quelpa t
  :preface
  (defun sd/snippet-mode-hook ()
    (interactive "P")
    ;; TODO: enable major mode of parent directory when writing
    ;; snippets
    ;; TODO: add good default values (respect indent etc)
    (sd/remove-electrics))

  :hook (snippet-mode-hook . sd/snippet-mode-hook)
  :bind
  (("C-c t y n" . yas-new-snippet)
    ("C-c t y r" . yas-reload-all)
    ("C-c t y e" . yas-expand))
  :config
  (add-hook
    'snippet-mode-hook
    (lambda () (setq-local require-final-newline nil)))
  (defcustom yas-new-snippet-default
    "\
# -*- mode: snippet -*-
# name: $1
# key: ${2:${1:$(yas--key-from-desc yas-text)}}
# expand-env: ((yas-indent-line 'fixed) (yas-wrap-around-region 'nil))
# --
$0`(yas-escape-text yas-selected-text)`"
    "Default snippet to use when creating a new snippet.
If nil, don't use any snippet."
    :type 'string))

(leaf
  yasnippet-extras
  :hook
  ((snippet-mode-hook . koek-ws/disable-final-empty-line)
    (post-command-hook . yas-try-expanding-auto-snippets)))

;; TODO: check if dir exists. if not (new start) then move from package dir
(leaf yasnippet-snippets :ensure t)

(leaf
  consult-yasnippet
  :after consult
  :ensure t
  :bind ("C-c C-t" . consult-yasnippet))

;; TODO: make work
;; (leaf yasnippet-capf
;;   :require t
;;   :quelpa (yasnippet-capf
;;            :fetcher github
;;            :repo "elken/yasnippet-capf")
;;   :custom (yasnippet-capf-lookup-by . 'name)
;;   :config (add-to-list 'completion-at-point-functions #'yasnippet-capf))

(leaf
  auto-yasnippet
  :ensure t
  :config (setq aya-persist-snippets-dir (concat user-emacs-directory "data/snippets"))
  :bind
  (("C-c s a c" . aya-create)
    ("C-c s a e" . aya-expand)
    ("C-c s a h" . aya-expand-from-history)
    ("C-c s a d" . aya-delete-from-history)
    ("C-c s a n" . aya-next-in-history)
    ("C-c s a p" . aya-previous-in-history)
    ("C-c s a x" . aya-persist-snippet)
    ("C-c s a o" . aya-open-line)))

;; yankpad for org

(leaf
  yankpad
  :ensure t
  :custom (yankpad-file . "~/org/yankpad.org")
  :bind (("C-c t o C-<tab>" . yankpad-expand) ("C-c t o o" . yankpad-insert)))
