;; -*- lexical-binding: t -*-

(leaf frame-center
  :bind ("C-x 5 +" . ct/frame-center))

(leaf fwb-cmds
  :ensure t
  :bind ("C-x 5 ^" . fwb-replace-current-window-with-frame))

(leaf frame-extras
)
