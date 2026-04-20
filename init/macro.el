;; -*- lexical-binding: t -*-

(leaf
  dmacro
  ;; doesn't work in general for some reason
  :ensure t
  :custom `((dmacro-key . ,(kbd "C-x C-k k"))))

(leaf
  elmacro
  :ensure t
  :bind (("C-x C-k !" . elmacro-mode) ("C-x C-k ?" . elmacro-show-last-macro)))
