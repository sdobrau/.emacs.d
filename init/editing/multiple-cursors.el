;; -*- lexical-binding: t -*-


(leaf
  multiple-cursors
  :ensure t
  ;; TODO: complex lazy load
  :after selected
  :require t
  ;; TODO: call-last-macro-on-each-multiple-cursor
  ;; TODO: function to make a temporary buffer as large as bottom-most cursor,;
  ;; then the macro can operate on that buffer... ?
  :bind
  (("M-c" . nil) ;; upcase-word
    ;;
    ("M-c n" . mc/mark-next-lines)
    ("M-c c" . mc/mark-all-dwim)
    ("M-c l" . mc/edit-lines)
    ("M-c a" . mc/mark-all-like-this)
    ("M-c w" . mc/mark-all-words-like-this)
    ("M-c @" . mc/mark-all-symbols-like-this)
    (:mc/keymap
      (("M-n" . mc/cycle-forward)
        ("M-p" . mc/cycle-backward)
        ;; ("M-<mouse-1>" . mc/add-cursor-on-click)
        ("<return>" . nil) ("<escape>" . nil)))
    (:selected-keymap
      (("m a" . mc/mark-all-in-region)
        ("m l" . mc/edit-lines)
        ("C-M-c" . mc/mark-all-in-region-regexp))))
  :custom (mc/max-cursors . 6000)
  :config (add-to-list 'mc/unsupported-minor-modes 'corfu-mode))

;; TEST: test
(leaf
  daanturo-multiple-cursors
  :after multiple-cursors
  ;; TODO: lazy
  :bind ("M-c p" . daanturo-mc/edit-lines-dwim)
  :hook
  (
    (multiple-cursors-mode-enabled-hook
      .
      daanturo-mc/resume-paused-cursors-when-indicated)
    (multiple-cursors-mode-hook
      .
      daanturo-toggle-corfu-tick-advice-mc-compat--a))
  :config
  (advice-add
    #'mc/keyboard-quit
    :before #'daanturo-mc/save-cursor-when-not-region-and-not-prefix-args--a)

  (daanturo-add-advice/s
    #'(corfu-insert corfu-complete)
    :around
    (daanturo-add-advice/s
      #'(corfu-insert corfu-complete)
      :around #'daanturo-corfu-completions-for-mc--a)
    (daanturo-add-advice/s
      #'(consult-completion-in-region)
      :around #'daanturo-completion-by-minibuffer-for-mc-a))
  )

;; ;; TODO: fix
;; (leaf phi-search-mc
;;   :ensure t
;;   :require t
;;   :hook (isearch-mode-hook . phi-search-from-isearch-mc/setup-keys)
;;   :config (phi-search-mc/setup-keys))
;; ;; (daanturo-bind [remap +multiple-cursors/evil-mc-toggle-cursor-here] #'daanturo-mc/toggle-cursor-at-point)
;; ;; (daanturo-bind [remap +multiple-cursors/evil-mc-toggle-cursors] #'daanturo-mc/toggle-pausing-cursors)
;; ;; (daanturo-bind [remap evil-mc-undo-all-cursors] #'daanturo-mc/indicate-paused-cursors-mode)
;; ;; (global-unset-key (kbd "m-<down-mouse-1>"))))
