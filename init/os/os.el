;; -*- lexical-binding: t -*-

;; TODO: kill off auto update if proced buffer not present in window config
(leaf
  proced
  :ensure nil
  :bind ("C-h -" . proced)
  :custom
  ((proced-auto-update-flag . nil)
    (proced-auto-update-interval . 3))) ;; minimize flag

;; DISABLED
(leaf explain-pause-mode :disabled t :config (explain-pause-mode))

;; Disable the mouse.
(setq-default x-mouse-click-focus-ignore-position t)

;; Expectable behaviour of clipboard. Cut and paste uses the clipboard
;; and primary selection. When killing text outside Emacs, append it
;; to the clipboard as well.

(setq-default
  select-enable-clipboard t
  select-enable-primary t
  save-interprogram-paste-before-kill t)

;; for wayland ‘wl-clipboard’. terminal<->GUI support
(leaf xclip :if (display-graphic-p) :ensure t)

(leaf
  direnv ;; grab
  :ensure t
  :commands direnv-mode
  :config (direnv-mode)
  :custom ((direnv-always-show-summary . t) (direnv-use-faces-in-summary . t)))

;; Not using it at the moment so not enabling it as a global minor mode.
(leaf envrc :ensure t :disabled t)

(leaf
  exec-path-from-shell
  :ensure t
  :custom
  (exec-path-from-shell-variables
    .
    '("MANPATH" "PATH" "MYIP" "XDG_RUNTIME_DIR" "LSP_USE_PLISTS"))
  :config (exec-path-from-shell-initialize))

(leaf
  alsamixer
  :if (executable-find "alsamixer")
  :ensure t
  :bind
  (("C-x c v +" . alsamixer-up-volume)
    ("C-x c v -" . alsamixer-down-volume)
    ("C-x c v _" . alsamixer-toggle-mute)))

;; (leaf mpc
;;   :custom ((mpc-frame-alist . '((name . "MPC")
;;                                 (tool-bar-lines . nil)))
;;            (mpc-browser-tags . '(Artist|Composer|Performer Album|Playlist) )
;;            (mpc-songs-format . "%2{Disc--}%3{Track} %-5{Time} %25{Title} %20{Album} %20{Artist} %5n{Date}"))
;;   :config
;;   (setq mpc-data-directory (no-littering-expand-var-file-name "mpc")))
