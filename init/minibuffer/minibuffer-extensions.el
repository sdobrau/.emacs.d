(leaf
  minibuffer-extras
  :after minibuffer
  :commands
  up-directory
  exit-with-top-completion
  :hook (rfn-eshadow-update-overlay-hook . daanturo-find-file-insert-/-after-~-h))

;; TODO:
;; TODO: lazy
;; proper setting/loading of vertico-multiform
;; (add-to-list 'vertico-multiform-categories '(embark-keybinding grid))
(leaf
  embark
  :ensure t
  :require t
  :init
  ;; TODO: try lazy

  (defun sd/embark-collect-and-export (&optional args)
    (interactive "P")
    (embark-collect)
    (embark-export))

  (defun sd/init--no-center-hook ()
    (visual-fill-column-mode -1)
    (visual-line-mode -1))

  (defun sd/embark-yank-no-prefix (strings)
    (interactive "fNote: ")
    (kill-new (car (last (split-string strings ":")))))

  ;; TODO: sd/embark-insert-no-prefix

  (defun embark-act-noquit ()
    "run action but don't quit the minibuffer afterwards."
    (interactive)
    (let ((embark-quit-after-action nil))

      (embark-act)))

  :hook
  ((embark-collect-mode-hook . sd/init--no-center-hook)
    (embark-collect-mode-hook . consult-preview-at-point-mode)
    (embark-collect-mode-hook . (lambda () (auto-sudoedit-mode -1)))) ;; consult int.
  :custom
  ((embark-quit-after-action . nil)
    (prefix-help-command . #'embark-prefix-help-command)
    ;; keep embark from attempt to insert target at y-or-n-p prompt
    (y-or-n-p-use-read-key . t)

    (embark-verbose-indicator-excluded-actions
      .
      '
      ("\\`embark-collect-"
        "\\`customize-"
        "\\(local\\|global\\)-set-key"
        set-variable
        embark-cycle
        embark-export
        embark-keymap-help
        embark-become
        embark-isearch))
    (embark-verbose-indicator-buffer-sections
      .
      `(target "\n" shadowed-targets " " cycle "\n" bindings))
    (embark-mixed-indicator-both . nil)
    (embark-mixed-indicator-delay . 1.2)
    (embark-verbose-indicator-display-action . nil))
  :bind
  (("C-." . embark-act) ;; global
    (:minibuffer-local-completion-map
      (("C-." . embark-act) ;; go down one line + enter ?
        ("C-M-s" . embark-collect)
        ("C-M-," . embark-become)
        ("C-M-e" . embark-export)))
    (:embark-collect-mode-map (("SPC" . embark-select)))
    (:embark-region-map
      (("s" . sort-lines)
        ("a" . align-regexp)
        ("u" . untabify)
        ("i" . epa-import-keys-region)))
    (:embark-general-map
      (("w" . sd/embark-yank-no-prefix) ("C-." . sd/embark-insert-no-prefix)))
    (:minibuffer-local-map
      (("C-l" . embark-act) ("C-M-s" . embark-collect) ("C-|" . embark-collect))
      ("C-M-," . embark-become)
      ("C-M-e" . embark-export))
    (:vertico-map
      (("C-l" . embark-act)
        ("M-RET" . embark-dwim)
        ("C-c M-RET" . embark-act-all)
        ("C-M-s" . embark-collect)
        ("C-M-p" . sd/embark-collect-and-export))
      ("C-M-," . embark-become) ("C-M-e" . embark-export)))
  :config
  (add-to-list
    'display-buffer-alist
    '
    ("\\`\\*embark collect \\(live\\|completions\\)\\*"
      nil
      (window-parameters (mode-line-format . none))))

  (setq
    embark-action-indicator
    (lambda (map _target)
      (which-key--show-keymap "embark" map nil nil 'no-paging)
      #'which-key--hide-popup-ignore-command)
    embark-become-indicator embark-action-indicator))

(leaf
  embark-consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; TODO: embark keymaps etc
;; allow target to be edited before acting on it
;; embark-setup-actions hooks to run after injecting target into minibuffer
;; manage general.el embark keymaps

;; (add-hook 'minibuffer-setup-hook #'visual-line-mode)
;;(add-hook 'minibuffer-setup-hook #'(lambda () (setq-default truncate-lines nil)))
;;(add-hook 'minibuffer-setup-hook #'(lambda () (toggle-truncate-lines -1)))

(leaf
  marginalia
  :ensure t
  :custom (marginalia--cache-size . 900000)
  :bind (:minibuffer-local-map ("M-a" . marginalia-cycle))
  :config
  ;; don't need for file or buffer
  (setq marginalia-annotator-registry
    (assq-delete-all 'file marginalia-annotator-registry))
  (setq marginalia-annotator-registry
    (assq-delete-all 'buffer marginalia-annotator-registry))
  (add-to-list 'marginalia-prompt-categories '("face" . face)))
