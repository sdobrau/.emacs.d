;; -*- lexical-binding: t -*-

(leaf frame-center
  :bind ("C-x 5 SPC" . ct/frame-center))

(leaf nameframe
  :ensure t
  :bind ("C-x 5 n" . nameframe-create-frame))

(leaf nameframe-project
  :ensure t)

(leaf zoom-frame
  :bind (("C-x M-=" . acg/zoom-frame)
         ("C-x M--" . acg/zoom-frame-out)
         ("<M-wheel-up>" . acg/zoom-frame)
         ("<M-wheel-down>" . acg/zoom-frame-out)))

(leaf frame-extras
  :bind ("C-x 5 C-c 0" . sd/kill-other-frames))
