;; -*- lexical-binding: t -*-

(require 'shr)

;;; mine:
;;;; get shr image at point
;;;;; little utility

(defun shr-get-last-node-of-url (url)
  (-last-item (s-split
               "/"
               url)))

(defun shr-get-extension-of-image-url (url)
  (-last-item (s-split "\\." url)))

;;;; get links

(defun my-shr-collect-links (&optional url)
  (interactive "p")
  (let* ((urls '()))
    (while
        (goto-char
         (prop-match-beginning
          (unwind-protect
              (text-property-search-forward 'shr-url nil nil t)))
         (push (get-text-property (point) 'help-echo) urls)))))

;;;; TODO: previous/next link skipping forms
;;; from some blog post i forgot lol

(defun shr-tag-dfn (dom)
  (shr-fontize-dom dom 'italic))

;; Inspired from shr-tag-em
(defun shr-tag-cite (dom)
  (shr-fontize-dom dom 'italic))

;; Inspired from shr-tag-a
(defun shr-tag-q (dom)
  (shr-insert "“")
  (shr-generic dom)
  (shr-insert "”"))

;; Drawing inspiration from shr-tag-h1
(defun shr-tag-small (dom)
  (shr-fontize-dom
   dom (if shr-use-fonts '(variable-pitch (:height 0.8)))))

;; Drawing inspiration from shr-tag-abbr
(defun shr-tag-time (dom)
  (when-let* ((datetime (or
                         (dom-attr dom 'title)
                         (dom-attr dom 'datetime)))
              (start (point)))
    (shr-generic dom)
    (shr-add-font start (point) 'shr-abbreviation)
    (add-text-properties
     start (point)
     (list
      'help-echo datetime
      'mouse-face 'highlight))))

;;; jao: fixes for image rendering

(defun jao-shr--kill-nl (p)
  (save-excursion
    (goto-char p)
    (when (looking-at-p "\n") (delete-char 1))))

(defun jao-shr-tag-img (fn &rest args)
  (let ((p (point)))
    (prog1 (apply fn args)
      (when (> (point) p) (jao-shr--kill-nl p)))))

(defun jao-shr-insert (fn &rest args)
  (let ((p (when (and (not (bolp))
                      (get-text-property (1- (point)) 'image-url))
             (point))))
    (prog1 (apply fn args)
      (when (and p (> (point) p)) (jao-shr--kill-nl p)))))

(advice-add 'shr-tag-img :around #'jao-shr-tag-img)
(advice-add 'shr-insert :around #'jao-shr-insert)

;;; jf?

;; EWW lacks a style for article
(defun shr-tag-article (dom)
  (shr-ensure-paragraph)
  (shr-generic dom)
  (shr-ensure-paragraph))

;; EWW lacks a style for section; This is quite provisional
(defun shr-tag-section (dom)
  (shr-ensure-paragraph)
  (shr-generic dom)
  (shr-ensure-paragraph))



(provide 'shr-extras)
