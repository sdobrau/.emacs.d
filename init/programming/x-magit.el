(leaf
  magit
  ;; TODO: lazy
  :quelpa (magit :fetcher github :repo "magit/magit")
  :preface
  (defun my-recenter-top (&optional args)
    "recenter at top"
    (interactive "P")
    (recenter-top-bottom 'top))
  :require t
  :commands magit-dispatch
  :bind
  (("C-x M-g" . magit-dispatch)
    ("C-x g" . magit-status)
    ("C-x v C-c" . magit-commit-create)
    ("C-x v C-." . magit-commit-autofixup)
    ("C-x v M-." . magit-commit-reword)
    ("C-x v C-M-." . magit-commit-extend)
    ("C-x v SPC" . magit-push-current-to-upstream)
    (:magit-mode-map
      (("M-w" . easy-kill) ;; was key below v
        ("C-c s" . magit-jump-to-staged)
        ("C-c u" . magit-jump-to-unstaged)
        ("C-c M-w" . magit-copy-buffer-revision)
        ("C-o" . magit-dired-other-window)
        ("M-d" . daanturo-magit-diff-commit-or-branch-at-point-to-HEAD)
        ("M-k" . daanturo-magit-discard-no-trash)))
    (:magit-section-mode-map (("C-M-u" . magit-section-up))))
  :hook ((magit-post-stage-hook magit-post-refresh-hook) . my-recenter-top)
  :custom
  ((magit-repository-directories . '(("/home/sdobrau/git" . 2)))
    (magit-refresh-status-buffer . t)
    (magit-clone-set-remote.pushDefault . t)
    (magit-clone-default-directory . my-git-directory)
    (magit-log-auto-more . t)
    (magit-commit-diff-inhibit-same-window . t) ;; for current-window-only
    (magit-commit-show-diff . t)
    ;; daanturo
    (magit-log-margin . '(t "%F %R" magit-log-margin-width t 16))
    ;; redguardtoo
    (magit-buffer-log-rags . '("--follow"))
    ;; don’t show index
    (magit-diff-adjust-tab-width . 'always)
    (magit-diff-refine-hunk . 'all) ; fine differences always
    (magit-revision-use-hash-sections . 'quickest) ;; search only 7 chars
    (magit-ediff-show-stash-with-index . nil)
    (magit-remote-add-set-remote.pushdefault . t)
    (magit-save-repository-buffers . 'dontask)
    (magit-blame-disable-modes . '(fci-mode view-mode yascroll-bar-mode))
    (magit-process-find-password-functions
      .
      '(magit-process-password-auth-source))
    (magit-process-password-prompt-regexps
      .
      '
      ("^\\(Enter \\)?[Pp]assphrase\\( for \\(RSA \\)?key '.*'\\)?: ?$"
        "^\\(Enter \\)?[Pp]assword\\( for '?\\(https?://\\)?\\(?99:[^']*\\)'?\\)?: ?$"
        "Please enter the passphrase for the ssh key"
        "Please enter the passphrase to unlock the OpenPGP secret key"
        "^.*'s password: ?$"
        "^Yubikey for .*: ?$"
        "^Enter PIN for .*: ?$"
        "^\\[sudo\\] password for .*: ?$"))
    (magit-clone-default-directory . my-git-directory))
  :config
  ;; fix colors
  ;;(set-face-attribute 'magit-diff-removed-highlight nil :foreground (face-attribute 'diff-removed :foreground))
  ;;(set-face-attribute 'magit-diff-added-highlight nil :background (face-attribute 'diff-added :background))
  ;; DEBUG
  (magit-auto-revert-mode 0)
  (defun magit-dired-other-window ()
    (interactive)
    (dired-other-window (magit-toplevel)))

  ;; (defun my-disable-font-lock (&optional arg)
  ;;   (interactive "P")
  ;;   (font-lock-mode 0))
  ;; (add-hook 'magit-revision-mode-hook #'my-disable-font-lock)
  (remove-hook 'git-commit-setup-hook #'with-editor-usage-message) ;; git-commit
  ;; kaz-yos: recenter when moving across sections/siblings
  (advice-add 'magit-section-forward :after #'my-recenter-top)
  (advice-add 'magit-section-forward-sibling :after #'my-recenter-top)
  (advice-add 'magit-section-backward :after #'my-recenter-top)
  (advice-add 'magit-section-backward-sibling :after #'my-recenter-top))

;; daanturo
;;(advice-add 'magit-process-insert-section
;;            :before
;;            #'magit-wiki-auto-display-magit-process-buffer)

(leaf
  magit-extras
  :commands
  (my-fast-magit-refresh-on
    my-fast-magit-refresh-off
    my-fast-magit-refresh-toggle
    magit-list-repositories)
  ;; proper commit history as accessible by M-n/M-p in commit/status buffers

  :bind
  (("C-x v !" . ar/magit-soft-reset-head~1)
    (:magit-mode-map
      (("C-x n s" . mw-magit-narrow-to-section)
        ("C-c SPC" . mw-magit-mark-section)
        ("C-x -" . lw-magit-checkout-last)))
    (:magit-repolist-mode-map
      :package magit-extras
      (("w" . akirak/magit-repolist-kill-origin-url-at-point)
        ("D" . akirak/magit-repolist-trash-repository-at-point)
        ("R" . akirak/magit-repolist-rename-repository-at-point))))
  :custom
  (
    (magit-repolist-columns
      .
      '
      (("Path" 30 akirak/magit-repolist-column-path nil)
        ("Branch" 20 magit-repolist-column-branch nil)
        ("Drty" 4 akirak/magit-repolist-column-dirty nil)
        ("Unmg" 5 akirak/magit-repolist-column-unmerged nil)
        ("Stsh" 4 magit-repolist-column-stashes nil)
        ("B<U"
          3
          magit-repolist-column-unpulled-from-upstream
          ((:right-align t) (:help-echo "Upstream changes not in branch")))
        ("B>U"
          3
          magit-repolist-column-unpushed-to-upstream
          ((:right-align t) (:help-echo "Local changes not in upstream")))
        ("Date" 12 akirak/magit-repolist-column-commit-date nil)
        ("origin" 30 akirak/magit-repolist-column-origin nil))))
  :config (advice-add 'magit-status :after #'mw/advice/add-last-commit-messages))
;;  :bind (:magit-mode-map
;;         (("!")))

;; https://github.com/magit/forge/issues/363 "Selecting deleted buffer"
(leaf
  forge
  :after
  emacsql-sqlite
  closql
  :quelpa (forge :fetcher github :repo "magit/forge")
  :bind ("C-x C-M-g" . forge-browse-repository))

(leaf
  magit-todos
  :quelpa (magit-todos :fetcher github :repo "alphapapa/magit-todos")
  ;;:hook (magit-status-mode-hook . magit-todos-mode)
  :custom ((magit-todos-update . t) (magit-todos-ignore-case . t)))

(leaf
  magit-delta
  :if (executable-find "delta")
  :ensure t
  :hook (magit-mode-hook . magit-delta-mode)
  :custom
  ((magit-delta-hide-plus-minus-markers . nil)
    (magit-delta-default-dark-theme . "Sublime Snazzy")))

(leaf
  magit-commit-mark
  :quelpa
  (magit-commit-mark
    :fetcher codeberg
    :repo "ideasman42/emacs-magit-commit-mark")
  ;; TODO: fetcher form for codeberg
  :hook (magit-mode-hook . magit-commit-mark-mode)
  :bind
  (:magit-log-mode-map
    :package magit-commit-mark
    ((";" . magit-commit-mark-toggle-read)
      ("M-;" . magit-commit-mark-toggle-star)
      ("C-;" . magit-commit-mark-toggle-urgent)))
  :config
  (setq magit-commit-mark-directory
    (no-littering-expand-var-file-name "magit-commit-mark")))

(leaf
  magit-todos
  :quelpa (magit-todos :fetcher github :repo "alphapapa/magit-todos")
  :hook (magit-mode-hook . magit-todos-mode))
;; commit: wtf
(set-fringe-mode '(1 . 1))
