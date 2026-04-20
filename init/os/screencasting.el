;; TODO: gif-screencast but for wayland
;; (leaf gif-screencast
;;   :ensure t
;;   :bind (("C-M-c ` g
;;  s" . gif-screencast)
;;    ("C-M-c ` g e" . gif-screencast-stop))
;;   :config
;;   (setq gif-screencast-output-directory
;;  (no-littering-expand-var-file-name "screencast/")))

;; TODO: escr but for wayland
;; (leaf escr
;;   :quelpa (escr
;;            :fetcher github
;;            :repo "atykhonov/escr")
;;   :commands escr-window-screenshot escr-frame-screenshot escr-region-screenshot
;;   :bind (("M-s p f" . escr-frame-screenshot)
;;          ("M-s p w" . escr-window-screenshot)
;;          ("M-s p r" . escr-region-screenshot))
;;   :config (setq escr-screenshot-directory
;;    (no-littering-expand-var-file-name "screenshots/")))
