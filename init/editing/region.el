;; -*- lexical-binding: t -*-

;; Automatically append to kill-ring when selecting by mouse
(setq-default mouse-drag-copy-region t)

(leaf
  easy-kill
  :ensure t
  :bind* ("M-w" . easy-kill) ;; remap kill-ring-save
  :custom
  (easy-kill-alist
    .
    '
    ((?w word " ")
      (?s symbol "\n")
      (?l line "\n")
      (?f filename "\n")
      (?d defun "\n\n")
      (?D defun-name " ")
      (?- line "\n")
      (?b buffer "\n")
      ;; additions
      (?p paragraph "\n")
      (?u url " ")
      (?' string " "))))

(leaf
  easy-kill-extras
  :ensure t
  :config (require 'extra-things)
  ;; example settings

  (add-to-list 'easy-kill-alist '(?w word " ") t)
  (add-to-list 'easy-kill-alist '(?\' squoted-string "") t)
  (add-to-list 'easy-kill-alist '(?\" dquoted-string "") t)
  (add-to-list 'easy-kill-alist '(?\` bquoted-string "") t)
  (add-to-list 'easy-kill-alist '(?q quoted-string "") t)
  (add-to-list 'easy-kill-alist '(?q quoted-string-universal "") t)
  (add-to-list 'easy-kill-alist '(?\) parentheses-pair-content "\n") t)
  (add-to-list 'easy-kill-alist '(?\( parentheses-pair "\n") t)
  (add-to-list 'easy-kill-alist '(?\] brackets-pair-content "\n") t)
  (add-to-list 'easy-kill-alist '(?\[ brackets-pair "\n") t)
  (add-to-list 'easy-kill-alist '(?} curlies-pair-content "\n") t)
  (add-to-list 'easy-kill-alist '(?{ curlies-pair "\n") t)
  (add-to-list 'easy-kill-alist '(?> angles-pair-content "\n") t)
  (add-to-list 'easy-kill-alist '(?< angles-pair "\n") t))

(leaf
  whitespace4r
  :quelpa
  (whitespace4r
    :fetcher github
    :repo "twlz0ne/whitespace4r.el"
    :files ("whitespace4r.el"))

  :commands whitespace4r-mode
  :custom
  ((whitespace4r-style . '(tabs hspaces zwspaces trailing))
    (whitespace4r-display-mappings
      .
      `
      ((space-mark . [?·])
        (hard-space-mark . [?¤])
        (zero-width-space-mark . [?┆])
        (tab-mark . [?— ?⟶])))))

(leaf
  expand-region
  :ensure t
  ;; TODO: lazy?
  :bind
  (:selected-keymap
    :package
    expand-region
    (("SPC" . er/expand-region) ("q" . er/contract-region))))

(leaf
  selected
  :ensure t
  :require t
  ;; TODO: lazy ?
  :bind ((:selected-keymap (("w" . kill-region)))))

(leaf
  region-extras
  ;; TODO: lazy
  :require t
  :bind
  ;; TODO: fix conflixt with undo?
  (("M-g SPC" . xc/reselect-last-region)
    ("C-x n n" . redguardtoo-narrow-or-widen-dwim)
    ("C-x c r C-SPC" . xc/reselect-last-region))

  (:selected-keymap
    :package region-extras
    (("!" . shell-command-on-region)
      ("u" . kf-uniqify)
      ("w" . kill-region) ;; C-w already for window
      ("s" . adq/sort-symbol-list-region)
      ("C-s" . jf/sort-unique-lines)
      ("C-x C-o" . mw-region-delete-empty-lines))))
