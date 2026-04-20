;; -*- lexical-binding: t -*-

(leaf python
  ;;:after aggressive-indent electric-operator pyvenv poetry pipenv lsp
  ;;lsp-pyright
  :preface
  (defun prettify-symbols-python () ;; from adq
    (push '("lambda" . ?λ) prettify-symbols-alist)
    (push '("and" . ?∧) prettify-symbols-alist)
    (push '("or" . ?∨) prettify-symbols-alist)
    (push '("==" . ?≡) prettify-symbols-alist)
    (push '("!=" . ?≠) prettify-symbols-alist)
    (push '("<=" . ?≤) prettify-symbols-alist)
    (push '(">=" . ?≥) prettify-symbols-alist)
    (push '(">>" . ?≫) prettify-symbols-alist)
    (push '("<<" . ?≪) prettify-symbols-alist)
    (push '("->" . ?→) prettify-symbols-alist)
    (push '("not in" . ?∉) prettify-symbols-alist)
    (push '("in" . ?∈) prettify-symbols-alist)
    (push '("sum" . ?Σ) prettify-symbols-alist)
    (push '("all" . ?∀) prettify-symbols-alist)
    (push '("any" . ?∃) prettify-symbols-alist)
    (push '("..." . ?…) prettify-symbols-alist))

  (defun sd/python-ts-mode-hook (&optional arg)
    (interactive)
    ;;(poetry-tracking-mode)
    (setq-local python-indent 2)
    (aggressive-indent-mode -1)
    ;;(electric-operator-mode)
    (prettify-symbols-mode)
    (prettify-symbols-python)
    ;; from pet-mode
    (setq-local python-shell-interpreter (pet-executable-find "python")
                python-shell-virtualenv-root (pet-virtualenv-root)
                lsp-pyright-python-executable-cmd python-shell-interpreter
                lsp-pyright-venv-path python-shell-virtualenv-root)

    (local-set-key (kbd "M-h") #'er/mark-python-block)
    (local-set-key (kbd "C-M-h") #'er/mark-python-block)
    ;;(require 'lsp-pyright)
    ;;(setq-local lsp-pyright-langserver-command "basedpyright")
    (lsp))

  :hook (python-ts-mode-hook . sd/python-ts-mode-hook)
  :mode (("[./]flake8\\'" . conf-mode)
         ("/pipfile\\'" . conf-mode)
         ("sconstruct\\'" . python-mode)
         ("sconscript\\'" . python-mode))
  :interpreter ("python" . python-mode)

  :bind (:python-mode-map
         (("DEL" . python-indent-dedent-line-backspace)
          ("<backspace>" . python-indent-dedent-line-backspace)
          ("C-x C-e" . python-shell-send-whole-line-or-region)
          ("C-c C-c" . python-shell-send-buffer)
          ("C-M-x" . python-shell-send-defun)))

  :custom ((python-indent-guess-indent-offset-verbose . nil)
           (python-shell-interpreter . "ipython")
           (python-indent-def-block-scale . 1)
           (python-shell-interpreter-args .
                                          "-i --simple-prompt --no-color-info --interactiveshell.display_page=true")))

(leaf pip-requirements
  :ensure t
  :mode ("requirements.in"
         "requirements.txt"
         "constraints.txt"))
