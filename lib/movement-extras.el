;; -*- lexical-binding: t -*-

;;; from koekelas

;;;###autoload
(defun koek-mtn/next-word (&optional arg)
       "Move point to beginning of next word, repeat ARG times.
  Optional ARG is an integer and defaults to one.  When ARG is
  negative, move point to ending of previous word."
       (interactive "p")
       (unless arg
               (setq arg 1))
  (unless (= arg 0)
                  (let ((step (/ arg (abs arg))))
      (when (or (and (> step 0) (looking-at (rx word)))
                                      (and (< step 0)
                     (looking-back (rx word) (max (1- (point)) (point-min)))))
        (forward-word step))
                       (forward-word (- arg step))
      (when (forward-word step)
        (backward-word step)))))

;;;###autoload
(defun koek-mtn/previous-word (&optional arg)
       "Move point to ending of previous word, repeat ARG times.
  Optional ARG is an integer and defaults to one.  When ARG is
  negative, move point to beginning of next word."
       (interactive "p")
       (unless arg
               (setq arg 1))
       (koek-mtn/next-word (- arg)))

;;; from zk-phi: smart next-prev-line
;; TODO: don't go to end of line on blank line
;;;###autoload
(defun zk-phi-next-line (n)
       (interactive "p")
       (call-interactively 'next-line)
       (when (looking-back "^[\s\t]*" (point-at-bol))
             (let (goal-column) (back-to-indentation))))
;;;###autoload
(defun zk-phi-previous-line (n)
       (interactive "p")
       (call-interactively 'previous-line)
       (when (looking-back "^[\s\t]*" (point-at-bol))
             (let (goal-column) (back-to-indentation))))

;; TODO: ok?
(defun xah--forward-real-double-quote ()
       (interactive)
       (search-forward-regexp "\\s\"")
       (while (looking-back "\\\\\"")
              (search-forward-regexp "\\s\"")))

(defun xah--backward-real-double-quote ()
       (interactive)
       (search-backward-regexp "\\s\"")
       (while (looking-at "\\\\\"")
              (search-backward-regexp "\\s\"")))



(provide 'movement-extras)
