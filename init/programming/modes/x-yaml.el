;; -*- lexical-binding: t -*-

(leaf
  yaml-mode
  :ensure t
  :mode "\\.yml\\'" "\\.yaml\\'" "\\.eyaml\\'"
  :preface
  (defun sd/yaml-ts-mode-hook (&optional arg)
    "Setup hook for `prog-mode'-like text-modes for example YAML."
    (interactive "P")
    (sd/prog-mode-hook)
    ;; but let’s disable 'aggressive-indent'.
    (aggressive-indent-mode -1)
    ;; also let’s disable electric operator mode
    ;;(electric-operator-mode -1)
    (indent-bars-mode)
    ;; yaml-pro specifics
    (yaml-ts-mode)
    (yaml-pro-ts-mode)
    ;; not text
    (visual-fill-column-mode -1)
    ;;(flymake-yamllint-setup)
    (flymake-ansible-lint-setup)
    ;; https://github.com/joaotavora/yasnippet/issues/1020
    ;; fix expansion of snippets
    (setq-local yas/indent-line nil))
  :hook (yaml-ts-mode-hook . sd/yaml-ts-mode-hook))

(leaf yaml-mode-extras :bind (:yaml-mode-map (("<backtab>" . backward-indent))))

(leaf
  yaml-pro
  :ensure t
  :commands sd/yaml-ts-mode-hook
  :bind
  (:yaml-pro-ts-mode-map
    (("M-RET" . yaml-pro-ts-meta-return)
      ("C-M-f" . yaml-pro-ts-next-subtree)
      ("C-M-b" . yaml-pro-ts-prev-subtree)
      ("C-M-u" . yaml-pro-ts-up-level)
      ("C-M-d" . yaml-pro-ts-down-level)
      ("M-<up>" . yaml-pro-ts-move-subtree-up)
      ("M-<down>" . yaml-pro-ts-move-subtree-down))))
