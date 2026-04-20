;; -*- lexical-binding: t -*-

;;; daanturo

;;;###autoload
(defun daanturo-transpose-line-and-swap-comment-status ()
  (interactive)
  (save-excursion (comment-line 1))
  (daanturo-save-line-col (transpose-lines 1))
  (save-excursion (comment-line 1)))



(provide 'comment-extras)
