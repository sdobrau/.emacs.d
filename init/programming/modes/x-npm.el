;; -*- lexical-binding: t -*-

(leaf npm-mode
  :ensure t)

(leaf npm-mode
  :ensure t)

(leaf npm
:ensure t
:bind (:js2-mode-map
       (("C-x N i" . npm-install))))
