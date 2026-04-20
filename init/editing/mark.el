;; -*- lexical-binding: t -*-

(setq-default set-mark-command-repeat-pop t)

(leaf phi-rectangle
  :ensure t
  :bind ("C-x SPC" . phi-rectangle-set-mark-command))
