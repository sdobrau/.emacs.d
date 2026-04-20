;; -*- lexical-binding: t -*-

;; TODO: level-1 face

(leaf highlight-stages :ensure t)
(leaf lisp-extra-font-lock :ensure t)
(leaf highlight-function-calls :ensure t)

;; TODO: why does it not work sometimes?
;;(advice-add 'elisp-demos-advice-helpful-update :after #'highlight-function-calls-mode)

;; TODO: elsa and flycheck

(leaf
  pp
  :bind
  (([remap eval-expression] . pp-eval-expression)
    ([remap eval-last-sexp] . pp-eval-last-sexp)))

;; highlight lexically-bound variables
(leaf
  lex-hl
  :bind
  (:lex-hl-mode-map
    (("M-s h C-`" . lex-hl-unhighlight)
      ("M-s h C-'" . lex-hl-top-level)
      ("M-s h C-," . lex-hl-prompt)
      ("M-s h C-." . lex-hl-nearest))))

(leaf morlock :ensure t)

(leaf bug-hunter :ensure t)

(leaf
  elisp-autofmt
  :quelpa
  (elisp-autofmt
    :fetcher codeberg
    :repo "ideasman42/emacs-elisp-autofmt"
    :files
    (:defaults
      "elisp-autofmt.py"
      "elisp-autofmt-cmd.py"
      "elisp-autofmt.overrides.json"))
  ;; to not break
  :custom
  ((elisp-autofmt-empty-line-max . 1)
    (elisp-autofmt-load-packages-local . '("leaf")))
  :commands (elisp-autofmt-mode elisp-autofmt-buffer))

(leaf
  elisp-extras
  :require
  :preface
  (defun sd/lisps-hook (&optional arg)
    "Hook for `emacs-lisp-mode-hook' or `ielm-mode-hook'."
    (interactive "P")
    ;; (lex-hl-mode)
    ;;(flylisp-mode)
    ;; (elisp-def-mode)
    (rainbow-delimiters-mode)
    (compile-angel-on-save-local-mode)
    ;; (highlight-stages-mode)
    ;; (morlock-mode)
    ;; (lisp-extra-font-lock-mode)
    (highlight-function-calls-mode)
    (push '("/=" . ?≠) prettify-symbols-alist)
    (push '("sqrt" . ?√) prettify-symbols-alist)
    (push '("not" . ?¬) prettify-symbols-alist)
    (push '("and" . ?∧) prettify-symbols-alist)
    (push '("or" . ?∨) prettify-symbols-alist)
    ;; but remove electric-operator as variables use '-'
    (electric-indent-local-mode)
    (setq-local completion-at-point-functions
      '
      (elisp-completion-at-point
        yasnippet-capf
        cape-keyword
        cape-dabbrev
        cape-file
        t))
    ;; autofmt and indent
    (setq-local indent-tabs-mode nil)
    (setq-local lisp-indent-function nil)
    (setq-local lisp-indent-offset 2)
    (setq-local elisp-autofmt-style 'fixed)
    (elisp-def-mode)
    (eros-mode))

  :hook
  (
    (emacs-lisp-mode-hook
      ;; inferior-emacs-lisp-mode-hook
      ;; ielm-mode-hook
      ;; lisp-mode-hook
      ;; inferior-lisp-mode-hook
      ;; lisp-interaction-mode-hook
      ;; eval-expression-minibuffer-setup-hook
      ;; slime-repl-mode-hook
      )
    . sd/lisps-hook))
