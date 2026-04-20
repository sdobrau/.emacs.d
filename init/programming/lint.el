;; -*- lexical-binding: t -*-

;; make flymake backends work with flycheck

(leaf flymake
  :bind
  (:flymake-mode-map
    (("C-<left>" . flymake-goto-next-error)
      ("C-<right>" . flymake-goto-prev-error)
      ("M-g M-f" . flymake-show-project-diagnostics))))

(leaf flymake-flycheck
  :ensure t
  :hook (flymake-mode-hook . flymake-flycheck-auto))

(leaf flycheck
  :ensure t
  ;; make it fast
  :custom
  ((flycheck-idle-change-delay . 3)
    (flycheck-idle-b-switch-delay . 3)
    (flycheck-display-errors-delay . 2)
    ;; use load path of current emacs session for checking
    (flycheck-emacs-lisp-load-path . 'inherit)
    (flycheck-relevant-error-other-file-show . nil)
    ;; when saving
    (flycheck-check-syntax-automatically . '(save))
    ;; navigate compilation errors, not standard errors with error
    ;; navigation keys
    (flycheck-standard-error-navigation . nil)
    (next-error-function . #'flycheck-next-error-function)
    (previous-error-function . #'flycheck-previous-error-function)))

;; TODO: try out just flymake combined atm
(leaf flycheck-inline
  :disabled t
  :hook (flycheck-mode-hook . flycheck-inline-mode)
  ;; use quick-peek for nice box display
  :init
  (setq
    flycheck-inline-display-function
    (lambda (msg pos err)
      (let*
        (
          (ov (quick-peek-overlay-ensure-at pos))
          (contents (quick-peek-overlay-contents ov)))
        (setf (quick-peek-overlay-contents ov)
          (concat
            contents
            (when contents
              "\n")
            msg))
        (quick-peek-update ov)))
    flycheck-inline-clear-function #'quick-peek-hide))
