;; -*- lexical-binding: t -*-

;;; mine

(defun new-line-below-and-indent ()
  "Insert a new-line just below POINT, and move the point there."
  (interactive)
  (end-of-line)
  (newline-and-indent))

;;; from kf

(defun kf-fill-paragraph (&optional justify)
  "Like fill-paragraph, but don't mark the buffer as modified if no change.

Emacs's native fill-paragraph is like the burglar who breaks into
your house, rearranges all your furniture exactly as it was, and
departs: even if the result of the fill is to leave the buffer in
exactly the same state, it still marks the buffer as modified so you
know you've been broken into.

Note: to get this accepted into Emacs, it should watch the md5sum for
just the affected region rather than the entire buffer.  See
`fill-region' and `fill-region-as-paragraph' in textmodes/fill.el.
The elegant solution would be a new macro, '(detect-buffer-unmodified
from to)' or something, that just wraps the relevant body of code in
those two functions.  Then it could be used by other fill functions
easily too."
  (interactive "P")
  (let ((orig-md5sum (md5 (current-buffer)))
        (was-modified-before-fill (buffer-modified-p)))
    (fill-paragraph justify)
    (let ((new-md5sum (md5 (current-buffer))))
      (when (string-equal orig-md5sum new-md5sum)
        (set-buffer-modified-p was-modified-before-fill)))))

;;; adam

;; https://adam.kruszewski.name/2022-05-08-backward-kill-word-or-join-lines.html

;;;###autoload
(defun backward-kill-word-or-join-lines ()
  "Backward-kill-word that will join lines if there is no word on a current line to kill."
  (interactive)
  (let ((orig-point (point))
        (orig-column (current-column))
        (start-line (line-number-at-pos)))

    (backward-word)
    (if (> start-line (line-number-at-pos))
        (progn
          (goto-char orig-point)
          (delete-backward-char orig-column)
          (when (= orig-column 0)
            (delete-char -1)))
      (kill-region (point) orig-point))))

;;; daanturo

;;;###autoload
(defun daanturo-open-new-indented-line (&optional arg)
  (interactive "P")
  (save-excursion
    (newline-and-indent arg)))

;;;###autoload
(defun daanturo-open-then-new-indented-line ()
  (interactive)
  (save-excursion (open-line 1))
  (newline-and-indent))

;;;###autoload
(defun daanturo-mark-inner-paragraph ()
  "Mark current paragraph without the first empty line."
  (interactive)
  (if (use-region-p)
      (user-error "Active region!")
    (progn
      (mark-paragraph)
      (skip-chars-forward "\n"))))

;;;###autoload
(defun daanturo-recenter-region-in-window ()
  (interactive)
  (recenter-top-bottom
   (max 0
        (floor (/ (- (window-height)
                     (if (use-region-p)
                         (count-lines (region-beginning)
                                      (region-end))
                       0))
                  2)))))

;;;###autoload
(defun daanturo-recenter-left-right ()
  "Move current buffer column to the specified window column."
  (interactive)
  (set-window-hscroll (selected-window)
                      (- (current-column) (/ (window-width) 2))))


;;;###autoload
(defun daanturo-insert-and-copy-date ()
  "Insert current date in ISO format."
  (interactive)
  (daanturo-insert-and-copy (format-time-string "%F" (current-time))))

;;;###autoload
(defun daanturo-insert-and-copy-date-and-time ()
  "Insert current date & time."
  (interactive)
  (daanturo-insert-and-copy (format-time-string "%F %H:%M:%S" (current-time))))

;;;###autoload
(defun daanturo-query-replace-regexp-in-whole-buffer ()
  (interactive)
  (save-excursion
    (unless (use-region-p)
      (daanturo-add-advice-once #'query-replace-read-args :after
        (daanturo-fn% (goto-char (point-min)))))
    ;; `anzu' isn't compatible OOTB
    (call-interactively #'query-replace-regexp)))

;;; from excalamus: convert bs to fs / \

;; (defun xc/convert-slashes (&optional beg end)
;;   "Convert backslashes to forward slashes.

;; Only convert within region defined by BEG and END.  Use current
;; line if no region is provided."
;;   (interactive)
;;   (let* ((beg (or beg (if (use-region-p) (region-beginning)) (line-beginning-position)))
;;         (end (or end (if (use-region-p) (region-end)) (line-end-position))))
;;     (subst-char-in-region beg end ?// ?/)
;;     (replace-string "//" "/" nil beg end)))
;; TODO: invalid read syntax ?

;;; from junkw: kill-word-dwim

;;;###autoload
(defun kill-word-dwim (arg)
  "Call the `kill-word'  you want (Do What I Mean).

With argument ARG, do kill commands that many times."
  (interactive "p")
  (cond ((and (called-interactively-p 'any) transient-mark-mode mark-active)
         (kill-region (region-beginning) (region-end)))
        ((eobp)
         (backward-kill-word arg))
        (t
         (let ((char (char-to-string (char-after (point)))))
           (cond ((string-match "\n" char)
                  (delete-char 1) (delete-horizontal-space))
                 ((string-match "[\t ]" char)
                  (delete-horizontal-space))
                 ((string-match "[-@\[-`{-~]" char)
                  (kill-word arg))
                 (t
                  (beginning-of-thing 'word) (kill-word arg)))))))



(provide 'editing-extras)
