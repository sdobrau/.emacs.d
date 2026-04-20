;; -*- lexical-binding: t -*-

;; Save various rings and histories in =~/.config/emacs/data/savehist=.

(leaf
  savehist
  :require t
  :custom
  ((history-length . 100) ;; t is way too large
    (savehist-save-minibuffer-history . t)
    ;; what other variables to save?
    (savehist-additional-variables
      .
      '
      (search-ring
        regexp-search-ring
        ;; kill-ring ;; don’t save
        comint-input-ring
        sr-history-registry
        file-name-history
        org-mark-ring
        dogears-list
        tablist-name-filter
        winner-ring-alist
        mark-ring
        eshell-history-ring
        kmacro-ring)))
  :config
  (setq savehist-file (no-littering-expand-var-file-name "savehist"))
  (savehist-mode 1))

;; Save point history. Abbreviate file-names for confidentiality and make
;; backups of the master save-place file.
(leaf
  save-place
  :ensure nil
  :custom
  ((save-place-abbreviate-file-names . t)
    (save-place-limit . nil)
    (save-place-version-control . t))
  :config (setq save-place-file (no-littering-expand-var-file-name "save-place.el")))
