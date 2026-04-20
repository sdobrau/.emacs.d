;; -*- lexical-binding: t -*-

;;; TREEMACS

;; (leaf
;;   treemacs
;;   :ensure t
;;   :hook ((treemacs-mode-hook . treemacs-indent-guide-mode))
;;   :bind ("M-0" . treemacs-select-window)
;;   :custom
;;   ((treemacs-deferred-git-apply-delay . 2)
;;     (treemacs-directory-name-transformer . #'identity)
;;     (treemacs-display-in-side-window . t)
;;     (treemacs-eldoc-display . 'simple)
;;     (treemacs-file-event-delay . 2000)
;;     (treemacs-file-extension-regex . treemacs-last-period-regex-value)
;;     (treemacs-file-follow-delay . 1.5)
;;     (treemacs-file-name-transformer . #'identity)
;;     (treemacs-follow-after-init . t)
;;     (treemacs-expand-after-init . t)
;;     (treemacs-find-workspace-method . #'find-for-file-or-pick-first)
;;     (treemacs-git-command-pipe . "")
;;     (treemacs-goto-tag-strategy . 'refetch-index)
;;     (treemacs-header-scroll-indicators . '(" " . "^^^^^^"))
;;     (treemacs-hide-dot-git-directory . t)
;;     (treemacs-indentation . 3)
;;     (treemacs-indentation-string . " ")
;;     (treemacs-is-never-other-window . t)
;;     (treemacs-max-git-entries . 5000)
;;     (treemacs-missing-project-action . 'ask)
;;     (treemacs-move-files-by-mouse-dragging . t)
;;     (treemacs-move-forward-on-expand . t)
;;     (treemacs-no-png-images . t)
;;     (treemacs-no-delete-other-windows . t)
;;     (treemacs-project-follow-cleanup . t)
;;     (treemacs-position . 'left)
;;     (treemacs-read-string-input . 'from-minibuffer)
;;     (treemacs-recenter-distance . 0.1)
;;     (treemacs-recenter-after-file-follow . t)
;;     (treemacs-recenter-after-tag-follow . t)
;;     (treemacs-recenter-after-project-jump . 'always)
;;     (treemacs-recenter-after-project-expand . 'on-distance)
;;     (treemacs-litter-directories . '("/node_modules" "/.venv" "/.cask"))
;;     (treemacs-project-follow-into-home . t)
;;     (treemacs-show-cursor . t)
;;     (treemacs-show-hidden-files . t)
;;     (treemacs-silent-filewatch . t)
;;     (treemacs-silent-refresh . t)
;;     (treemacs-sorting alphabetic-asc)
;;     (treemacs-select-when-already-in-treemacs . 'move-back)
;;     (treemacs-space-between-root-nodes . t)
;;     (treemacs-tag-follow-cleanup . t)
;;     (treemacs-tag-follow-delay . 1.5)
;;     (treemacs-text-scale . 0.5)
;;     (treemacs-user-mode-line-format . nil)
;;     (treemacs-user-header-line-format . nil)
;;     (treemacs-wide-toggle-width . 70)
;;     (treemacs-width . 30)
;;     (treemacs-width-increment . 1)
;;     (treemacs-width-is-initially-locked . t)
;;     (treemacs-workspace-switch-cleanup))
;;   :config
;;   (treemacs-follow-mode)
;;   (treemacs-filewatch-mode)
;;   (treemacs-fringe-indicator-mode 'always)
;;   (when treemacs-python-executable
;;     (treemacs-git-commit-diff-mode t))

;;   (pcase
;;     (cons
;;       (not (null (executable-find "git")))
;;       (not (null treemacs-python-executable)))
;;     (`(t . t) (treemacs-git-mode 'deferred))
;;     (`(t . _) (treemacs-git-mode 'simple))))

;;; everything else

;; cool
(leaf dired-rainbow :ensure t)

(leaf
  dired-filter
  :ensure t
  :commands dired-filter-mode
  ; :hook (dired-mode-hook . dired-filter-mode)

  :custom
  ((dired-filter-prefix . "/")
    (dired-filter-mark-prefix . "M-/")
    (dired-filter-revert . t))
  :hook
  (
    (dired-sidebar-mode-hook
      .
      (lambda ()
        (progn
          (dired-filter-by-git-ignored)
          (setq-local dired-filter-header-line-format nil))))))

(leaf
  dired-subtree
  :ensure t
  :require t
  :bind
  (:dired-mode-map
    (("i" . nil) ;; dired-maybe-insert-subdir
      ("i" . dired-subtree-insert)
      ("C-M-n" . dired-subtree-next-sibling)
      ("C-M-p" . dired-subtree-previous-sibling)
      ("C-M-a" . dired-subtree-beginning)
      ("C-M-e" . dired-subtree-end)
      ("C-M-f" . dired-subtree-next-sibling)
      ("C-M-b" . dired-subtree-previous-sibling)
      ("C-M-u" . dired-subtree-up)
      ("C-M-d" . dired-subtree-down)
      ("* RET" . dired-subtree-mark-subtree)
      ("* M-RET" . dired-subtree-mark-subtree)
      ("TAB" . nil)
      ("C-x M-RET" . dired-subtree-unmark-subtree)
      ("C-c l" . dired-subtree-with-subtree)
      ;; cant tab at the moment, tab-for-indent
      ("C-c TAB" . dired-subtree-cycle)
      ("C-c M-d" . dired-subtree-remove)))
  :custom (dired-subtree-use-backgrounds . nil))

(leaf dired-map) ;; TODO: where is dired-map ?

(leaf
  dired-posframe
  :if (display-graphic-p)
  :ensure t
  :after posframe
  :bind (:dired-mode-map ("C-*" . dired-posframe-show)))

;; TODO
(leaf
  dired-x
  :hook (dired-mode-hook . dired-omit-mode)
  :bind
  (("s-\\" . dired-jump-other-window)
    (:dired-mode-map ((")" . dired-omit-mode))))
  :custom
  ((dired-clean-up-buffers-too . nil)
    (dired-clean-confirm-killing-deleted-buffers . nil)))

(leaf
  fd-dired
  :bind (:dired-mode-map (("/" . fd-dired)))
  :custom (fd-dired-generate-random-buffer . t))

(leaf
  dired-aux
  :custom
  ((dired-vc-rename-file . t)
    (dired-dwim-target . #'dired-dwim-target-next-visible)
    (dired-create-destination-dirs . 'ask)
    ;; if point on file, search file, otherwise whole buffer
    (dired-isearch-filenames . 'dwim)
    (dired-create-destination-dirs . t)
    ;; rename file using vc mechanism
    (dired-vc-rename-file . t)
    (dired-do-revert-buffer . (lambda (dir) (not (file-remote-p dir))))))

(leaf
  dired-hist
  :ensure t
  :hook (dired-mode-hook . dired-hist-mode)
  :bind (:dired-mode-map (("l" . dired-hist-go-back) (";" . dired-hist-go-forward))))

(leaf diredfl :ensure t :hook (dired-mode-hook . diredfl-mode))

(leaf
  dired-extras
  :bind
  (("C-c M-d" . sd/dired-here)
    (:dired-mode-map
      (("C-c f #" . redguardtoo-ediff-files) ("~" . daanturo-dired-home)))))

(leaf
  dired-toggle-sudo
  :ensure t
  :bind
  (:dired-mode-map
    (("#" . nil) ;; dired-flag-auto-save-files
      ("#" . dired-toggle-sudo))))

(leaf
  nerd-icons-dired
  :if (display-graphic-p)
  :ensure t
  :hook (dired-mode-hook . nerd-icons-dired-mode))

(leaf
  dired-auto-readme
  :ensure t
  :hook dired-mode-hook
  :custom
  (dired-auto-readme-files
    . '
    ;; TODO: wtf is this regex
    ("readme.org" "readme.rst" "readme.markdown" "readme" "manifest")))

(leaf dired-list :ensure t)
