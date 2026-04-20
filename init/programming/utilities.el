(leaf xref
  :ensure t
  :hook (xref-after-return-hook . recenter)
  :custom (xref-marker-ring . 30)) ; should be enough

;; TODO: what ?
(leaf symbols-outline
  :if (executable-find "ctags")
  :ensure t
  :bind (:prog-mode-map (("M-g s" . symbols-outline-show))))
