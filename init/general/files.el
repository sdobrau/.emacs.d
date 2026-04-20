;; -*- lexical-binding: t -*-

;; Useful and fast key-bindings for common operations.
;; Should convert some of these to org-capture at some point.

(leaf
  files-extras
  ;; TODO: lazy load
  ;; TODO: find-next|prev-file-same-mode C-x f C-n|p
  :preface
  (defun sd/dired-to-downloads (&optional arg)
    "Go to DOWNLOADS folder."
    (interactive "P")
    (dired "/ent/chrome-downloads"))
  :leaf-defer t
  :bind
  (("C-x C-M-f" . find-file-rec)
    ("C-x M-d" . sd/dired-to-downloads)
    ("C-x s-f" . open-all-files-in-directory)
    ("C-x f" . nil) ;; set-fill-column
    ("C-x f r" . redguardtoo-vc-rename-file-and-buffer)
    ("C-x f d" . +delete-current-file)
    ("C-x f l" . count-words)
    ("C-x f c" . redguardtoo-vc-copy-file-and-rename-buffer)
    ("C-x f g" . open-on-github)
    ("C-x f w" . jf/nab-file-name-to-clipboard)
    ("C-x f -" . xah-open-file-from-clipboard)
    ("C-x f u" . revert-buffer)
    ("C-x f n" . find-next-file)
    ("C-x f C-r" . recover-this-file)
    ("C-x f p" . find-previous-file)
    ("C-x f x" . kf-make-file-executable)
    ("C-x f /" . save-in-tmp-dir)
    ("C-x f @" . sd/tramp-remote-find-file-for-me))
  ;;daanturo-open-files-with-mode-in-dir maybe
  :config
  (advice-add 'find-file :around #'find-file--line-number)
  (add-to-list 'find-file-not-found-functions #'er-auto-create-missing-dirs))

;; (leaf directory-extras ; todo autoloads explained
;;   :require t)

(leaf
  ediff
  :leaf-defer t
  :custom
  ((ediff-window-setup-function . 'ediff-setup-windows-plain)
    (ediff-diff-options . "-w")
    (ediff-show-clashes-only . t)
    (ediff-split-window-function . 'split-window-horizontally)))

(leaf
  recentf
  :ensure t
  :custom
  ((recentf-max-menu-items . 200)
    (recentf-max-saved-items . 6000)
    (recentf-auto-cleanup . t))

  :config
  (setq recentf-exclude
    `
    (,tramp-file-name-regexp
      "recentf"
      "/elpa/"
      "/elisps/"
      "\\`/tmp/"
      "/\\.git/"
      "/\\.cask/"
      "/tmp/gomi/"
      ".loaddefs.el"
      "/\\.cpanm/"
      "\\.mime-example"
      "\\.ido.last"
      "woman_cache.el"
      "\\`/proc/"
      "\\`/sys/"
      "/ssh\\(x\\)?:"
      "/su\\(do\\)?:"
      "^/usr/include/"
      "/TAGS\\'"
      "COMMIT_EDITMSG\\'"
      "CMakeCache.txt"
      "/bookmarks"
      "\\.gz$"
      "COMMIT_EDITMSG"
      "MERGE_MSG"
      "git-rebase-todo"))
  (recentf-load-list))
