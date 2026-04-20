;; -*- lexical-binding: t -*-

(leaf
  grep
  :after wgrep rg
  :bind
  (
    (:wgrep-mode-map
      (("C-c C-c" . save-buffer)) ;; echo magit behaviour. jeremyf
      (:ripgrep-search-mode-map (("e" . wgrep-change-to-wgrep-mode)))
      (:grep-mode-map (("e" . wgrep-change-to-wgrep-mode)))
      ("C-c C-c" . wgrep-finish-edit))))

(leaf wgrep :bind (:wgrep-mode-map ("C-c ESC" . wgrep-abort-changes)))

(leaf
  rg
  :if (executable-find "rg")
  :custom (rg-use-transient-menu . nil)
  :bind (("M-s x" . rg-dwim-project-dir) ("M-s C-x" . rg-dwim-current-dir)))
;; TODO: keys not working
;; (:rg-mode-map
;;   (("M-n" . rg-next-file)
;;     ("M-p" . rg-prev-file)
;;     ("h" . rg-list-searches)
;;     ("d" . rg-rerun-change-dir)
;;     ("s" . rg-rerun-change-query)
;;     ("r" . rg-rerun-change-regexp)
;;     ("f" . rg-rerun-change-files)
;;     ("q" . rg-kill-current)
;;     ("k" . kill-current-buffer)))))
