(leaf minibuffer-extras
  :after minibuffer
  :commands up-directory exit-with-top-completion
  :hook (rfn-eshadow-update-overlay-hook . daanturo-find-file-insert-/-after-~-h))

;; TODO maybe leaf form "vertico-repeat :quelpa (:files (:defaults ("...")))"
;; this would remove the requirement of recursive search
;; recursive requirement
;; HERE

(leaf mini-popup)

    ;;;; 2. projectile.el (projectile-project-root)
;; (autoload 'projectile-project-root "projectile")
;; (setq consult-project-root-function #'projectile-project-root)
    ;;;; 3. vc.el (vc-root-dir)
;; (setq consult-project-root-function #'vc-root-dir)
    ;;;; 4. locate-dominating-file
;; (setq consult-project-root-function (lambda () (locate-dominating-file "." ".git")))

(leaf consult-extras
  :require t)

(leaf smex
  :ensure t
  :require t
  :preface (setq smex-history-length 20)
  :bind (("M-x". smex)
         ("s-x" . execute-extended-command))
  :custom ((smex-prompt-string . "⧒ ")
           (smex-auto-update . nil)) ;; smex smex to update
  :config
  (smex-initialize))

(leaf embark
  :ensure t
  :preface
  (defun embark-act-noquit ()
    "run action but don't quit the minibuffer afterwards."
    (interactive)
    (let ((embark-quit-after-action nil))
      (embark-act)))
  :hook (embark-collect-mode . consult-preview-at-point-mode) ;; consult int.
  :custom ((prefix-help-command . #'embark-prefix-help-command)
           ;; (prefix-help-command #'describe-prefix-bindings) ; the default of the above
           ;; (embark-collect-initial-view-alist . '((t . list))) ; list is def
           ;; (embark-quit-after-action . t)     ; xxx: read the doc string!
           ;; (embark-cycle-key . (kbd "C-."))   ; see the `embark-act' key

           ;; keep embark from attempt to insert target at y-or-n-p prompt
           (y-or-n-p-use-read-key . t)
           (embark-collect-live-update-delay . 0.5)
           (embark-collect-live-initial-delay . 0.8)

           (embark-indicator . #'embark-mixed-indicator)
           ;; note 2021-07-31: the mixed indicator starts out with a minimal view
           ;; and then pops up the verbose buffer, so those variables matter.
           (embark-verbose-indicator-excluded-actions
            .
            '("\\`embark-collect-" "\\`customize-" "\\(local\\|global\\)-set-key"
              set-variable embark-cycle embark-export
              embark-keymap-help embark-become embark-isearch))
           (embark-verbose-indicator-buffer-sections
            .
            `(target "\n" shadowed-targets " " cycle "\n" bindings))
           (embark-mixed-indicator-both . nil)
           (embark-mixed-indicator-delay . 1.2)
           (embark-verbose-indicator-display-action . nil))
  :bind (("C-." . embark-act) ;; global
         (:minibuffer-local-completion-map
          (("C-." . embark-act) ;; go down one line + enter ?
           ("M-RET" . embark-act-noquit)
           ("C-M-s" . embark-collect)
           ("C-M-," . embark-become)
           ("C-M-e" . embark-export)))
         (:embark-collect-mode-map
          (("M-q" . embark-collect-toggle-view)))
         (:embark-region-map
          (("s" . sort-lines)
           ("a" . align-regexp)
           ("u" . untabify)
           ("i" . epa-import-keys-region)))
         (:minibuffer-local-map
          (("C-l" . embark-act)
           ("M-RET" . embark-act-noquit)
           ("C-M-s" . embark-collect)
           ("C-|" . embark-collect))
          ("C-M-," . embark-become)
          ("C-M-e" . embark-export)))
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*embark collect \\(live\\|completions\\)\\*" nil
                 (window-parameters (mode-line-format . none))))

  (setq embark-action-indicator
        (lambda (map _target)
          (which-key--show-keymap "embark" map nil nil 'no-paging)
          #'which-key--hide-popup-ignore-command)
        embark-become-indicator embark-action-indicator))

(leaf embark-consult
  :after embark ; only need to install it, embark loads it after consult if found
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; TODO: embark keymaps etc
;; allow target to be edited before acting on it
;; embark-setup-actions hooks to run after injecting target into minibuffer
;; manage general.el embark keymaps

(leaf orderless
  :ensure t
  ;; COMMIT: remove circular dependency
  :require t
  :custom ((completion-styles . '(basic substring partial-completion flex))
           (completion-category-overrides
            . '((file (styles basic partial-completion))
                (buffer (styles . (flex))))))
  :config
  ;; Try out host-name completion (with Vertico.)
  (defun basic-remote-try-completion (string table pred point)
    (and (vertico--remote-p string)
         (completion-basic-try-completion string table pred point)))
  (defun basic-remote-all-completions (string table pred point)
    (and (vertico--remote-p string)
         (completion-basic-all-completions string table pred point)))
  (add-to-list
   'completion-styles-alist
   '(basic-remote basic-remote-try-completion basic-remote-all-completions nil))
  (setq completion-styles '(orderless)
        completion-category-overrides '((file (styles basic-remote
                                                      partial-completion)))))

(leaf marginalia
  :ensure t
  :init (marginalia-mode)
  :custom (marginalia--cache-size . 0)
  :bind (:minibuffer-local-map
         (("M-a" . marginalia-cycle)))
  :config (add-to-list 'marginalia-prompt-categories '("face" . face)))
