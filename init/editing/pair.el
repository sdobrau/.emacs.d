(leaf
  smart-hungry-delete
  :init (smart-hungry-delete-add-default-hooks)
  :ensure t
  :bind (("C-d" . smart-hungry-delete-forward-char))
  :hook ((text-mode-hook . smart-hungry-delete-default-text-mode-hook)))

(leaf
  replace
  :custom (list-matching-lines-jump-to-current-line . t)
  :hook (occur-mode-hook . hl-line-mode)
  :bind (:occur-mode-map (("t" . toggle-truncate-lines))))
