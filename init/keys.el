;; -*- lexical-binding: t -*-

;; Show keys on scren
(leaf keypression :if (display-graphic-p) :ensure t)

;; Easily define repeat-map
(leaf
  repeaters
  :quelpa (repeaters :fetcher github :repo "mmarshall540/repeaters")
  :config
  ;; (repeaters-define-maps
  ;;  '(("git-gutter-with-magit"
  ;;     git-gutter:previous-hunk  "C-x v" "["
  ;;     git-gutter:next-hunk  "C-x v" "]"
  ;;     git-gutter:stage-hunk  "C-x v" "S"
  ;;     magit-commit-create "C-x v" "C-c"
  ;;     magit-commit-instant-fixup "C-x v" "C-."
  ;;     magit-commit-extend "C-x v" "C-M-."
  ;;     magit-commit-reword "C-x v" "M-.")))
  (repeat-mode))

;; Suggest free prefix keys
(leaf
  free-keys
  :ensure t
  :custom (free-keys-modifiers . '("C-c" "s" "C" "M" "C-M" , "C-M-S")))

;; Key helper
(leaf
  which-key
  :require t
  ;; todo number-or-marker-p if which-key-mode
  :bind
  (("C-h C-k" . which-key-show-top-level)
    ("C-h M-k" . which-key-show-major-mode)
    ("C-h C-M-k" . which-key-show-full-keymap))
  :custom
  ((which-key-show-early-on-C-h . t)
    (which-key-paging-key . ">")
    (which-key-idle-delay . 1.0)
    (which-key-max-description-length . 30)
    (which-key-allow-imprecise-window-fit . t) ; performance [redguardtoo]
    (which-key-separator . ": ")
    (which-key-idle-secondary-delay . 0.3)
    (which-key-min-display-lines . 6)
    (which-key-min-column-description-width . 80)
    (which-key-sort-order . 'which-key-key-order)
    (which-key-sort-uppercase-first . nil)
    (which-key-popup-type . 'minibuffer)
    ;; TODO: function to show in same buffer
    (which-key-side-window-location . 'top)))
