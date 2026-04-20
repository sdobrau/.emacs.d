;;; spatial-navigate.el --- Directional navigation between blank-space blocks -*- lexical-binding: t -*-

;; SPDX-License-Identifier: GPL-2.0-or-later
;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://codeberg.org/ideasman42/emacs-spatial-navigate
;; Package-Version: 20260412.1442
;; Package-Revision: cf99831bba08
;; Package-Requires: ((emacs "29.1"))

;;; Commentary:

;; Support jumping horizontally and vertically
;; across blocks of blank-space or non-blank-space.

;;; Usage:

;; ;; This shows how Alt-arrow keys can be used for directional navigation.
;; (global-set-key (kbd "<M-up>") 'spatial-navigate-backward-vertical-bar)
;; (global-set-key (kbd "<M-down>") 'spatial-navigate-forward-vertical-bar)
;; (global-set-key (kbd "<M-left>") 'spatial-navigate-backward-horizontal-bar)
;; (global-set-key (kbd "<M-right>") 'spatial-navigate-forward-horizontal-bar)

;; ;; If you use evil-mode, the 'box' navigation functions make sense in normal mode,
;; ;; while the 'bar' functions make the most sense in insert mode.

;; (define-key evil-normal-state-map (kbd "M-k") 'spatial-navigate-backward-vertical-box)
;; (define-key evil-normal-state-map (kbd "M-j") 'spatial-navigate-forward-vertical-box)
;; (define-key evil-normal-state-map (kbd "M-h") 'spatial-navigate-backward-horizontal-box)
;; (define-key evil-normal-state-map (kbd "M-l") 'spatial-navigate-forward-horizontal-box)
;; (define-key evil-insert-state-map (kbd "M-k") 'spatial-navigate-backward-vertical-bar)
;; (define-key evil-insert-state-map (kbd "M-j") 'spatial-navigate-forward-vertical-bar)
;; (define-key evil-insert-state-map (kbd "M-h") 'spatial-navigate-backward-horizontal-bar)
;; (define-key evil-insert-state-map (kbd "M-l") 'spatial-navigate-forward-horizontal-bar)

;;; Code:

;; ---------------------------------------------------------------------------
;; Compatibility

(eval-when-compile
  (when (version< emacs-version "31.1")
    (defmacro incf (place &optional delta)
      "Increment PLACE by DELTA or 1."
      (declare (debug (gv-place &optional form)))
      (gv-letplace (getter setter) place
        (funcall setter `(+ ,getter ,(or delta 1)))))
    (defmacro decf (place &optional delta)
      "Decrement PLACE by DELTA or 1."
      (declare (debug (gv-place &optional form)))
      (gv-letplace (getter setter) place
        (funcall setter `(- ,getter ,(or delta 1)))))))


;; ---------------------------------------------------------------------------
;; Custom Variables

(defcustom spatial-navigate-wrap-horizontal-motion nil
  "Skip blank lines when horizontal motion reaches line bounds."
  :group 'spatial-navigate
  :type 'boolean)


;; ---------------------------------------------------------------------------
;; Evil Mode Support

(defun spatial-navigate--evil-visual-mode-workaround (state)
  "Workaround for evil-visual line mode, STATE must be \\='pre or \\='post."
  (declare (important-return-value nil))
  (when (and (fboundp 'evil-visual-state-p)
             (funcall #'evil-visual-state-p)
             (fboundp 'evil-visual-type)
             (eq (funcall #'evil-visual-type) 'line)
             (boundp 'evil-visual-point))
    (let ((mark (symbol-value 'evil-visual-point)))
      (when (markerp mark)
        (cond
         ;; Without this, `point' will be at the beginning of the line
         ;; (from the pre command hook).
         ((eq state 'pre)
          (goto-char mark))
         ;; Without this, the `point' won't move.
         ;; See: https://github.com/emacs-evil/evil/issues/1708
         ((eq state 'post)
          (set-marker mark (point)))
         (t
          (error "Invalid input, internal error")))))))


;; ---------------------------------------------------------------------------
;; Private Functions

(defun spatial-navigate--char-filled-p (pos beg end default)
  "Return non-nil if POS contains a non-blank-space character.
BEG and END are line bounds.  DEFAULT is returned if POS is out of range."
  (declare (important-return-value t))
  (cond
   ((and (>= pos beg) (< pos end))
    (let ((ch (char-after pos)))
      (not (memq ch '(?\s ?\t)))))
   (t
    default)))

(defun spatial-navigate--resolve-block-cursor (is-block-cursor)
  "Return IS-BLOCK-CURSOR adjusted for rectangle selection.
When `rectangle-mark-mode' is active, use box behavior (return t),
unless the rectangle has zero width, then use bar behavior (return nil)."
  (declare (important-return-value t))
  (cond
   ((bound-and-true-p rectangle-mark-mode)
    (not
     (= (current-column)
        (save-excursion
          (goto-char (mark))
          (current-column)))))
   (t
    is-block-cursor)))

(defun spatial-navigate--vertical-calc (dir is-block-cursor)
  "Calculate the next/previous vertical position based on DIR (-1 or 1).

Argument IS-BLOCK-CURSOR causes the cursor to detect blank-space using
characters before and after the current cursor.  This behaves in a way that
is logical for a block cursor."
  (declare (important-return-value t))
  (spatial-navigate--evil-visual-mode-workaround 'pre)

  (let ((result nil)
        (result-fallback (cons 0 (point)))
        (lines 0)
        (lines-prev 0)
        (is-first t)
        (is-empty-state nil)
        (pos-prev (point))
        (col-init (current-column)))
    (while (null result)

      ;; Step to next line and move to column.
      (forward-line dir)
      (incf lines dir)

      (let* ((col (move-to-column col-init))
             (is-empty
              (or (< col col-init)
                  ;; End of the line is also considered empty.
                  (and (or (zerop col-init) is-block-cursor) (eolp))

                  ;; Avoid delimiting on spaces between words by checking
                  ;; if we're surrounded by spaces before and after.
                  (let* ((pos-eol (pos-eol))
                         (pos-bol (pos-bol))

                         (is-fill-curr
                          (spatial-navigate--char-filled-p (point) pos-bol pos-eol nil))
                         (is-fill-prev
                          (spatial-navigate--char-filled-p
                           (- (point) 1) pos-bol pos-eol is-fill-curr))
                         (is-fill-next
                          (spatial-navigate--char-filled-p
                           (+ (point) 1) pos-bol pos-eol is-fill-curr)))

                    (cond
                     ;; Check three characters: current char, before, and after.
                     ;; Empty if current is blank and at least one neighbor is also blank.
                     (is-block-cursor
                      (null (or is-fill-curr (and is-fill-prev is-fill-next))))

                     ;; Check only two characters: current and previous.
                     (t
                      (null (or is-fill-curr is-fill-prev))))))))

        ;; Keep searching for whatever we encounter first.
        (when is-first
          (setq is-empty-state is-empty)
          (setq is-first nil))

        ;; Either set the result, or continue looping.
        (cond
         ((null (eq is-empty is-empty-state))
          ;; We have hit a different state, stop!
          (setq result
                (cond
                 (is-empty-state
                  (cons lines (point)))
                 (t
                  (cons lines-prev pos-prev)))))
         ((eq pos-prev (point))
          ;; Point didn't move, we're at buffer boundary.
          (setq result result-fallback))
         (t ; Keep looping.
          ;; If we reach the beginning or end of the document,
          ;; use the last time we reached a valid column.
          (when (eq col col-init)
            (setq result-fallback (cons lines (point))))
          (setq lines-prev lines)
          (setq pos-prev (point))))))
    result))


(defun spatial-navigate--vertical-calc-rect-prev (dir)
  "Calculate the vertical position for rectangle selection when point < mark column.
DIR is -1 or 1.  Point is at the left edge of the rectangle,
so no column offset is needed."
  (declare (important-return-value t))
  (spatial-navigate--vertical-calc dir t))

(defun spatial-navigate--vertical-calc-rect-next (dir)
  "Calculate the vertical position for rectangle selection when point > mark column.
DIR is -1 or 1.  Point is one column past the right edge of the rectangle,
so blank detection uses the column before point."
  (declare (important-return-value t))
  (spatial-navigate--evil-visual-mode-workaround 'pre)

  (let ((result nil)
        (result-fallback (cons 0 (point)))
        (lines 0)
        (lines-prev 0)
        (is-first t)
        (is-empty-state nil)
        (pos-prev (point))
        (col-init (current-column))
        (col-detect (1- (current-column))))
    (while (null result)

      ;; Step to next line and move to column.
      (forward-line dir)
      (incf lines dir)

      (let* ((col (move-to-column col-detect))
             (is-empty
              (or (< col col-detect)
                  ;; End of the line is also considered empty.
                  (eolp)

                  ;; Avoid delimiting on spaces between words by checking
                  ;; if we're surrounded by spaces before and after.
                  (let* ((pos-eol (pos-eol))
                         (pos-bol (pos-bol))

                         (is-fill-curr
                          (spatial-navigate--char-filled-p (point) pos-bol pos-eol nil))
                         (is-fill-prev
                          (spatial-navigate--char-filled-p
                           (- (point) 1) pos-bol pos-eol is-fill-curr))
                         (is-fill-next
                          (spatial-navigate--char-filled-p
                           (+ (point) 1) pos-bol pos-eol is-fill-curr)))

                    (or
                     ;; Check three characters: current char, before, and after.
                     ;; Empty if current is blank and at least one neighbor is also blank.
                     (null (or is-fill-curr (and is-fill-prev is-fill-next)))

                     ;; The character at the original column must also be filled.
                     (null (spatial-navigate--char-filled-p (1+ (point)) pos-bol pos-eol nil)))))))

        ;; Restore to the original column for result positions.
        (move-to-column col-init)

        ;; Keep searching for whatever we encounter first.
        (when is-first
          (setq is-empty-state is-empty)
          (setq is-first nil))

        ;; Either set the result, or continue looping.
        (cond
         ((null (eq is-empty is-empty-state))
          ;; We have hit a different state, stop!
          (setq result
                (cond
                 (is-empty-state
                  (cons lines (point)))
                 (t
                  (cons lines-prev pos-prev)))))
         ((eq pos-prev (point))
          ;; Point didn't move, we're at buffer boundary.
          (setq result result-fallback))
         (t ; Keep looping.
          ;; If we reach the beginning or end of the document,
          ;; use the last time we reached a valid column.
          (when (eq col col-detect)
            (setq result-fallback (cons lines (point))))
          (setq lines-prev lines)
          (setq pos-prev (point))))))
    result))


(defun spatial-navigate--horizontal-calc (dir is-block-cursor)
  "Calculate the next/previous horizontal position based on DIR (-1 or 1).

Argument IS-BLOCK-CURSOR causes the cursor to detect blank-space using
characters before and after the current cursor.  This behaves in a way that
is logical for a block cursor."
  (declare (important-return-value t))
  (spatial-navigate--evil-visual-mode-workaround 'pre)

  (let ((result nil)
        (is-first t)
        (is-empty-state nil)
        (pos-prev (point))

        (pos-eol (pos-eol))
        (pos-bol (pos-bol)))

    ;; Initial step is needed here because forward-char requires explicit call,
    ;; whereas forward-line in vertical-calc implicitly moves to the next line.
    (when (cond
           ((< dir 0)
            (> pos-prev pos-bol))
           (t
            (<= pos-prev pos-eol)))
      (forward-char dir))

    (while (null result)
      (let ((is-empty
             ;; Avoid delimiting on spaces between words by checking
             ;; if we're surrounded by spaces before and after.
             (let* ((is-fill-curr (spatial-navigate--char-filled-p (point) pos-bol pos-eol nil))
                    (is-fill-prev
                     (spatial-navigate--char-filled-p (- (point) 1) pos-bol pos-eol is-fill-curr))
                    (is-fill-next
                     (spatial-navigate--char-filled-p (+ (point) 1) pos-bol pos-eol is-fill-curr)))
               (null (or is-fill-curr (and is-fill-prev is-fill-next))))))

        ;; Keep searching for whatever we encounter first.
        (when is-first
          (setq is-empty-state is-empty)
          (setq is-first nil))

        ;; Either set the result, or continue looping.
        (cond
         ((null (eq is-empty is-empty-state))
          ;; We have hit a different state, stop!
          (setq result
                (cond
                 (is-block-cursor
                  (cond
                   (is-empty-state
                    (point))
                   (t
                    pos-prev)))
                 (t
                  (cond
                   ((> dir 0)
                    (point))
                   (t
                    pos-prev))))))
         ((eq pos-prev (point))
          ;; Point didn't move, we're at buffer boundary.
          (setq result (point)))
         ;; If we get out of range, use last usable point.
         ((cond
           ((< dir 0)
            (< (point) pos-bol))
           (t
            (>= (point) pos-eol)))
          ;; Point moved past line bounds, use previous valid position.
          (setq result pos-prev))
         (t ; Keep looping.
          ;; If we reach the beginning or end of the line, we may need to use this.
          (setq pos-prev (point))
          (when (cond
                 ((< dir 0)
                  (> pos-prev pos-bol))
                 (t
                  (<= pos-prev pos-eol)))
            ;; Step to next character.
            (forward-char dir))))))
    result))


;; ---------------------------------------------------------------------------
;; Wrapper Functions

(defun spatial-navigate--vertical (dir is-block-cursor)
  "See `spatial-navigate--vertical-calc' for docs on DIR and IS-BLOCK-CURSOR.

When DIR is outside the -1/1 range, motion will run multiple times.

Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed."
  (declare (important-return-value nil))

  ;; Determine the calc function once before the loop.
  ;; Rectangle mode overrides: point > mark col uses rect-next,
  ;; point < mark col uses rect-prev, equal cols uses bar behavior.
  (let ((calc-fn
         (cond
          ((bound-and-true-p rectangle-mark-mode)
           (let ((col-point (current-column))
                 (col-mark
                  (save-excursion
                    (goto-char (mark))
                    (current-column))))
             (cond
              ((> col-point col-mark)
               #'spatial-navigate--vertical-calc-rect-next)
              ((< col-point col-mark)
               #'spatial-navigate--vertical-calc-rect-prev)
              (t
               (setq is-block-cursor nil)
               nil))))
          (t
           nil)))
        (times (abs dir))
        (keep-searching t)
        (changed nil))
    (cond
     ((eq times dir)
      (setq dir 1))
     (t
      (setq dir -1)))

    (while (and keep-searching
                (null
                 (zerop
                  (prog1 times
                    (decf times)))))
      (pcase-let ((`(,lines . ,pos-next)
                   (save-excursion
                     (cond
                      (calc-fn
                       (funcall calc-fn dir))
                      (t
                       (spatial-navigate--vertical-calc dir is-block-cursor))))))
        (cond
         ((zerop lines)
          (setq keep-searching nil))
         (t
          (setq changed t)
          (goto-char pos-next)))))

    (cond
     (changed
      (spatial-navigate--evil-visual-mode-workaround 'post)
      (* times dir))
     (t
      (message "Spatial-navigate: no lines to jump to!")
      nil))))

(defun spatial-navigate--horizontal (dir is-block-cursor)
  "See `spatial-navigate--horizontal-calc' for docs on DIR and IS-BLOCK-CURSOR."
  (declare (important-return-value nil))
  (setq is-block-cursor (spatial-navigate--resolve-block-cursor is-block-cursor))
  (let ((times (abs dir))
        (keep-searching t)
        (changed nil))
    (cond
     ((eq times dir)
      (setq dir 1))
     (t
      (setq dir -1)))

    (while (and keep-searching
                (null
                 (zerop
                  (prog1 times
                    (decf times)))))

      (let ((pos-next (save-excursion (spatial-navigate--horizontal-calc dir is-block-cursor))))

        ;; Optionally skip over blank lines.
        (when spatial-navigate-wrap-horizontal-motion
          (when (zerop (- pos-next (point)))
            (save-excursion
              (when (zerop (forward-line dir))
                ;; Skip blank lines.
                (while (and (looking-at-p "[[:blank:]]*$") (zerop (forward-line dir))))
                (setq pos-next
                      (cond
                       ((< dir 0)
                        (pos-eol))
                       (t
                        (pos-bol))))))))
        (cond
         ((zerop (- pos-next (point)))
          (setq keep-searching nil))
         (t
          (setq changed t)
          (goto-char pos-next)))))

    (cond
     (changed
      (spatial-navigate--evil-visual-mode-workaround 'post)
      (* times dir))
     (t
      (message "Spatial-navigate: boundary reached!")
      nil))))


;; ---------------------------------------------------------------------------
;; Public Functions

;; Vertical motion.

;;;###autoload
(defun spatial-navigate-forward-vertical-box (arg)
  "Jump forward vertically ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a box cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--vertical arg t))
   ((< arg 0)
    (spatial-navigate-backward-vertical-box (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-backward-vertical-box (arg)
  "Jump backward vertically ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a box cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--vertical (- arg) t))
   ((< arg 0)
    (spatial-navigate-forward-vertical-box (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-forward-vertical-bar (arg)
  "Jump forward vertically ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a bar cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--vertical arg nil))
   ((< arg 0)
    (spatial-navigate-backward-vertical-bar (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-backward-vertical-bar (arg)
  "Jump backward vertically ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a bar cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--vertical (- arg) nil))
   ((< arg 0)
    (spatial-navigate-forward-vertical-bar (- arg)))
   (t
    nil)))

;; Horizontal motion.

;;;###autoload
(defun spatial-navigate-forward-horizontal-box (arg)
  "Jump forward horizontally ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a box cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--horizontal arg t))
   ((< arg 0)
    (spatial-navigate-backward-horizontal-box (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-backward-horizontal-box (arg)
  "Jump backward horizontally ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a box cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--horizontal (- arg) t))
   ((< arg 0)
    (spatial-navigate-forward-horizontal-box (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-forward-horizontal-bar (arg)
  "Jump forward horizontally ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a bar cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--horizontal arg nil))
   ((< arg 0)
    (spatial-navigate-backward-horizontal-bar (- arg)))
   (t
    nil)))

;;;###autoload
(defun spatial-navigate-backward-horizontal-bar (arg)
  "Jump backward horizontally ARG times across blank-space and non-blank-space.
A negative ARG reverses the motion.
Return the number of steps remaining (0 when all succeed)
or nil when the motion could not be performed.

Use for a bar cursor."
  (declare (important-return-value nil))
  (interactive "p")
  (cond
   ((> arg 0)
    (spatial-navigate--horizontal (- arg) nil))
   ((< arg 0)
    (spatial-navigate-forward-horizontal-bar (- arg)))
   (t
    nil)))

(provide 'spatial-navigate)
;; Local Variables:
;; fill-column: 99
;; indent-tabs-mode: nil
;; End:
;;; spatial-navigate.el ends here
