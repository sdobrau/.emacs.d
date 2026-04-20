(leaf imenu-list
  :ensure t
  :bind ("M-s i" . imenu-list-smart-toggle)
  :custom ((imenu-list-position . 'left)
           (imenu-list-idle-update-delay . 999999) ;;lol
           (imenu-list-size . 60)
           (imenu-list-focus-after-activation . t)
           (imenu-auto-rescan . nil)))

(leaf imenu-anywhere
  :ensure t
  :config
  ;;;###autoload
  (defun open-project-files-in-background ()
    "Open/find all source files in the background which are tracked by Git."
    (let ((default-directory (vc-root-dir)))
      (save-window-excursion
        (dolist (file (split-string (shell-command-to-string "git ls-files")))
          (unless (find-buffer-visiting file)
            (with-current-buffer (find-file-noselect file)
              (if (equal (get major-mode 'derived-mode-parent) 'prog-mode)
                  (bury-buffer)
                (kill-buffer))))))))

;;;###autoload
  (defun open-project-files-in-background-maybe (&rest _args)
    "Prepare a project-wide `Imenu'."
    (interactive)
    ;; 'vc-root-dir returns nil when not tracked, so checking if (not
    ;; that it is in a list that contains nil) is enough for both
    ;; (non-nil and in the list of fully opened projects)
    (defvar fully-opened-projects '(nil) "List of project paths, each has all tracked files opened.")
    (let ((git-dir (vc-root-dir)))
      (unless (member git-dir fully-opened-projects)
        (open-project-files-in-background)
        (push git-dir fully-opened-projects))))
  (advice-add 'imenu-anywhere :before 'open-project-files-in-background-maybe))
