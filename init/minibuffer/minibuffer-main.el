(leaf
  minibuffer
  :require t ;; don’t install but load
  :hook (minibuffer-setup-hook . cursor-intangible-mode)
  :bind
  (
    (:minibuffer-local-map
      (([escape] . abort-recursive-edit))
      :minibuffer-local-ns-map (([escape] . abort-recursive-edit))
      :minibuffer-local-completion-map (([escape] . abort-recursive-edit))
      :minibuffer-local-must-match-map (([escape] . abort-recursive-edit))
      :minibuffer-local-isearch-map (([escape] . abort-recursive-edit))))

  :custom
  ((completion-auto-help . t)
    (completion-show-help . nil)
    ;; cycle completions regardless of the count
    (completion-cycle-threshold . t)
    ;; test enable
    (minibuffer-prompt-properties
      .
      '
      (read-only
        t
        point-entered
        minibuffer-avoid-prompt
        face
        minibuffer-prompt))
    (enable-recursive-minibuffers . t) ;; stupid
    (resize-mini-windows . nil) ;; fixes smex multi-line issue
    (minibuffer-auto-raise . nil)
    (minibuffer-depth-indicate-mode . t)
    (minibuffer-eldef-shorten-default . t)
    (minibuffer-electric-default-mode . t)
    ;; always display minibuffer in selected frame
    (minibuffer-follows-selected-frame . t)
    ;; ignore cases when complete
    (completion-ignore-case . t)
    ;; insensitive buffer/filename matching
    (read-buffer-completion-ignore-case . t)
    (read-file-name-completion-ignore-case . t)
    ;; vertical view
    (completions-format . 'one-column)
    (completions-detailed . t)
    (minibuffer-prompt-properties
      .
      '(read-only t cursor-intangible t face minibuffer-prompt))
    ;; don’t resize mini-windows as much as possible to fit text
    (resize-mini-windows . t))
  :config
  ;; remove 'on-screen-keyboard' ('touch-screen')
  (remove-hook 'minibuffer-setup-hook #'minibuffer-setup-on-screen-keyboard)
  (remove-hook 'minibuffer-exit-hook #'minibuffer-exit-on-screen-keyboard))
;; Emacs 28: M-x: hide commands not fit for current mode
;;(read-extended-command-predicate
;; . #'command-completion-default-include-p)))
