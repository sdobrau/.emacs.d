;; see https://github.com/CeleritasCelery/emacs-native-shell-complete
;; ---
;; 'export HISTCONTROL=ignoreboth'
;; bind 'set enable-bracketed-paste off'
;; ---
;; ^ in bashrc  if garbled history

(leaf native-complete :ensure t :commands shell)

;; xterm-color required in function
(leaf
  shell
  :init
  (defun sd/shell-mode-hook ()
    (native-complete-setup-bash)
    (setq-local comint-prompt-regex "^.+[$%>] ")
    (corfu-mode)
    (rainbow-delimiters-mode -1)
    ;; https://github.com/atomontage/xterm-color
    (require 'xterm-color)
    (font-lock-mode -1)
    (setq font-lock-function (lambda (_) nil))
    (add-hook 'comint-preoutput-filter-functions 'xterm-color-filter nil t)
    (setq comint-output-filter-functions
      (remove 'ansi-color-process-output comint-output-filter-functions)))
  :custom
  ((shell-command-switch . "--norc --noprofile -c")
    (async-shell-command-buffer . nil))
  :hook (shell-mode-hook . sd/shell-mode-hook))
