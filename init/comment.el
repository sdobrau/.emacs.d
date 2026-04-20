;; -*- lexical-binding: t -*-

(leaf
  comment-extras
  :bind
  (("C-M-;" . comment-box)
    ("C-x M-;" . daanturo-transpose-line-and-swap-comment-status)
    (:prog-mode-map
      (("M-RET" . nasyxx/newline-indent-and-continue-comments-a)))))

(leaf comnt-hide :bind ("C-c M-;" . hide/show-comments-toggle))

(setq byte-compile-dynamic-docstrings t)
