;; test
(leaf alert :ensure t)

(leaf
  quick-peek ; flycheck-inline
  :ensure t
  :commands
  quick-peek-update
  quick-peek-hide
  quick-peek-overlay-contents
  quick-peek-overlay-ensure-at)

(leaf mini-popup :if (display-graphic-p) :ensure t)

(leaf posframe :if (display-graphic-p) :ensure t)

(leaf
  popup ; google-translate / define-it / imenu-popup
  :ensure t
  ;; TODO: lazy
  :require t
  :config
  (defun sd/popup-change-colors-on-theme-change (&optional theme)

    (set-face-attribute 'popup-face nil
      :background (face-attribute 'corfu-default :background))
    (set-face-attribute 'popup-face nil
      :foreground (face-attribute 'corfu-default :foreground))

    (set-face-attribute 'popup-menu-selection-face nil
      :inherit 'corfu-current
      :background)
    (set-face-attribute 'popup-isearch-match nil
      :inherit 'corfu-current
      :background)
    (set-face-attribute 'popup-isearch-match nil
      :inherit 'corfu-current
      :foreground))
  (sd/popup-change-colors-on-theme-change)
  :hook (enable-theme-functions . sd/popup-change-colors-on-theme-change)
  :commands popup-create)

(leaf
  popup-imenu
  :quelpa (popup-imenu :fetcher github :repo "ancane/popup-imenu")
  :custom (popup-imenu-style . 'indent)
  :bind (("M-g i" . popup-imenu) ("M-g q" . imenu)))
