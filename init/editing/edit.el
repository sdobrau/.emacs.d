;; -*- lexical-binding: t -*-

(leaf ace-jump-zap :ensure t :bind ("M-z" . ace-jump-zap-up-to-char))

(global-set-key (kbd "C-c M-u") #'upcase-char)

(leaf
  editing-extras
  :bind
  (("M-d" . kill-word-dwim)
    ;; TODO: backward-kill-superword / kill-superword-at-point
    ("M-DEL" . backward-kill-word-or-join-lines) ;; M-DEL backward-kill-word
    ("C-c RET" . daanturo-open-then-new-indented-line)
    ("C-c M-h" . daanturo-mark-inner-paragraph)
    ;; ("C-M-c -" . daanturo-recenter-region-in-window)
    ;; ("C-M-c |" . daanturo-recenter-left-right)
    ("C-x 8 t" . daanturo-insert-and-copy-date)
    ("C-x 8 M-t" . daanturo-insert-and-copy-date-and-time)
    ("M-q" . kf-fill-paragraph) ;; no mark modified if change
    ("C-x M-%" . daanturo-query-replace-regexp-in-whole-buffer)))

;; TODO: good keymap
(leaf
  surround
  :ensure t
  :require t
  :bind
  (:surround-keymap
    (("i" . surround-mark-inner)
      ("'" . surround-insert)
      ("SPC" . surround-mark))))

(leaf filladapt :ensure t)
