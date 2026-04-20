;; -*- lexical-binding: t -*-

;;; Parentheses

(leaf rainbow-delimiters
  :ensure t)

(leaf show-paren
  :ensure nil
  :custom
  ((show-paren-style . 'parenthesis) ; show matchin paren
    (show-paren-when-point-in-periphery . t) ; show when near paren
    (show-paren-delay . 0.4)
    (show-paren-when-point-inside-paren . t))) ; don’t show when inside paren

;;; Whitespace

(setq-default backward-delete-char-untabify-method 'hungry)

(leaf whitespace
  :custom
  ;; what to do when a buffer is visited or written
  ((whitespace-action . '(auto-cleanup))
    ;; which blanks to visualize?
    (whitespace-style
      .
      '
      (face
        tabs
        spaces
        newline
        space-mark
        tab-mark
        newline-mark
        empty
        trailing
        lines
        space-before-tab
        empty
        lines-style))
    ;; disable whitespace mode in these modes
    (whitespace-global-modes . '(not (erc-mode ses-mode)))
    ;; junkw emacs.d setup
    (whitespace-space-regexp . "\\( +\\|\x3000+\\)") ; mono and multi-byte space
    (whitespace-display-mappings
      .
      '
      ((space-mark ?\xa0 [?\u00a4] [?_])
        (space-mark ?\x8a0 [?\x8a4] [?_])
        (space-mark ?\x920 [?\x924] [?_])
        (space-mark ?\xe20 [?\xe24] [?_])
        (space-mark ?\xf20 [?\xf24] [?_])
        (space-mark ?\u3000 [?\u25a1])
        (newline-mark ?\n [?$ ?\n])
        (TAB-mark ?\t [?\u00bb ?\t] [?\\ ?\t])))))

;; TODO: bug with org src buffers. disable for now
(leaf whitespace-cleanup-mode
  :disabled t
  :custom
  (whitespace-cleanup-mode-only-if-initially-clean . nil)
  (whitespace-style
    .
    '
    (face
      trailing
      tabs
      spaces
      newline
      missing-newline-at-eof
      empty
      indentation
      space-after-tab
      space-before-tab
      space-mark
      tab-mark
      newline-mark)))

;;; Format

(leaf reformatter
  :ensure t)

(leaf apheleia
  :if (--any (executable-find it) '("shfmt" "black"))
  :ensure t
  :custom
  ((apheleia-hide-log-buffers . t) ;; type SPC to see
    (apheleia-log-debug-info . t)
    (apheleia-format-after-save-in-progress . nil))
  :bind (:prog-mode-map (("C-x C-." . apheleia-format-buffer))))

;;; Indent

(setq-default
  indent-tabs-mode nil
  c-basic-indent 2
  c-basic-offset 2
  sh-basic-offset 2
  ;; tab-stop positions are (2 4 6 8 ...)
  tab-stop-list (number-sequence 2 200 2)
  tab-width 2)

;; TODO: what?
;; (paragraph-indent-minor-mode)

(leaf align
  :ensure t)

(leaf aggressive-indent
  :ensure t
  :custom
  (
    (aggressive-indent-dont-electric-modes
      .
      '(yaml-mode python-mode emacs-lisp-mode))
    (aggressive-indent-excluded-modes . '(python-mode text-mode yaml-mode)))
  :config
  ;;; fix, cancel excessive timers aggressive-indent--indent-if-changed

  ;; https://github.com/Malabarba/aggressive-indent-mode/issues/112

  (defun cancel-aggressive-indent-timers ()
    (interactive)
    (let ((count 0))
      (dolist (timer timer-idle-list)
        (when (eq 'aggressive-indent--indent-if-changed (aref timer 5))
          (cl-incf count)
          (cancel-timer timer)))
      (when (> count 0)
        (message "Cancelled %s aggressive-indent timers" count))))

  (run-with-idle-timer 5 t 'cancel-aggressive-indent-timers))

(leaf dtrt-indent
  :ensure t
  :custom
  ((dtrt-indent-verbosity . 0)
    ;; should fix issue with bash
    ;; dtrt-indent would send to smie-config-guess for sh which is wrong
    (dtrt-indent-run-after-smie . t)))

;; Buttonize bug references
(leaf bug-reference
  :hook (text-mode . bug-reference-mode))

(leaf bug-reference-github
  :ensure t)

;; ;; 'a=10*5+2 > a = 10 * 5 + 2'
;; (leaf electric-operator
;;   :ensure t
;;   :custom ((electric-operator-enable-in-docs . nil)
;;            (electric-operator-double-space-docs . nil))) ;; "." -> ". "
