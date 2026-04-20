;; -*- lexical-binding: t -*-

(lossage-size 5000)

;; Functions are redefined without warning.
(leaf advice :custom (ad-redefinition-action . 'accept))

(leaf
  crux
  :ensure t
  :bind
  (("C-x C-M-d" . crux-recentf-find-directory)
    ("C-x M-s-k" . crux-kill-other-buffers)
    (:prog-mode-map
      (("C-a" . crux-move-beginning-of-line) ("C-c C-j" . crux-top-join-line)))
    (:text-mode-map
      (("C-a" . crux-move-beginning-of-line)
        ("C-o" . crux-smart-open-line-above)))))

(leaf everlasting-scratch :ensure t)

;; View large files
(leaf
  vlf
  :ensure t
  :commands vlf
  :custom
  ((vlf-batch-size . 5242880) ; 5 MB
    (large-file-warning-threshold . 90000000)) ;; 90 MB
  :config (require 'vlf-setup))

(leaf
  consult-todo
  :quelpa (consult-todo :fetcher github :repo "liuyinz/consult-todo")
  :bind (("M-s t" . consult-todo-all) ("M-s T" . consult-todo-project)))

;; for popup-switcher
(leaf flx-ido :ensure t :require t)

;; ;; etc
;; (leaf
;;   popup-switcher
;;   :quelpa (popup-switcher :fetcher github :repo "sdobrau/popup-switcher")
;;   :custom
;;   ((psw-popup-position . 'point)
;;     (psw-use-flx . t)
;;     (psw-highlight-previous-buffer . t))
;;   :bind
;;   (("C-x b" . psw-switch-buffer)
;;     ("C-x t RET" . psw-switch-tab)
;;     ("C-x ," . psw-switch-project-files)))

(leaf
  hide-lines
  :ensure t
  :bind (("C-c h" . hide-lines) ("C-c C-h" . hide-lines-show-all)))

(leaf
  outline
  :bind
  (:outline-mode-map
    (("M-<up>" . nil)
      ("M-<down>" . nil)
      ("C-M-u" . outline-up-heading)
      ("C-M-n" . outline-next-heading)
      ("C-M-p" . outline-previous-heading)
      ("C-M-f" . outline-forward-same-level)
      ("C-M-b" . outline-backward-same-level))))

(leaf lte :ensure t)
;; TODO: think key

;;; gentoo

;;; life
