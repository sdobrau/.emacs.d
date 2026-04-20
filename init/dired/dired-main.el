;; -*- lexical-binding: t -*-

(leaf
  dired
  ;; TODO: lazy ?
  :hook
  ((dired-mode-hook . dired-hide-details-mode))
    ;;(dired-mode-hook . dired-async-mode))
  :bind
  (
    (:dired-mode-map
      :package
      window-extras
      (("C-M-o" . xc/switch-to-last-window)))
    (:dired-mode-map :package dired-extras (("RET" . xc/dired-find-file)))
    (:dired-mode-map :package daanturo-dired (("r" . daanturo-dired-do-rename)))
    (:dired-mode-map
      :package
      daanturo-dired
      (("_" . daanturo-dired-delete-no-trash)))
    (:dired-mode-map
      :package dired
      (("C-c w" . dired-copy-filename-as-kill)
        ("e" . wdired-change-to-wdired-mode)
        ("h" . diredp-dired-recent-dirs)
        ("C-c M-s" . dired-do-isearch)
        ("$" . eshell)
        ;; previous eww-open-file but it prompts
        ("w" . browse-url-of-dired-file)
        ("E" . redguardtoo-ediff-files)
        ("@" . dired-run-command)
        ("l" . nil)
        ("l" . dired-up-directory)
        (";" . dired-next-subdir)))) ;; dired-do-redisplay
  :custom
  (
    (dired-listing-switches
      .
      "-iafxhlvs --group-directories-first --time-style=long-iso")
    (dired-free-space-args . "-ph")
    ;; which files not to display
    (dired-omit-files . "^\\.\\|^#.*#$")
    ;; which directories to track
    (dirtrack-list . '("^[^:]*:\\(?:\e\\[[0-9]+m\\)?\\([^$#\e]+\\)" 1))
    (ls-lisp-ignore-case . t)
    (ls-lisp-dirs-first . t)
    (dired-dwim-target . t)
    ;; use system's trash can
    (delete-by-moving-to-trash . t)
    ;; don’t delete excess backup versions silently
    (delete-old-versions . t)
    ;; don't hide symbolic link targets
    (wdired-allow-to-change-permissions . nil)
    (wdired-create-parent-directories . t)
    (dired-auto-revert-buffer . #'dired-directory-changed-p)
    (dired-recursive-deletes . 'always)
    (delete-by-moving-to-trash . t)
    (dired-always-read-filesystem . t)
    (dired-vc-rename-file . t)
    (dired-copy-preserve-time . t)
    (dired-recursive-copies . t)
    (dired-clean-confirm-killing-deleted-buffers . nil)
    (dired-kill-when-opening-new-dired-buffer . t)
    (dired-hide-details-hide-symlink-targets . nil)
    (dired-omit-verbose . nil) ;; don't show messages when omitting files
    (dired-recursive-copies . 'always) ;; always copy recursively
    (dired-recursive-deletes . 'always) ;; always delete recursively
    (find-ls-option . '("-print0 | xargs -p4 -0 ls -ldn" . "-ldn"))
    (find-ls-subdir-switches . "-ldn")
    (find-ls-subdir-switches . "-ldn")
    ;; run command depending on os, depending on file-type
    (dired-guess-shell-alist-user
      .
      `
      (
        (
          ,
          (rx
            "."
            (or
              ;; videos
              "mp4"
              "avi"
              "mkv"
              "flv"
              "ogv"
              "ogg"
              "mov"
              ;; music
              "wav"
              "mp3"
              "flac"
              ;; images
              "jpg"
              "jpeg"
              "png"
              "gif"
              "xpm"
              "svg"
              "bmp"
              ;; docs
              "pdf"
              "md"
              "djvu"
              "ps"
              "eps"
              "doc"
              "docx"
              "xls"
              "xlsx"
              "ppt"
              "pptx")
            string-end)
          ,
          (pcase system-type
            ('gnu/linux "xdg-open")
            ('darwin "open")
            ('windows-nt "start")
            (_ "")))))))
