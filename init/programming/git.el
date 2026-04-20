;; -*- lexical-binding: t -*-

;; * 'vc' and basic

(leaf git-extras :ensure nil :bind ("C-x v ^" . open-on-github))

(leaf
  git-modes
  :ensure t
  :mode
  (("/\\.gitattributes\\'" . gitattributes-mode)
    ("/info/attributes\\'" . gitattributes-mode)
    ("/git/attributes\\'" . gitattributes-mode)

    ("/\\.gitconfig\\'" . gitconfig-mode)
    ("/\\.git/config\\'" . gitconfig-mode)
    ("/modules/.*/config\\'" . gitconfig-mode)
    ("/git/config\\'" . gitconfig-mode)
    ("/\\.gitmodules\\'" . gitconfig-mode)
    ("/etc/gitconfig\\'" . gitconfig-mode)

    ("/\\.gitignore\\'" . gitignore-mode)
    ("/info/exclude\\'" . gitignore-mode)
    ("/git/ignore\\'" . gitignore-mode)))

(leaf
  git-commit
  :hook (git-commit-mode-hook . (lambda () (setq-local fill-column 72)))
  :custom (git-commit-summary-max-length . 50))

(leaf
  vc
  :custom
  ((auto-revert-check-vc-info . nil) ;; TODO: wtf? find-file hook
    (vc-allow-async-revert . t)
    (vc-command-messages . t)
    (vc-make-backup-files . t)
    (version-control . 'never)
    ;; git diff switches
    (vc-git-diff-switches . '("-w" "-u3"))
    (vc-follow-symlinks . t)))
;; (vc-ignore-dir-regexp . '("\\(\\(\\`"
;;                           "\\(?:[\\/][\\/][^\\/]+[\\/]\\|/"
;;                           "\\(?:net\\|afs\\|\\.\\.\\.\\)/\\)"
;;                           "\\'\\)\\|\\(\\`/[^/|:][^/|]*:\\)\\)\\|\\"
;;                           "(\\`/[^/|:][^/|]*:\\)"))))

;; * Extensions and others

(leaf git-link :ensure t :bind ("C-x v C-l" . git-link))

(leaf diff-hl :ensure t :custom (diff-hl-disable-on-remote . t))

;; Popup last commit of current-line
(leaf
  git-messenger
  :ensure t
  :bind ("C-x v ?" . git-messenger:popup-message)
  :custom ((git-messenger:use-magit-popup . t) (git-messenger:show-detail . t)))

;; Time-machine of commit
(leaf git-timemachine :commands git-timemachine--start :ensure t)

(leaf git-timemachine-extras :bind ("C-x v t" . redguardtoo-git-timemachine))

(leaf consult-ls-git :ensure t :bind ("C-x C-g" . consult-ls-git-ls-files))

(leaf
  lab
  :if (executable-find "glab")
  :ensure t
  :bind ("C-x / C-g g" . lab-search-project))

(leaf
  smeargle
  :ensure t
  :bind
  (("C-x v s" . smeargle)
    ("C-x v C-s" . smeargle-clear)
    ("C-x v c" . smeargle-commits)))

;; (require 'vc-git)
;; (advice-add 'vc-git-find-file-hook :override
;;             (lambda ()
;;               "Activate `smerge-mode' if there is a conflict."
;;               (when (and buffer-file-name
;;                          (eq (vc-state buffer-file-name 'Git) 'conflict)
;;                          (save-excursion
;;                            (goto-char (point-min))
;;                            (re-search-forward "^<<<<<<< " nil 'noerror)))
;;                 (unless (and (boundp 'smerge-mode) smerge-mode)
;;                   (smerge-start-session))
;;                 (when vc-git-resolve-conflicts
;;                   (add-hook 'after-save-hook 'vc-git-resolve-when-done nil 'local))
;;                 (vc-message-unresolved-conflicts buffer-file-name))))
