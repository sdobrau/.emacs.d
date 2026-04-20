;; -*- lexical-binding: t -*-

;; TODO: customize and binds. see info
(leaf visual-replace :ensure t)

(leaf
  visual-regexp-steroids
  :ensure t
  :bind
  (("M-%" . vr/replace)
    ("C-c M-%" . vr/mc-mark)
    ("C-M-s" . vr/isearch-forward)
    ("C-M-r" . vr/isearch-backward)))
