(leaf
 vterm
 :ensure t
 :preface
 (defun sd/vterm-new-below-this-window (&optional arg)
   "Split window below and call a new vterm here."
   (interactive "P")
   (split-window-below-and-focus)
   (vterm 4))
 (defun sd/vterm-copy-mode-and-set-mark (&optional arg)
   (interactive "P")
   (vterm-copy-mode)
   (bd-set-mark-command))
 :commands
 vterm
 (defun sd/vterm-rename-buffer-sticky (&optional title)
   "Prompt for or set TITLE of the vterm buffer persistently, regardless of
`vterm-buffer-name-string'."
   (interactive "P")
   ;; We set this to nil in order to prevent the shell from renaming it.
   (setq-local vterm-buffer-name-string nil)
   (if title
       (rename-buffer title)
     (call-interactively #'rename-buffer)))
 :bind
 (("C-c M-v" . sd/vterm-new-below-this-window)
  (:vterm-mode-map
   (("C-y" . vterm-yank)
    ("M-y" . vterm-yank-pop)
    ;; for compact with running vterm inside a terminal
    ;; key handling is 'a mess'
    ;; https://github.com/akermu/emacs-libvterm/issues/106
    ("RET" . vterm-send-return)
    ("TAB" . vterm-send-tab)
    ("C-m" . vterm-send-return)
    ("C-c C-c" . vterm-send-C-c)
    ("C-l" . vterm-clear)
    ("DEL" . vterm-send-backspace)
    ("M-DEL" . vterm-send-meta-backspace)
    ("C-c C-e" . vterm-copy-mode)
    ("C-SPC" . nil)
    ("C-SPC" . sd/vterm-copy-mode-and-set-mark)
    ("M-&" . async-shell-command)
    ;; augh
    ("C-w" . nil)
    ("M-s" . nil)
    ("M-<" . nil)
    ("M->" . nil)
    ("C-w 0" . winum-select-window-0)
    ("C-w 1" . winum-select-window-1)
    ("C-w 2" . winum-select-window-2)
    ("C-w 3" . winum-select-window-3)
    ("C-w 4" . winum-select-window-4)
    ("C-w 5" . winum-select-window-5)
    ("C-w 6" . winum-select-window-6)
    ("C-w 7" . winum-select-window-7)
    ("C-w 8" . winum-select-window-8)
    ("C-w 9" . winum-select-window-8)))
  (:vterm-copy-mode-map
   (("C-M-e" . forward-paragraph)
    ("C-M-a" . backward-paragraph)
    ("C-c C-e" . vterm-copy-mode))))
 :custom
 ((vterm-buffer-name-string . "vterm %s")
  (vterm-timer-delay . 0.0001)
  (vterm-clear-scrollback-when-clearing . t)
  (vterm-max-scrollback . 100000) ; max
  (vterm-disable-bold-font . nil))
 :config
 ;; TODO make exceptions dynamic based on key for
 ;; winum window
 ;; previous / next buffer
 ;; (let (result)
 ;; (dolist (element loop-list store-var)
 ;;  (body)))
 ;; #'key-description
 ;;
 (add-to-list 'vterm-keymap-exceptions "C-w")
 (add-to-list 'vterm-keymap-exceptions "M-<")
 (add-to-list 'vterm-keymap-exceptions "M->")
 (add-to-list 'vterm-keymap-exceptions "M-s"))

(leaf
 vterm-extras
 :bind (:vterm-mode-map (("C-k" . vterm-send-C-k-and-kill))))

(leaf
 vterm-toggle
 :ensure t
 :custom (vterm-toggle-hide-method . nil)
 :bind
 (("C-c v" . vterm-toggle-cd)
  (:vterm-mode-map
   (("M->" . vterm-toggle-forward) ("M-<" . vterm-toggle-backward)))
  (:vterm-copy-mode-map
   (("M->" . vterm-toggle-forward) ("M-<" . vterm-toggle-backward)))))
