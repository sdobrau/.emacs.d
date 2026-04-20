;; -*- lexical-binding: t -*-

(leaf comint
  :bind (:comint-mode-map
         (("C-l" . comint-clear-buffer)))
  :custom ((comint-buffer-maximum-size . 20000)
           (comint-input-autoexpand . t)
           (comint-move-point-for-output . t)))
