;; -*- lexical-binding: t -*-

;;; mine

;;;###autoload
(defun backward-kill-superword (arg)
  "Kill superword backwards."
  (interactive "p")
  (let ((beg (point)))
    (superword-mode)
    (backward-word)
    (delete-region beg (point))
    (subword-mode)))



(provide 'subword-extras)
