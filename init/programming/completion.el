;; -*- lexical-binding: t -*-

;;; Main options
(setq-default
  completions-cycle-threshold t ;; always cycle completions
  ;; vertical completion in columns in minibuffer
  completions-format 'vertical
  ;; below this is cycled
  completion-cycle-threshold nil
  ;; enable indentation+completion using the TAB key.
  ;; `completion-at-point'is often bound to M-TAB.
  tab-always-indent 'complete)

(leaf
  prescient
  :ensure t
  :require t
  :commands prescient-persist-mode
  :custom ((prescient-use-case-folding . 'smart) (prescient-sort-length-enable . nil)))

;;; Corfu suite

(leaf
  orderless
  :ensure t
  :require t
  :custom
  ((completion-styles . '(basic substring partial-completion flex))
    (completion-category-overrides
      .
      '((file (styles basic partial-completion)) (buffer (styles . (flex))))))
  :config
  ;; Try out host-name completion (with Vertico.)
  (defun basic-remote-try-completion (string table pred point)
    (and (vertico--remote-p string)
      (completion-basic-try-completion string table pred point)))
  (defun basic-remote-all-completions (string table pred point)
    (and (vertico--remote-p string)
      (completion-basic-all-completions string table pred point)))
  (add-to-list
    'completion-styles-alist
    '
    (basic-remote
      basic-remote-try-completion
      basic-remote-all-completions
      nil))
  (setq
    completion-styles '(orderless)
    completion-category-overrides '((file (styles basic-remote partial-completion)))))

(leaf
  corfu
  :ensure t
  :config

  ;; enable completion in all non-completion minibuffers

  (setq global-corfu-minibuffer
    (lambda ()
      (not
        (or (bound-and-true-p mct--active)
          (bound-and-true-p vertico--input)
          (eq (current-local-map) read-passwd-map)))))

  (defun corfu-insert-shell-filter (&optional _)
    "Insert completion candidate and send when inside comint/eshell."
    (when (or (derived-mode-p 'eshell-mode) (derived-mode-p 'comint-mode))
      (lambda ()
        (interactive)
        (corfu-insert)
        ;; `corfu-send-shell' was defined above
        (corfu-send-shell))))

  (defun corfu-just-newline (&optional _)
    "Insert completion candidate and send when inside comint/eshell."
    (interactive "P")
    (corfu-quit)
    (newline))

  ;; SPC as separator
  (setq corfu-separator 32)
  ;; https://github.com/minad/corfu/wiki#same-key-used-for-both-the-separator-and-the-insertion
  ;; highly recommanded to use corfu-separator with "32" (space)
  (define-key
    corfu-map (kbd "SPC")
    (lambda ()
      (interactive)
      (if current-prefix-arg
        ;;we suppose that we want leave the word like that, so do a space
        (progn
          (corfu-quit)
          (insert " "))
        (if
          (and (= (char-before) corfu-separator)
            (or
              ;; check if space, return or nothing after
              (not (char-after))
              (= (char-after) ?\s)
              (= (char-after) ?\n)))
          (progn
            (corfu-insert)
            (insert " "))
          (corfu-insert-separator)))))

  (defun corfu-send-shell (&rest _)
    "Send completion candidate when inside comint/eshell."
    (cond
      ((and (derived-mode-p 'eshell-mode) (fboundp 'eshell-send-input))
        (eshell-send-input))
      ((and (derived-mode-p 'comint-mode) (fboundp 'comint-send-input))
        (comint-send-input))))

  (advice-add #'corfu-insert :after #'corfu-send-shell)

  ;; https://github.com/minad/corfu#completing-with-corfu-in-the-minibuffer

  (defun corfu-enable-always-in-minibuffer ()
    "Enable Corfu in the minibuffer if Vertico/Mct are not active."
    (unless
      (or (bound-and-true-p mct--active)
        (bound-and-true-p vertico--input)
        (eq (current-local-map) read-passwd-map))
      (setq-local corfu-auto nil) ;; Enable/disable auto completion
      (setq-local
        corfu-echo-delay nil ;; Disable automatic echo and popup
        corfu-popupinfo-delay nil)
      (corfu-mode 1)))

  (defun orderless-fast-dispatch (word index total)
    (and (= index 0)
      (= total 1)
      (length< word 4)
      `(orderless-regexp . ,(concat "^" (regexp-quote word)))))

  (orderless-define-completion-style
    orderless-fast
    (orderless-dispatch '(orderless-fast-dispatch))
    (orderless-matching-styles '(orderless-literal orderless-regexp)))

  :hook ((corfu-mode-hook . corfu-history-mode))
  :bind
  (:corfu-map
    (("TAB" . corfu-next)
      ([tab] . corfu-next)
      ("C-<tab>" . corfu-previous)
      ("M-d" . corfu-show-documentation)
      ("M-l" . corfu-show-location)
      ;; for eshell and etc
      ("C-n" . corfu-next)
      ("RET" . corfu-insert)
      ("C-p" . corfu-previous)
      ("M-RET" . corfu-insert)
      ("M-n" . corfu-popupinfo-scroll-up)
      ("M-p" . corfu-popupinfo-scroll-down)
      ([backtab] . corfu-previous))
    (:corfu-popup-info-map
      ("M-n" . corfu-popupinfo-scroll-up)
      ("M-p" . corfu-popupinfo-scroll-down)))
  :custom
  ((corfu-cycle . nil) ; enable cycling
    (corfu-auto . t) ; popup auto on delay
    (corfu-preselect-first . t)
    (corfu-separator . ?\s) ; space
    (corfu-min-width . 40)
    (corfu-max-width . 40)
    (corfu-auto-prefix . 1)
    (corfu-separator . ?\s) ; for orderless comp, use spc?
    (corfu-quit-at-boundary . nil)
    (corfu-quit-no-match . 'separator)
    (corfu-sort-function . #'corfu-sort-length-alpha)
    (corfu-echo-documentation . t)
    (corfu-auto-delay . 0.6)
    (corfu-scroll-margin . 5)
    (corfu-count . 7)
    (completion-styles . '(basic))
    (completion-category-overrides
      ((file (styles orderless-fast partial-completion))))
    (corfu-popupinfo-delay . 0.5)
    (corfu-popupinfo-max-height . 60)
    (corfu-popupinfo-max-width . 80))

  ;; TODO: consider minibuffer completion for corfu
  ;; (add-to-list 'corfu--frame-parameters `(font . ,my-font))
  (add-hook 'minibuffer-setup-hook #'corfu-enable-always-in-minibuffer)
  (advice-add 'window-configuration-change-hook :before #'corfu--popup-hide))

(leaf
  nerd-icons-corfu
  :if (display-graphic-p)
  :ensure t
  :config (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(leaf
  corfu-prescient
  :after prescient
  :hook (corfu-mode-hook . corfu-prescient-mode))

;; (leaf
;;   corfu-terminal
;;   :if (not (display-graphic-p))
;;   :ensure t
;;   :hook (corfu-mode-hook . corfu-terminal-mode))

;; additional completions
(leaf
  cape
  :hook
  ((completion-at-point-functions . cape-dabbrev)
    (completion-at-point-functions . cape-file))
  :ensure t)

;;; Others
(leaf
  abbrev
  :hook (text-mode . abbrev-mode)
  :custom (abbrev-suggest . t) ;; if typing expansion instead of existing abbrv
  :bind (:abbrev-map (("?" . abbrev-suggest-show-report))))

;; TODO: look for tramp issue
;; https://github.com/minad/vertico#problematic-completion-commands

;; (defun basic-remote-try-completion (string table pred point)
;;   (and (vertico--remote-p string)
;;        (completion-basic-try-completion string table pred point)))
;; (defun basic-remote-all-completions (string table pred point)
;;   (and (vertico--remote-p string)
;;        (completion-basic-all-completions string table pred point)))
;; (add-to-list
;;  'completion-styles-alist
;;  '(basic-remote basic-remote-try-completion basic-remote-all-completions nil))
;; (setq completion-styles '(orderless basic)
;;       completion-category-defaults nil
;;       completion-category-overrides '((file (styles basic-remote partial-completion))))
