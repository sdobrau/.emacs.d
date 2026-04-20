;;https://mocompute.codeberg.page/item/2024/2024-09-03-emacs-project-vterm.html
(defun my-project-shell ()
  "Start an inferior shell in the current project's root directory.
If a buffer already exists for running a shell in the project's root,
switch to it.  Otherwise, create a new shell buffer.
With \\[universal-argument] prefix arg, create a new inferior shell buffer even
if one already exists."
  (interactive)
  (require 'comint)
  (let*
    (
      (default-directory (project-root (project-current t)))
      (default-project-shell-name (project-prefixed-buffer-name "shell"))
      (shell-buffer (get-buffer default-project-shell-name)))
    (if (and shell-buffer (not current-prefix-arg))
      (if (comint-check-proc shell-buffer)
        (pop-to-buffer shell-buffer
          (bound-and-true-p display-comint-buffer-action))
        (vterm shell-buffer))
      (vterm (generate-new-buffer-name default-project-shell-name)))))

(advice-add 'project-shell :override #'my-project-shell)

(leaf find-file-in-project
  :ensure t
  :custom (ffip-use-rust-fd . t)
  :bind
  (:project-prefix-map
    (("f" . find-file-in-project)
      ("d" . find-directory-in-project-by-selected))))

;; TODO: rest project functions
;; TODO: fix. completely broken
(leaf isearch-project
  :ensure t
  :bind
  (:project-prefix-map
    :package
    project
    (("C-s" . isearch-project-forward-symbol-at-point))))
