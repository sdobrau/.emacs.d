;;; aws

(leaf cfn-mode :ensure t :mode)

(leaf
  flycheck-cfn
  :ensure t
  :hook
  (cfn-mode-hook
    .
    (lambda ()
      (setq flycheck-checkers (append flycheck-checkers '(cfn-lint cfn-nag))))))

(leaf
  jmespath
  :if (or (executable-find "jp") (executable-find "jpipe"))
  :ensure t)

(leaf
  terraform-ts-mode
  :after
  treesit-auto
  eglot
  :quelpa (terraform-ts-mode :fetcher github :repo "kgrotel/terraform-ts-mode")
  :config (add-to-list 'treesit-auto-langs 'hcl))

(leaf
  hcl-mode
  :preface
  (defun sd/hcl-mode-hook ()
    (interactive "P")
    ;;(electric-operator-mode -1)
    (auto-fill-mode -1))
  :hook (hcl-mode-hook . sd/hcl-mode-hook)
  :ensure t
  :mode "\\.hcl\\'")

;;; Docker

(leaf docker :ensure t :bind ("C-c d" . docker))

(leaf
  dockerfile-mode
  :ensure t
  :mode "Dockerfile\\’"
  :hook (dockerfile-mode-hook))

;;; Kubernetes
;; TODO:

(leaf kubernetes :ensure t)

(leaf
  rego-mode
  :ensure t
  :mode ("\\.rego\\'" . rego-mode)
  :custom
  ((rego-repl-executable . "/home/strangepr0gram/bin/opa")
    (rego-opa-command . "/home/strangepr0gram/bin/opa")))

;;; Ansible

(leaf
  flymake-ansible-lint
  :if (executable-find "ansible-lint")
  :ensure t
  :commands flymake-ansible-lint-setup
  :hook ((yaml-ts-mode yaml-mode) . flymake-ansible-lint-setup))

;;; Puppet

(leaf puppet-mode :ensure t :mode "\\.pp\\'")

(leaf flymake-puppet :ensure t :hook (puppet-mode-hook . flymake-puppet-load))

;;; Vagrant

(leaf vagrant :quelpa vagrant)

(leaf vagrant-tramp :quelpa vagrant-tramp)
