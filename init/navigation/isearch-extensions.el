(leaf anzu
  :ensure t
  :preface
  ;; deftsp
  (defun tl/anzu-update-mode-line (here total)
    "Custom update function which does not propertize the status."
    (when anzu--state
      (let ((status (cl-case anzu--state
                      (search (format "(%s/%d%s)"
                                      (anzu--format-here-position here total)
                                      total (if anzu--overflow-p "+" "")))
                      (replace-query (format "(%d replace)" total))
                      (replace (format "(%d/%d)" here total)))))
        status)))
  :config
  (setq anzu-mode-line-update-function 'tl/anzu-update-mode-line))

(leaf isearch-other
  :preface
  (defun isearch-forward-other-window (prefix)
    "Function to isearch-forward in other-window."
    (interactive "P")
    (unless (one-window-p)
      (save-excursion
        (let ((next (if prefix -1 1)))
          (other-window next)
          (isearch-forward)
          (other-window (- next))))))

  (defun isearch-backward-other-window (prefix)
    "Function to isearch-backward in other-window."
    (interactive "P")
    (unless (one-window-p)
      (save-excursion
        (let ((next (if prefix 1 -1)))
          (other-window next)
          (isearch-backward)
          (other-window (- next))))))
  :bind (("C-c C-s" . isearch-forward-other-window)
         ("C-c C-r" . isearch-backward-other-window)))
