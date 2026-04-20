(leaf
  consult
  :ensure t
  :preface

  ;; (defun sd/consult--buffer-preview-cwo-patch ()
  ;;   "Buffer preview function."
  ;;   (let
  ;;     (
  ;;       (orig-buf (window-buffer (consult--original-window)))
  ;;       (orig-prev (copy-sequence (window-prev-buffers)))
  ;;       (orig-next (copy-sequence (window-next-buffers)))
  ;;       (orig-bl (copy-sequence (frame-parameter nil 'buffer-list)))
  ;;       (orig-bbl (copy-sequence (frame-parameter nil 'buried-buffer-list)))
  ;;       other-win)
  ;;     (lambda (action cand)
  ;;       (pcase action
  ;;         ('return
  ;;           ;; Restore buffer list for the current tab
  ;;           (set-frame-parameter nil 'buffer-list orig-bl)
  ;;           (set-frame-parameter nil 'buried-buffer-list orig-bbl))
  ;;         ('exit
  ;;           (set-window-prev-buffers other-win orig-prev)
  ;;           (set-window-next-buffers other-win orig-next))
  ;;         ('preview
  ;;           ;; Prevent opening the preview in another tab, since restoring the tab
  ;;           ;; status is difficult and also costly.
  ;;           (cl-letf*
  ;;             (
  ;;               ((symbol-function #'display-buffer-in-tab) #'ignore)
  ;;               ((symbol-function #'display-buffer-in-new-tab) #'ignore))
  ;;             (when
  ;;               (and
  ;;                 (eq consult--buffer-display #'switch-to-buffer-other-window)
  ;;                 (not other-win))
  ;;               (switch-to-buffer-other-window-force orig-buf 'norecord)
  ;;               (setq other-win (selected-window)))
  ;;             (let
  ;;               (
  ;;                 (win (or other-win (selected-window)))
  ;;                 (buf (or (and cand (get-buffer cand)) orig-buf)))
  ;;               (when
  ;;                 (and (window-live-p win)
  ;;                   (buffer-live-p buf)
  ;;                   (not (buffer-match-p consult-preview-excluded-buffers buf)))
  ;;                 (with-selected-window win
  ;;                   (unless (or orig-prev orig-next)
  ;;                     (setq
  ;;                       orig-prev (copy-sequence (window-prev-buffers))
  ;;                       orig-next (copy-sequence (window-next-buffers))))
  ;;                   (switch-to-buffer buf 'norecord))))))))))

  ;; captainflasmr
  (defvar consult--xref-history nil
    "History for the `consult-recent-xref' results.")

  (defun consult-recent-xref (&optional markers)
    "Jump to a marker in MARKERS list (defaults to `xref--history'.
The command supports preview of the currently selected marker position.
The symbol at point is added to the future history."
    (interactive)
    (consult--read
      (consult--global-mark-candidates
        (or markers (flatten-list xref--history)))
      :prompt "Go to Xref: "
      :annotate (consult--line-prefix)
      :category 'consult-location
      :sort nil
      :require-match t
      :lookup #'consult--lookup-location
      :history '(:input consult--xref-history)
      :add-history (thing-at-point 'symbol)
      :state (consult--jump-state)))

  :bind
  (("C-x b" . consult-buffer)
    ("C-x M-f" . consult-recent-file)
    ("C-h !" . consult-man)
    ("C-h i" . consult-info)
    ("C-c h" . consult-history)
    ("C-c m" . consult-mode-command)
    ("C-x r b" . consult-bookmark) ;; bookmark+
    ("C-c k" . consult-kmacro)
    ;; C-x bindings (ctl-x-map)
    ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
    ("C-x 4 b" . consult-buffer-other-window)
    ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
    ("C-h !" . consult-man)
    ("C-h i" . consult-info)
    ("C-c h" . consult-history)
    ("C-c m" . consult-mode-command)
    ("C-x r b" . consult-bookmark) ;; bookmark+
    ("C-c k" . consult-kmacro)
    ;; C-x bindings (ctl-x-map)
    ("C-x M-:" . consult-complex-command) ;; orig. repeat-complex-command
    ("C-x 4 b" . consult-buffer-other-window)
    ("C-x 5 b" . consult-buffer-other-frame) ;; orig. switch-to-buffer-other-frame
    ("M-4" . consult-register)
    ("M-y" . consult-yank-pop) ;; orig. yank-pop
    ("M-g e" . consult-compile-error)
    ("M-g f" . consult-flymake) ;; flymake
    ("M-g g" . consult-goto-line) ;; orig. goto-line
    ("M-g o" . consult-org-heading)
    ("M-g M-o" . consult-outline)
    ("M-g m" . consult-mark)
    ("M-g k" . consult-global-mark)
    ("M-g i" . consult-imenu)
    ("M-g M-i" . consult-imenu-multi)
    ("M-g x" . consult-xref)
    ;; M-s bindings (search-map)
    ("M-s d" . consult-find)
    ("M-s F" . consult-locate)
    ("M-s g" . consult-grep)
    ("M-s G" . consult-git-grep)
    ("M-s r" . consult-ripgrep)
    ("M-s l" . consult-line)
    ("M-s L" . consult-line-multi)
    ("M-s M-o" . consult-multi-occur)
    ("M-s k" . consult-keep-lines)
    ("M-s u" . consult-focus-lines)
    (:isearch-mode-map
      (("C-c h" . consult-isearch-history)
        ("M-s l" . consult-line) ;; needed by consult-line to detect isearch
        ("M-s L" . consult-line-multi))))
  :init
  (setq
    register-preview-delay 0
    register-preview-function #'consult-register-format)

  (advice-add #'register-preview :override #'consult-register-window)

  (setq
    xref-show-xrefs-function #'consult-xref
    xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section, after lazily
  ;; loading the package.

  :custom
  ((consult-async-input-debounce . 0.2)
    (consult-async-input-throttle . 0.2)
    (consult-async-min-input . 3)
    (consult-async-refresh-delay . 0.1)
    (consult-preview-key . "M-.")
    (consult-ripgrep-args
      .
      "rg --null --line-buffered --color=never --max-columns=300 --path-separator / --smart-case --no-heading --with-filename --line-number --search-zip --no-heading --threads=13")
    (consult--gc-threshold . most-positive-fixnum)
    (completion-in-region-function . #'consult-completion-in-region))

  :config
  ;; TODO
  ;; advice consult--buffer-preview to work with 'current-window-only
  ;; https://github.com/FrostyX/current-window-only

  ;;(advice-add #'completing-read-multiple :override #'consult-completing-read-multiple)

  ;; Optionally configure preview. The default value is 'any, such that any
  ;; key triggers the preview.
  ;; (setq consult-preview-key (kbd "M-."))

  (setq-default consult-preview-key '(:debounce 0.5 "M-."))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  ;; (consult-customize consult-theme :preview-key
  ;;                    ;;consult-bookmark
  ;;                    ;;consult-recent-file
  ;;                    ;;consult-xref
  ;;                    ;;consult--source-file why?
  ;;                    ;;consult--source-project-file why?
  ;;                    ;;consult--source-bookmark :preview-key '(kbd "M-.")
  ;;                    consult-ripgrep :preview-key
  ;;                    ;;consult-git-grep
  ;;                    consult-imenu
  ;;                    :preview-key
  ;;                    consult-imenu-multi
  ;;                    :preview-key
  ;;                    consult-line
  ;;                    :preview-key
  ;;                    consult-org-heading
  ;;                    :preview-key
  ;;                    consult-grep

  ;; Optionally configure the narrowing key.
  (setq consult-narrow-key "<") ;; (kbd "C-+")

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; Optionally configure a function which returns the project root directory.
  ;; There are multiple reasonable alternatives to chose from.
  ;;;; 1. project.el (project-roots)
  (setq consult-project-root-function
    (lambda ()
      (when-let
        (
          project
          (project-current))
        (car (project-roots project))))))
;;;; 2. projectile.el (projectile-project-root)
;; (autoload 'projectile-project-root "projectile")
;; (setq consult-project-root-function #'projectile-project-root)
;;;; 3. vc.el (vc-root-dir)
;; (setq consult-project-root-function #'vc-root-dir)
;;;; 4. locate-dominating-file
;; (setq consult-project-root-function (lambda () (locate-dominating-file "." ".git")))

(leaf
  consult-dir
  :ensure t
  :bind
  (("C-x C-d" . consult-dir)
    (:minibuffer-local-completion-map
      (("C-x C-d" . consult-dir) ("C-x C-j" . consult-dir-jump-file)))))

(leaf
  consult-recoll
  :after embark
  :ensure t
  :custom
  ((consult-recoll-inline-snippets . t)
    (consult-recoll-group-by-mime . nil)
    (consult-recoll-open-fn . #'find-file))
  :bind ("M-s s C-?" . consult-recoll)
  :config (consult-recoll-embark-setup))

;; TODO: improve https://github.com/armindarvish/consult-gh
;; TODO: rg onto whole repo

(leaf
  consult-gh
  :quelpa (consult-gh :fetcher github :repo "armindarvish/consult-gh")
  :preface
  ;; TODO: consult-gh-find-file onto result
  (defun sd/consult-gh-search-code-in-repo (&optional args)
    (interactive "P")
    (let
      (
        (repo
          (first
            (string-split
              (substring-no-properties
                (consult-gh-search-repos nil t "Repo: "))))))
      (consult-gh-search-code nil repo nil "Search code in repo: ")))
  :custom
  ((consult-gh-group-files-by . :file)
    (consult-gh-file-action . #'consult-gh--files-view-action))
  :bind
  (("C-x / g r" . consult-gh-repo-list)
    ("C-x / g g" . consult-gh)
    ("C-x / g s" . consult-gh-search-code)
    ("C-x / g C-s" . sd/consult-gh-search-code-in-repo)
    ("C-x / g c" . consult-gh-repo-clone)
    ("C-x / g f" . consult-gh-repo-fork)
    ("C-x / g C-f" . consult-gh-find-file)
    ("C-x / g i l" . consult-gh-find-file)
    ("C-x / g i c" . consult-gh-issue-create)
    ("C-x / g i l" . consult-gh-issue-list)
    ("C-x / g i d" . consult-gh-issue-delete)
    ("C-x / g i x" . consult-gh-issue-close)
    ("C-x / g i e" . consult-gh-issue-edit)
    ("C-x / g i v" . consult-gh-issue-view)))

(leaf
  consult-omni
  :after browser-hist
  :quelpa
  (consult-omni
    :fetcher github
    :repo "armindarvish/consult-omni"
    :files (:defaults "sources/*.el")
    :branch "develop")
  ;; TODO: cmd to go to next page
  ;; -- :page 2
  :custom
  ( ;;(consult-omni-alternate-browse-function . sd/browse-chrome)
    (consult-omni-show-preview . t)
    (consult-omni-preview-key . "M-.")
    (consult-omni-default-count . 10)
    (consult-omni-url-use-queue . t)
    (consult-omni-http-retrieve-backend . 'plz) ;; 15 parallel
    (consult-omni-default-autosuggest-command
      .
      #'consult-omni-dynamic-google-autosuggest)
    (consult-omni-dynamic-input-debounce . 0.8)
    (consult-omni-dynamic-input-throttle . 1.6)
    (consult-omni-dynamic-refresh-delay . 0.8))
  :config
  (require 'consult-omni-embark)
  (require 'consult-omni-sources)
  (consult-omni-sources-load-modules))

;; extras
(leaf consult-extras :require t)

;; TODO: lazy-load
(leaf
  consult-stash
  :require t
  :bind
  (("C-x f ?" . sd/consult-locate-in-stash)
    ("M-s @" . sd/consult-symbol-or-region-in-stash)))

(leaf
  consult-project-extra
  :ensure t
  :bind
  (:project-prefix-map
    (("b" . consult-project-buffer) ("f" . consult-project-extra-find))))
