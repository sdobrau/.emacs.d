;; -*- lexical-binding: t -*-

;; TODO: factor for dabbrev
(leaf calc-extras
 :commands
 :config
 ;; divisions done by float always
 ;; wasamasa
 (setq calculator-user-operators '(("/" / (/ (float x) y) 2 5))))
