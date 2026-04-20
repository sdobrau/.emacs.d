;; -*- lexical-binding: t -*-

(leaf bookmark
  :custom ((bookmark-fontify . nil)
           ;; save bookmark file whenever bookmarks are modified
           (bookmark-save-flag . 1)
           (bookmark-version-control . t)
           (bookmark-automatically-show-annotations . t))
  :config
  (setq bookmark-default-file
        ;; behaviour
        (no-littering-expand-var-file-name "bookmark-default.el")))
