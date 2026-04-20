;;; -*- lexical-binding: t -*

(setq-default x-select-enable-primary t)

;; * sort keys

;; * set scroll

(setq-default
 scroll-conservatively 10000
 maximum-scroll-margin 0.5
 scroll-error-top-bottom nil
 ;; Preserve screen point position when scrolling
 scroll-preserve-screen-position t
 fast-but-imprecise-scrolling t
 ;; counter emacs sluggishness when scrolling very fast
 scroll-margin 9999)


(global-unset-key (kbd "C-M-c")) ;; forgot
(global-unset-key (kbd "C-M-p")) ;; pgtk-preedit-text
(global-unset-key (kbd "M-c")) ;; upcase-word
(global-unset-key (kbd "C-z")) ;; suspend<
(global-unset-key (kbd "C-x C-z")) ;; suspend-frame
(global-unset-key (kbd "C-x C-c")) ;; save-buffers-kill-terminal
(global-unset-key (kbd "C-x C-p")) ;; mark page
(global-unset-key (kbd "C-x f")) ;; fill-column
(global-unset-key (kbd "C-h C-n")) ;; view-emacs-news
(global-unset-key (kbd "ESC [")) ;; when hovering with mouse
(global-unset-key (kbd "M-[")) ;; when hovering with mouse
(global-set-key (kbd "C-c C-f") 'ffap)
(global-unset-key (kbd "C-h t")) ;; help-with-tutorial

;; * Setup leaf
(eval-and-compile
  (customize-set-variable
   'package-archives
   '
   (("org" . "https://orgmode.org/elpa/")
    ("melpa" . "https://melpa.org/packages/")
    ("gnu" . "https://elpa.gnu.org/packages/")
    ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

  (package-initialize)

  (package-activate-all)
  (customize-set-variable
   'package-user-dir
   (directory-file-name (concat user-emacs-directory "packages/elpa")))
  (customize-set-variable
   'package-archive-priorities
   '(("melpa-stable" . 10) ("melpa" . 20) ("gnu" . 30) ("nongnu" . 40)))
  (customize-set-variable 'package-menu-hide-low-priority nil))
(package-refresh-contents :async)
;; <leaf-install-code>

(unless (package-installed-p 'quelpa)
  (with-temp-buffer
    (url-insert-file-contents
     "https://raw.githubusercontent.com/quelpa/quelpa/master/quelpa.el")
    (eval-buffer)
    (quelpa-self-upgrade)))

(package-activate 'quelpa)

(setq-default
 quelpa-dir (concat user-emacs-directory "packages/quelpa")
 quelpa-melpa-dir (expand-file-name "melpa" quelpa-dir)
 quelpa-build-dir (expand-file-name "build" quelpa-dir)
 quelpa-packages-dir (expand-file-name "packages" quelpa-dir)
 quelpa-melpa-recipe-stores (list (expand-file-name "recipes" quelpa-melpa-dir))
 quelpa-persistent-cache-file (expand-file-name "cache" quelpa-dir)
 quelpa-build-verbose nil
 quelpa-verbose nil)

(quelpa
 '(quelpa-leaf :fetcher git :url "https://github.com/quelpa/quelpa-leaf.git"))


;; * shell

(setq-default confirm-kill-processes nil)
(setq-default kill-buffer-query-functions nil)
(setq-default shell-command-switch "-c")

(setq-default async-shell-command-display-buffer . nil)

;; redirection supported, region supported
(leaf shell-command+
  :ensure t
  :bind ("M-!" . shell-command+)
  :custom (shell-command+-prompt . "$+: "))

;; ** vterm

(leaf vterm
  :ensure t
  :preface
  :bind
  ((:vterm-mode-map
    (("M-g" . nil)
     ("C-y" . vterm-yank)
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
    (("M-g" . nil)
     ("C-M-e" . forward-paragraph)
     ("C-M-a" . backward-paragraph)
     ("C-c C-e" . vterm-copy-mode))))
  :custom
  ((vterm-buffer-name-string . "vterm %s")
   (vterm-timer-delay . 0.1)
   (vterm-clear-scrollback-when-clearing . t)
   (vterm-max-scrollback . 100000) ; max
   (vterm-disable-bold-font . nil)))

;; * histories and save place

(leaf savehist
  :require t
  :custom
  ((history-length . 100) ;; t is way too large
   (savehist-save-minibuffer-history . t)
   ;; what other variables to save?
   (savehist-additional-variables
    .
    '
    (search-ring
     regexp-search-ring
     ;; kill-ring ;; don’t save
     comint-input-ring
     sr-history-registry
     file-name-history
     org-mark-ring
     dogears-list
     tablist-name-filter
     winner-ring-alist
     mark-ring
     eshell-history-ring
     kmacro-ring)))
  :config
  (setq savehist-file (no-littering-expand-var-file-name "savehist"))
  (savehist-mode 1))

;; Save point history. Abbreviate file-names for confidentiality and make
;; backups of the master save-place file.
(leaf save-place
  :ensure nil
  :custom
  ((save-place-abbreviate-file-names . t)
   (save-place-limit . nil)
   (save-place-version-control . t))
  :config (setq save-place-file (no-littering-expand-var-file-name "save-place.el")))

;; * Disable the mouse.
(setq-default x-mouse-click-focus-ignore-position t)

;; * clipboard
;; Expectable behaviour of clipboard. Cut and paste uses the clipboard
;; and primary selection. When killing text outside Emacs, append it
;; to the clipboard as well.

(setq-default
 select-enable-clipboard t
 select-enable-primary t
 save-interprogram-paste-before-kill t)

;; for wayland ‘wl-clipboard’. terminal<->GUI support
(leaf xclip :if (display-graphic-p) :ensure t)


;; * shell inherit from

(leaf exec-path-from-shell
  :ensure t
  :custom
  (exec-path-from-shell-variables
   .
   '("MANPATH" "PATH" "MYIP" "XDG_RUNTIME_DIR" "LSP_USE_PLISTS"))
  :config (exec-path-from-shell-initialize))

;; * pinentry

(leaf pinentry :if (display-graphic-p) :ensure t :commands pinentry-start)

;;TODO: SETUP GPG-ENCRYPTED SECRETS

;; Save host information in =.emacs/data/nsm-settings.el=.
(setq nsm-save-host-names t)

;; * ai

;; TODO: customize, various models, etc
(leaf gptel
  :ensure t
  :init
  :hook
  ((gptel-post-response-functions . gptel-end-of-response)
   (gptel-post-stream-hook . gptel-auto-scroll))
  :bind ("C-x C-g" . gptel-menu)
  :custom
  (
   (gptel-track-media . t)
   (gptel-include-reasoning . nil)
   (gptel-use-header-line . nil)
   (gptel-default-mode . #'org-mode)
   (gptel-org-branching-context . t))
  :config
  (setq gptel-api-key (auth-source-pass-get 'secret "openai")))

;; * the greps

(leaf grep
  :after wgrep rg
  :bind
  (
   (:wgrep-mode-map
    (("C-c C-c" . save-buffer)) ;; echo magit behaviour. jeremyf
    (:ripgrep-search-mode-map (("e" . wgrep-change-to-wgrep-mode)))
    (:grep-mode-map (("e" . wgrep-change-to-wgrep-mode)))
    ("C-c C-c" . wgrep-finish-edit))))

(leaf deadgrep
  :ensure t
  :bind ("M-s x" . deadgrep))

;; * keys

;; Key helper
(leaf which-key
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

;; * documents and documentation

;; Better help buffer
(leaf helpful
  :ensure t
  :bind
  (([remap describe-function] . helpful-callable)
   ([remap describe-variable] . helpful-variable)
   ([remap describe-key] . helpful-key)
   ([remap describe-symbol] . helpful-symbol)
   ("C-c C-d" . helpful-at-point)
   (:helpful-mode-map (("q" . helpful-kill-buffers) ("g" . helpful-update))))
  :custom
  ((helpful-switch-buffer-function . #'pop-to-buffer)
   (help-window-select . t)
   (apropos-do-all . t))) ;; more extensively)

(leaf elisp-demos
  :ensure t
  :after helpful
  :config (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

;; ** the mans and unix

(leaf man
  ;; TODO: lazy load
  :require t
  :commands man consult-man smartscan-mode
  :hook (Man-mode-hook)
  :custom
  ((Man-notify-method . 'thrifty) ;; in pop-up frame
   (Man-width . nil))
  :bind (:Man-mode-map (("g" . nil) ("g" . consult-imenu))))

;; alternative
(leaf woman
  ;; TODO lazy load
  :require t
  :custom
  ((woman-fill-frame . t)
   (woman-fill-column . 80)
   (woman-imenu . t)
   (woman-cache-level . 3))
  :bind (("C-h /" . woman) (:woman-mode-map (("g" . consult-imenu))))
  :config
  (setq woman-cache-filename
        (no-littering-expand-var-file-name "woman-cache.el")))

;; cli -h|--help
(leaf noman
  :ensure t
  :bind
  (("C-h n" . noman)
   (:noman-mode-map (("n" . Man-next-section) ("p" . Man-previous-section))))
  :custom ((noman-reuse-buffers . nil)))

;; ** pdfs

;;; pdf
(if (display-graphic-p)
    (leaf
      pdf-outline
      :hook (pdf-view-mode-hook . pdf-outline-imenu-enable)
      :bind (:pdf-view-mode-map (("M-g o" . pdf-outline))))

  ;; TODO: tweak keybindings
  (leaf
    pdf-tools
    :ensure t
    :require
    (pdf-tools
     pdf-view
     pdf-misc
     pdf-occur
     pdf-util
     pdf-annot
     pdf-history
     pdf-info
     pdf-isearch
     pdf-links)
    ;; TODO: try less the file
    :preface
    :mode ("\\.pdf\\'" . pdf-tools-install)
    :preface
    (defun my-pdf-view-set-midnight-colors ()
      (interactive)
      (setq pdf-view-midnight-colors
            `
            (,(color-darken-name (face-attribute 'default :foreground) 0.001)
             .
             ,(color-lighten-name (face-attribute 'default :background) 0.001))))

    :bind ((:pdf-view-mode-map (("C-M-s" . pdf-occur) ("C-c l" . org-store-link))))
    ;; :bind (:pdf-history-minor-mode-map TODO: fix otherwise gives undefined
    ;;        (("l" . pdf-history-backward)
    ;;         (";" . pdf-history-forward)))

    :hook
    ((pdf-view-after-change-page-hook . pdf-view-midnight-minor-mode)
     ;;(pdf-view-mode-hook . pdf-loader-install)
     ;;(pdf-view-mode-hook . pdf-view-midnight-minor-mode)
     (pdf-view-mode-hook . my-pdf-view-set-midnight-colors))
    ;; lol

    :custom
    ((pdf-info-epdfinfo-program . "~/bin/epdfinfo")
     (pdf-tools-enabled-modes
      .
      '
      ( ;; keep history of previously visited pages
       pdf-history-minor-mode
       pdf-isearch-minor-mode ; can isearch
       pdf-links-minor-mode ; can find links
       pdf-outline-minor-mode ; can do outline
       ;; show size in mode-line
       ;; pdf-misc-size-indication-minor-mode
       ;; pdf-occur-global-minor-mode
       pdf-annot-minor-mode
       pdf-view-midnight-minor-mode
       pdf-view-auto-slice-minor-mode
       pdf-virtual-global-minor-mode))
     (pdf-view-display-size . 'fit-height)
     (pdf-view-continuous . t)
     (pdf-view-use-dedicated-register . nil)
     (pdf-view-max-image-width . 1080)
     (pdf-outline-imenu-use-flat-menus . t)
     (pdf-view-display-size . 'fit-page)
     (pdf-view-use-scaling . nil))
    :config
    (pdf-loader-install :no-query)
    (set-face-attribute 'pdf-links-read-link nil
                        :background (face-attribute 'mode-line :background))
    (set-face-attribute 'pdf-links-read-link nil
                        :foreground (face-attribute 'mode-line :foreground)))

  ;; Save place in PDF files.

  (leaf
    saveplace-pdf-view
    :ensure t
    :hook (pdf-view-mode-hook . save-place-mode)))

;; ** epub

(leaf
  nov
  :ensure t
  :preface
  (defun sd/nov-mode-hook ()
    (turn-on-visual-line-mode)
    (visual-line-fill-column-mode))
  :hook (nov-mode-hook . sd/nov-mode-hook)
  :bind
  (
   (:nov-mode-map
    (("C-M-a" . backward-paragraph)
     ("C-M-e" . forward-paragraph)
     ("M-n" . nov-next-document)
     ("M-p" . nov-previous-document)
     ("n" . shr-next-link)
     ("p" . shr-previous-link)
     ("g" . shrface-headline-consult) ;; nov-render-document
     ;; TODO: forward/back word C-M-f C-M-b org
     ("l" . nov-history-back)
     (";" . nov-history-forward)
     ([tab] . shrface-outline-cycle)
     ("TAB" . shrface-outline-cycle)
     ("C-t" . shrface-toggle-bullets)
     ("C-j" . shrface-next-headline)
     ("C-k" . shrface-previous-headline)
     ("a" . nil) ;; nov-reopen-as-archive
     ("M-l" . shrface-links-consult)
     ("M-g i" . consult-imenu)))
   (:nov-button-map
    (("M-n" . nov-next-document)
     ("M-n" . nov-next-document)
     ("M-p" . nov-previous-document)
     ("n" . shr-next-link)
     ("p" . shr-previous-link))))
  :custom (nov-text-width . 80)
  :mode "\\.epub\\'"
  :config
  (setq
   nov-unzip-program (executable-find "bsdtar")
   nov-unzip-args '("-xC" directory "-f" filename))
  (setq
   nov-shr-rendering-functions
   (append nov-shr-rendering-functions shr-external-rendering-functions)
   nov-header-line-format ""))

;; * buffer

(global-set-key (kbd "C-c h") #'previous-buffer)
(global-set-key (kbd "C-c l") #'next-buffer)

;; Don't ask for confirmation when reverting a buffer
(setq-default
 revert-without-query '(".*")
 whitespace-line-column 120
 require-final-newline t)

(setq large-file-warning-threshold 500000000)

;; * utilities

(lossage-size 5000)

(leaf activities
  :ensure t
  :global-minor-mode activities-mode
  :bind
  (("M-g a n" . activities-new)
   ("M-g a d" . activities-define)
   ("M-g a a" . activities-resume)
   ("M-g a s" . activities-suspend)
   ("M-g a k" . activities-kill)
   ("M-g a RET" . activities-switch)
   ("M-g a b" . activities-switch-buffer)
   ("M-g a g" . activities-revert)
   ("M-g a l" . activities-list)))

;; Functions are redefined without warning.
(leaf advice :custom (ad-redefinition-action . 'accept))

(leaf
  crux
  :ensure t
  :bind
  ((:prog-mode-map
    (("C-a" . crux-move-beginning-of-line) ("C-c C-j" . crux-top-join-line)))
   (:text-mode-map
    (("C-a" . crux-move-beginning-of-line)
     ("C-o" . crux-smart-open-line-above)))))

;; for popup-switcher
(leaf flx-ido :ensure t :require t)

;; ;; etc
;; (leaf
;;   popup-switcher
;;   :quelpa (popup-switcher :fetcher github :repo "sdobrau/popup-switcher")
;;   :custom
;;   ((psw-popup-position . 'point)
;;     (psw-use-flx . t)
;;     (psw-highlight-previous-buffer . t))
;;   :bind
;;   (("C-x b" . psw-switch-buffer)
;;     ("C-x t RET" . psw-switch-tab)
;;     ("C-x ," . psw-switch-project-files)))

(leaf
  hide-lines
  :ensure t
  :bind (("C-c h" . hide-lines) ("C-c C-h" . hide-lines-show-all)))

(leaf
  outline
  :bind
  (:outline-mode-map
   (("M-<up>" . nil)
    ("M-<down>" . nil)
    ("C-M-u" . outline-up-heading)
    ("C-M-n" . outline-next-heading)
    ("C-M-p" . outline-previous-heading)
    ("C-M-f" . outline-forward-same-level)
    ("C-M-b" . outline-backward-same-level))))

;; * window


;; drag and drop windows (frame-local only). bind to a mouse-drag event.
;; TODO: look into
;;(global-set-key (kbd "<C-s-<drag-mouse-1>") #'th/swap-window-buffers-by-dnd)

;; TODO: key to -toggle- collapsing of windows left-right , up-down

;; Some useful keybindings

(leaf
  recentf
  :ensure t
  :custom
  ((recentf-max-menu-items . 200)
   (recentf-max-saved-items . 6000)
   (recentf-auto-cleanup . t))

  :config
  (setq recentf-exclude
        `
        (,tramp-file-name-regexp
         "recentf"
         "/elpa/"
         "/elisps/"
         "\\`/tmp/"
         "/\\.git/"
         "/\\.cask/"
         "/tmp/gomi/"
         ".loaddefs.el"
         "/\\.cpanm/"
         "\\.mime-example"
         "\\.ido.last"
         "woman_cache.el"
         "\\`/proc/"
         "\\`/sys/"
         "/ssh\\(x\\)?:"
         "/su\\(do\\)?:"
         "^/usr/include/"
         "/TAGS\\'"
         "COMMIT_EDITMSG\\'"
         "CMakeCache.txt"
         "/bookmarks"
         "\\.gz$"
         "COMMIT_EDITMSG"
         "MERGE_MSG"
         "git-rebase-todo"))
  (recentf-load-list))

;;;;; * snippets

;; tempel

;; yasnippet for everything else

(leaf
  yasnippet
  :ensure t
  :preface
  (defun sd/snippet-mode-hook ()
    (interactive "P")
    ;; TODO: enable major mode of parent directory when writing
    ;; snippets
    ;; TODO: add good default values (respect indent etc)
    (sd/remove-electrics))

  :hook (snippet-mode-hook . sd/snippet-mode-hook)
  :bind
  (("C-c t y n" . yas-new-snippet)
   ("C-c t y r" . yas-reload-all)
   ("C-o" . yas-expand))
  :config
  (add-hook
   'snippet-mode-hook
   (lambda () (setq-local require-final-newline nil)))
  (defcustom yas-new-snippet-default
    "\
# -*- mode: snippet -*-
# name: $1
# key: ${2:${1:$(yas--key-from-desc yas-text)}}
# expand-env: ((yas-indent-line 'fixed) (yas-wrap-around-region 'nil))
# --
$0`(yas-escape-text yas-selected-text)`"
    "Default snippet to use when creating a new snippet.
If nil, don't use any snippet."
    :type 'string))

(leaf
  yasnippet-extras
  :hook
  ((snippet-mode-hook . koek-ws/disable-final-empty-line)
   (post-command-hook . yas-try-expanding-auto-snippets)))

;; TODO: check if dir exists. if not (new start) then move from package dir
(leaf yasnippet-snippets :ensure t)

(leaf
  consult-yasnippet
  :after consult
  :ensure t
  :bind ("C-c C-t" . consult-yasnippet))

;; TODO: make work
;; (leaf yasnippet-capf
;;   :require t
;;   :quelpa (yasnippet-capf
;;            :fetcher github
;;            :repo "elken/yasnippet-capf")
;;   :custom (yasnippet-capf-lookup-by . 'name)
;;   :config (add-to-list 'completion-at-point-functions #'yasnippet-capf))

(leaf
  auto-yasnippet
  :ensure t
  :config (setq aya-persist-snippets-dir (concat user-emacs-directory "data/snippets"))
  :bind
  (("C-c s a c" . aya-create)
   ("C-c s a e" . aya-expand)
   ("C-c s a h" . aya-expand-from-history)
   ("C-c s a d" . aya-delete-from-history)
   ("C-c s a n" . aya-next-in-history)
   ("C-c s a p" . aya-previous-in-history)
   ("C-c s a x" . aya-persist-snippet)
   ("C-c s a o" . aya-open-line)))

;; yankpad for org

(leaf
  yankpad
  :ensure t
  :custom (yankpad-file . "~/org/yankpad.org")
  :bind (("C-c t o C-<tab>" . yankpad-expand) ("C-c t o o" . yankpad-insert)))

;;;;; * pair

(leaf
  smart-hungry-delete
  :init (smart-hungry-delete-add-default-hooks)
  :ensure t
  :bind (("C-d" . smart-hungry-delete-forward-char))
  :hook ((text-mode-hook . smart-hungry-delete-default-text-mode-hook)))

(leaf
  replace
  :custom (list-matching-lines-jump-to-current-line . t)
  :hook (occur-mode-hook . hl-line-mode)
  :bind (:occur-mode-map (("t" . toggle-truncate-lines))))

;;;;; * regexp

;; TODO: customize and binds. see info
(leaf visual-replace :ensure t)

(leaf
  visual-regexp-steroids
  :ensure t
  :bind
  (("M-%" . vr/replace)
   ("C-c M-%" . vr/mc-mark)
   ("C-M-s" . vr/isearch-forward)
   ("C-M-r" . vr/isearch-backward)))

;;;;; * region operations

;; Automatically append to kill-ring when selecting by mouse
(setq-default mouse-drag-copy-region t)

;;;;; * imenu

(leaf imenu-list
  :ensure t
  :bind ("M-s i" . imenu-list-smart-toggle)
  :custom ((imenu-list-position . 'left)
           (imenu-list-idle-update-delay . 999999) ;;lol
           (imenu-list-size . 60)
           (imenu-list-focus-after-activation . t)
           (imenu-auto-rescan . nil)))

(leaf imenu-anywhere
  :ensure t
  :config
  ;;;###autoload
  (defun open-project-files-in-background ()
    "Open/find all source files in the background which are tracked by Git."
    (let ((default-directory (vc-root-dir)))
      (save-window-excursion
        (dolist (file (split-string (shell-command-to-string "git ls-files")))
          (unless (find-buffer-visiting file)
            (with-current-buffer (find-file-noselect file)
              (if (equal (get major-mode 'derived-mode-parent) 'prog-mode)
                  (bury-buffer)
                (kill-buffer))))))))

;;;###autoload
  (defun open-project-files-in-background-maybe (&rest _args)
    "Prepare a project-wide `Imenu'."
    (interactive)
    ;; 'vc-root-dir returns nil when not tracked, so checking if (not
    ;; that it is in a list that contains nil) is enough for both
    ;; (non-nil and in the list of fully opened projects)
    (defvar fully-opened-projects '(nil) "List of project paths, each has all tracked files opened.")
    (let ((git-dir (vc-root-dir)))
      (unless (member git-dir fully-opened-projects)
        (open-project-files-in-background)
        (push git-dir fully-opened-projects))))
  (advice-add 'imenu-anywhere :before 'open-project-files-in-background-maybe))

;;;;; * search

(leaf isearch
  :custom
  ((search-highlight . t)
   (search-whitespace-regexp . ".*?")
   (isearch-lax-whitespace . t)
   (isearch-regexp-lax-whitespace . nil)
   ;; would be stuck in search otherwise
   (search-nonincremental-instead . nil)
   (isearch-lazy-highlight . t)
   (isearch-lazy-count . t) ;; show match numbers in prompt
   (lazy-highlight-initial-delay . 6)
   (lazy-highlight-interval . 1)
   (lazy-highlight-no-delay-length . 10)
   (lazy-count-prefix-format . nil)
   (isearch-lazy-count-suffix-format . " (%s/%s)")
   (isearch-yank-on-move . 'shift) ;; motion keys yank txt to srch str
   (isearch-allow-scroll . 'unlimited) ;; allow scrolling when isearchin
   (isearch-repeat-on-direction-change . t)
   (isearch-wrap-pause . t))
  :bind
  (
   (:isearch-mode-map
    (("C-g" . isearch-cancel)
     ("C-d" . isearch-forward-symbol-at-point) ;; instead of isearch-abort
     ("M-/" . isearch-complete) ("C-o" . sd/isearch-deadgrep)))
   (:minibuffer-local-isearch-map
    (("M-/" . isearch-complete-edit) ("C-M-p" . isearch-delete-wrong)))))

(leaf occur-context-resize
  :ensure t
  :hook (occur-mode-hook . occur-context-resize-mode))

;;'loccur': show lines matching string in the current buffer.

(leaf loccur
  :ensure t
  :custom (loccur-jump-beginning-of-line . t)
  :bind (("M-s C-o" . loccur)
         ("M-s M-o" . loccur-current) ;; word-at-point
         ("M-s C-<" . loccur-previous-match)))

;;;;; * movement

;;;;; * project

(leaf isearch-project
  :ensure t
  :bind
  (:project-prefix-map
   :package
   project
   (("C-s" . isearch-project-forward-symbol-at-point))))

(leaf find-file-in-project
  :ensure t
  :custom (ffip-use-rust-fd . t)
  :bind
  (:project-prefix-map
   (("f" . find-file-in-project)
    ("d" . find-directory-in-project-by-selected))))

(leaf
  bookmark-in-project
  :ensure t
  :bind
  (("C-x r C-n" . bookmark-in-project-jump-next)
   ("C-x r C-p" . bookmark-in-project-jump-previous)
   ("C-x r RET" . bookmark-in-project-toggle)
   ("C-x r C-j" . bookmark-in-project-jump)))

;; =M-del=: delete subword.
;; =C-m-<backspace>=: delete superword.

;; some binds
;; TODO: lazy

(leaf
  simple
  :bind (("C-x f 2" . end-of-buffer) ("C-x f 1" . beginning-of-buffer)))

(setq-default
 scroll-conservatively 10000
 maximum-scroll-margin 0.5
 scroll-error-top-bottom nil
 ;; Preserve screen point position when scrolling
 scroll-preserve-screen-position t
 fast-but-imprecise-scrolling t
 ;; counter emacs sluggishness when scrolling very fast
 scroll-margin 9999)

;;;;; * editing

(leaf
  comment-extras
  :bind
  (("C-M-;" . comment-box)))

(leaf comnt-hide :bind ("C-c M-;" . hide/show-comments-toggle))

(setq byte-compile-dynamic-docstrings t)

;;;;; * undo

(leaf ace-jump-zap :ensure t :bind ("M-z" . ace-jump-zap-up-to-char))

(global-set-key (kbd "C-c M-u") #'upcase-char)

(leaf
  editing-extras
  :bind
  (("M-d" . kill-word-dwim)
   ;; TODO: backward-kill-superword / kill-superword-at-point
   ("M-DEL" . backward-kill-word-or-join-lines) ;; M-DEL backward-kill-word
   
   ;; ("C-M-c -" . daanturo-recenter-region-in-window)
   ;; ("C-M-c |" . daanturo-recenter-left-right)
   ("C-x 8 t" . daanturo-insert-and-copy-date)
   ("C-x 8 M-t" . daanturo-insert-and-copy-date-and-time) ;; no mark modified if change
   ("C-x M-%" . daanturo-query-replace-regexp-in-whole-buffer)))

;; TODO: good keymap
(leaf
  surround
  :ensure t
  :require t
  :bind
  ("C-c M-w" . surround-mark)
  (:surround-keymap
   (("i" . surround-mark-inner)
    ("'" . surround-insert)
    ("SPC" . surround-mark))))

(leaf filladapt :ensure t)

(setq-default set-mark-command-repeat-pop t)

(leaf phi-rectangle
  :ensure t
  :bind ("C-x SPC" . phi-rectangle-set-mark-command))


;; * movement


(leaf dogears
  :ensure t
  :global-minor-mode dogears-mode
  :bind (("C-x f p" . dogears-back)
         ("C-x f n" . dogears-forward)))

(leaf register-quicknav
  :ensure t
  :require t
  :bind (("C-x f r p" . register-quicknav-prev-register)
         ("C-x f r n" . register-quicknav-next-register)
         (("C-x f r r" . register-quicknav-point-to-unused-register)
          ("C-x f r d" . register-quicknav-clear-current-register))))

(leaf register :custom (register-use-preview . 'never))

;; 2. bookmark for bookmark-wide - alt
;; TODO: replace with harpoon?
;; https://github.com/otavioschwanck/harpoon.el

(leaf bookmark
  :custom ((bookmark-fontify . nil)
           ;; save bookmark file whenever bookmarks are modified
           (bookmark-save-flag . 1)
           (bookmark-version-control . t)
           (bookmark-automatically-show-annotations . t))
  :config
  (setq bookmark-default-file
        ;; behaviour
        (no-littering-expand-var-file-name "bookmark-default.el")))

(leaf
  rings
  :custom
  ((global-mark-ring-max . 15000)
   (mark-ring-max . 1500)
   (kill-ring-max . 1500)
   (kill-do-not-save-duplicates . t)))

(leaf
  movement-extras
  :bind
  (
   (:prog-mode-map
    (([remap next-line] . zk-phi-next-line)
     ([remap previous-line] . zk-phi-previous-line)))
   (:text-mode-map
    (([remap next-line] . zk-phi-next-line)
     ([remap previous-line] . zk-phi-previous-line)))
   ;; 'python-mode-map' void error when loading this
   ;; do i have to?
   ;; (:python-mode-map
   ;;  (([remap next-line] . zk-phi-next-line)
   ;;   ([remap previous-line] . zk-phi-previous-line)))
   ;; only forward, backward is default.
   ("M-f" . koek-mtn/next-word)))

;; =M-del=: delete subword.
;; =C-m-<backspace>=: delete superword.

(leaf subword-extras :bind (("C-M-<backspace>" . backward-kill-superword)))


;; ** goto family
(leaf
  goto-chg
  :ensure t
  :bind (("M-g l" . goto-last-change) ("M-g C-l" . goto-last-change-reverse)))

(leaf goto-address :ensure nil :hook (global-goto-address-mode))

(leaf
  goto-char-preview
  :ensure t
  :bind (("M-g c" . nil) ("M-g c" . goto-char-preview)))

(leaf
  goto-line-preview
  :ensure t
  :bind (("M-g g" . nil) ("M-g g" . goto-line-preview)))

;; ** jumping

(leaf
  ace-jump-mode
  :ensure t
  :bind ("C-M-j" . ace-jump-char-mode)
  :custom (ace-jump-mode-gray-background . nil))

(leaf
  smartscan
  :ensure t
  :bind
  (
   (:special-mode-map
    (("M-n" . smartscan-symbol-go-forward)
     ("M-p" . smartscan-symbol-go-backward)))
   (:Man-mode-map
    (("M-n" . smartscan-symbol-go-forward)
     ("M-p" . smartscan-symbol-go-backward))))

  :custom ((smartscan-symbol-selector . "symbol") (smartscan-use-extended-syntax . t)))

(leaf smart-mark :ensure t)

;; some binds
;; TODO: lazy

(leaf beginend :ensure t)

(leaf
  simple
  :bind (("C-x f 2" . end-of-buffer) ("C-x f 1" . beginning-of-buffer)))

;; ** scroll

(setq-default
 scroll-conservatively 10000
 maximum-scroll-margin 0.5
 scroll-error-top-bottom nil
 ;; Preserve screen point position when scrolling
 scroll-preserve-screen-position t
 fast-but-imprecise-scrolling t
 ;; counter emacs sluggishness when scrolling very fast
 scroll-margin 5)

;; * org
;; ** org main

(leaf
  org
  :ensure nil ;; already covered from org-plus-contrib install
  :preface

  (defun sd/org-paste-as-child-subtree (&optional arg)
    "Paste kill as child subtree of tree at point."
    (interactive "P")
    (org-paste-subtree (+ (org-outline-level) 1)))
  (defun sd/hide-pandoc-org-stuff ()
    (hide-lines-matching "<<.*>>")
    (hide-lines-matching ".*.png")
    (hide-lines-matching ".*data:.*")
    (hide-lines-matching "[[.*][]].*"))

  ;; from Sophie
  (defun sophie/org-mark-as-done ()
    (interactive)
    (save-excursion
      (org-back-to-heading t) ;; Make sure command works even if point is
      ;; below target heading
      (cond
       ((looking-at "\*+ TODO")
        (org-todo "DONE"))
       ((looking-at "\*+ NEXT")
        (org-todo "DONE"))
       ((looking-at "\*+ WAIT")
        (org-todo "DONE"))
       ((looking-at "\*+ PROG")
        (org-todo "DONE"))
       ((looking-at "\*+ DONE")
        (org-todo "DONE"))
       (t
        (message "Undefined TODO state.")))))

  ;; TODO: what?
  ;; (require 'org-protocol)
  (defun org-summary-todo (n-done n-not-done)
    "switch entry to DONE when all subentries are done, to TODO otherwise."
    (let
        (
         org-log-done
         org-log-states) ; turn off logging
      (org-todo
       (if (= n-not-done 0)
           "DONE"
         "TODO"))))

  (defun my-org-capture-todo ()
    (interactive)
    (org-capture-string nil (kbd "t")))

  (defun sd/org-mode-hook (&optional arg)
    (interactive "P")
    (auto-fill-mode)
    (setq-local fill-column 80)
    (if (display-graphic-p)
        (org-variable-pitch-minor-mode))
    (display-fill-column-indicator-mode)
    (turn-on-visual-line-mode))

  (defun sd/org-src-mode-hook (&optional arg)
    (interactive "P")
    (auto-fill-mode)
    (setq-local fill-column 80)
    (display-fill-column-indicator-mode))

  :hook
  ((org-mode-hook . sd/org-mode-hook)
   (org-src-mode-hook . sd/org-src-mode-hook))
  :bind
  (("C-c M-t" . my-org-capture-todo)
   (:org-mode-map
    ( ;; list
     ("C-c C-x i" . sd/org-paste-as-child-subtree)
     ("C-M-a" . backward-paragraph)
     ("C-M-e" . forward-paragraph)
     ("M-n" . org-next-item)
     ("M-p" . org-previous-item)
     ("M-J" . org-move-subtree-down)
     ("M-K" . org-move-subtree-up)
     ("C-M-j" . org-move-item-down)
     ("C-M-k" . org-move-item-up)
     ;; don't need archive
     ;; because bookmark
     ("C-c !" . nil) ;; org-timestamp-inactive
     ("C-c d" . sophie/org-mark-as-done)
     ("M-<up>" . nil)
     ("M-<down>" . nil)
     ("M-<left>" . nil)
     ("M-<right>" . nil)
     ("C-c M-<up>" . org-metaup)
     ("C-c M-<down>" . org-metadown)
     ("C-c M-<left>" . org-metaleft)
     ("C-c M-<right>" . org-metaright)
     ("C-c C-x C-a" . nil)
     ("C-M-c" . sd/org-toggle-checkbox-presence)
     ("C-c C-M-c" . sd/org-new-checkbox-item)
     ("C-c C-q" . counsel-org-tag)
     ("C-c l" . org-open-at-point-global)
     ("C-c q" . org-set-tags-command)
     ("C-c M-l" . org-store-link)
     ("C-c i" . org-insert-last-stored-link)
     ("C-M-q" . org-fill-paragraph)
     ("C-c a" . org-agenda)
     ("C-," . nil) ;; org-cycle-agenda-files
     ("M-h" . mark-paragraph)
     ("C-M-l" . org-metaright)
     ("C-M-h" . org-metaleft)
     ("C-M-j" . org-metadown)
     ("C-M-k" . org-metaup)
     ("M-L" . org-shiftmetaright)
     ("M-H" . org-shiftmetaleft)
     ("s-<return>" . org-insert-item)
     ("C-c c" . org-capture)
     ("C-c C-l" . nil) ;; org clip link
     ("C-c C-o" . org-open-at-point-global)
     ("C-M-f" . org-forward-heading-same-level)
     ("C-M-b" . org-backward-heading-same-level)
     ("C-M-n" . org-next-visible-heading)
     ("C-M-p" . org-previous-visible-heading)
     ("C-M-u" . outline-up-heading)
     ("C-M-d" . org-down-element)
     ("C-c M-o" . nil)
     ("M-s-n" . org-forward-element)
     ("M-s-p" . org-backward-element)
     ("M-s-u" . org-up-element)
     ("M-s-d" . org-down-element)
     ("C-c '" . org-edit-special)
     ("C-<" . org-babel-previous-src-block)
     ("C->" . org-babel-next-src-block)
     ("C-c C-v w" . org-babel-mark-block)))
   ;; mark-ring
   ;; TODO fix with outshine
   ("C-c M-a" . org-mark-ring-push)
   ("C-c M-g" . org-mark-ring-goto)
   (:org-src-mode-map (("C-c C-c" . org-edit-src-exit))))

  :custom
  ((org-ellipsis . " ") ;; nothing
   ;; (org-src--allow-write-back . nil)
   ;; add id always
   (org-id-link-to-org-use-id . nil)
   ;; hide leading stars
   (org-hide-leading-stars . t)
   (org-pretty-entities . t)
   ;; refile
   (org-refile-targets . '((nil . (:maxlevel . 15))))
   ;; ;; A\B\NewC -> NewC appended to B
   (org-refile-allow-creating-parent-nodes . t)
   (org-refile-use-cache . nil)
   (org-refile-use-outline-path . 'file)
   (org-outline-path-complete-in-steps . nil)
   ;; ;; linking
   (org-return-follows-link . t)
   (org-tab-follows-link . t)
   ;; (org-link-keep-stored-after-insertion . nil)
   (org-link-file-path-type . 'absolute)

   ;; folding
   (org-startup-folded . nil)
   ;; show point when editing invisible region
   (org-catch-invisible-edits . 'show)
   (org-M-RET-may-split-line . nil)
   ;; ;; when motioning in lists, cycle/circular
   (org-list-use-circular-motion . t)
   ;; show headline, ancestors and entries+children in all org views
   (org-show-context-detail . t)
   (org-startup-indented . nil)
   (org-adapt-indentation . nil)
   ;; properties are inherited
   (org-use-property-inheritance . t)
   ;; org-use-property-inheritance ("property" "property" ...)
   ;; properties to inherit
   ;; dont display date prompt interpretation
   (org-read-date-display-live . nil)
   ;; org clock+occur highlights not removed if
   ;; editing, c-c c-c to remove highlights
   (org-remove-highlights-with-change . nil)
   ;; get image width from #+attr keyword in org file,
   ;; otherwise default
   (org-image-actual-width . 100)
   ;; depth of org headers parsing for imenu
   (org-element-use-cache . nil) ;; TODO: buggy, no
   (org-element-cache-persistent . nil)
   (org-imenu-depth . 9)
   ;; ;; TAGS ;;
   ;; (org-tag-alist . '(("easy" . ?e) ("medium" . ?m) ("hard" . ?h)))
   ;; ;; LINKS ;;
   ;; (org-link-use-indirect-buffer-for-internals . nil)
   ;; ;; keep links in link list/store for entire session
   ;; (org-link-keep-stored-after-insertion . t)
   ;; ;; ret follows link in org-mode also
   ;; (org-return-follows-link . nil)
   ;; ;; abbreviations for links in org mode
   ;; ;; e.g. [[bugzilla:138]][description] > id=138
   ;; ;; e.g. [[omap:3]][description] > search?q=1
   ;; ;; [[tag:value]][description]
   ;; ;; todo: add more for exploits
   ;; (org-link-abbrev-alist
   ;;  .
   ;;  '(("bugzilla"
   ;;     . "http://10.1.2.9/bugzilla/show_bug.cgi?id=")
   ;;    ("nu html checker"
   ;;     . "https://validator.w3.org/nu/?doc=%h")
   ;;    ("duckduckgo"
   ;;     . "https://duckduckgo.com/?q=%s")
   ;;    ("omap"
   ;;     . "http://nominatim.openstreetmap.org/search?q=%s&polygon=1")
   ;;    ("ads"
   ;;     . "https://ui.adsabs.harvard.edu/search/q=%20author%3a\"%s\"")))
   ;; ;; t0d0 ;;
   ;; ;; parent node not done if children not done
   ;; (org-enforce-todo-dependencies . t)
   ;; (org-use-fast-todo-selection . 'expert)
   ;; ;; todo covers all children, not just direct
   ;; (org-hierarchical-todo-statistics . nil)
   ;; ;; keywords for entering a todo item, c-c c-t keyword
   ;; (org-todo-keywords
   ;;  .
   ;;  '((sequence "TODO(t)" "|" "DONE(d)" "|" "TORESEARCH(r)") ;; sequence 1
   ;;    ;; seq 2
   ;;    (sequence "bug(b)" "knowncause(k)" "|" "fixed(f)")
   ;;    (sequence "|" "canceled(c)")))

   ;; ;; todo with checkboxes inside todo entry cannot be marked as done
   ;; (org-enforce-todo-checkbox-dependencies . t)
   ;; ;; priorities for todo lists
   ;; (org-priority-highest . 1)
   ;; (org-priority-lowest . 20)
   ;; ;; keep :closed: property even if no todo
   ;; (org-closed-keep-when-no-todo . t)
   ;; ;; attach ;;
   ;; ;; set attachment dir to be relative to current dir
   ;; (org-attach-dir-relative . t)
   ;; ;; set attach to inherit id+dir from parents, however can
   ;; ;; override per-entry/outline setting but specifying dir
   ;; ;; and id again
   ;; ;; dir takes precedence over id
   ;; (org-attach-use-inheritance . t)
   ;; ;; attach using "dir" method when attaching to nodes w/o id/dir prop
   ;; (org-attach-preferred-new-method . 'dir)
   ;; ;; don't delete attachments when archiving an entry
   ;; (org-attach-archive-delete . nil)
   ;; ;; org-attach-auto-tag.. what?
   ;; ;; store link to attachment in org link store when adding attachment
   ;; (org-attach-store-link-p . t)
   ;; ;; don't show attachment splash buffer when adding an attachment
   ;; (org-attach-expert . t)
   ;; ;; log ;;
   ;; ;; ask for note when changing deadline
   ;; (org-log-redeadline . 'note)
   ;; ;; ask for note when changing schedule
   ;; (org-log-reschedule . 'note)
   ;; ;; record note when clocking out
   ;; (org-log-note-clock-out . t)
   ;; ;; don’t do anything when refiling
   ;; (org-log-refile . nil)
   ;; ;; record note when clocking out
   ;; (org-log-note-clock-out . t)
   ;; ;; ???
   ;; (org-log-into-drawer . t) ;; logbook
   ;; ;; babel ;;
   (org-src-fontify-natively . t)
   ;; ;; TODO: uhhh
   ;; ;; (org-fontify-quote-and-verse-blocks . t)
   ;; ;; (org-fontify-whole-heading-line . t)
   ;; ;; don't ask for confirmation when evaluating with babel
   (org-confirm-babel-evaluate . nil)
   (org-link-elisp-confirm-function . nil)
   (org-edit-src-auto-save-idle-delay . 2)
   (org-edit-src-persistent-message . nil)
   (org-edit-src-turn-on-auto-save . t)
   (org-hide-block-startup . nil)
   (org-cycle-hide-block-startup . nil)
   (org-src-ask-before-returning-to-edit-buffer . nil)
   (org-src-strip-leading-and-trailing-blank-lines . t)
   ;; show dedicated buffer in current window
   (org-src-window-setup . 'current-window)
   ;; don’t preserve leading whitespace characters
   (org-src-preserve-indentation . nil)
   (org-edit-src-content-indentation . 0)
   (org-src-tab-acts-natively . t)
   (org-babel-load-languages
    .
    '
    ((emacs-lisp . t)
     (scheme . t) (ruby . t) (python . t)
     ;; (sh . t) todo get ob-sh
     ;;(c . t)
     (lisp . t) (shell . t))))

  :config
  (setq org-default-notes-file (concat my-org-directory "notes2.org"))
  (set-face-attribute 'org-link nil :inherit 'org-archived)

  ;;;;;;;;;;;;
  ;; agenda ;;
  ;;;;;;;;;;;;

  (setq org-agenda-files `(,(concat my-org-directory "/agenda2.org")))

  (setq org-attach-id-dir (concat my-org-directory "/attachments")))

;; ** org utilities

(leaf
  org-bookmark-heading
  :ensure t
  :commands
  org-mode
  bookmark-jump
  :custom (org-bookmark-jump-indirect . t))

(leaf
  outshine
  ;; TODO: keybindings
  :ensure t
  ;; add also to conf-unix
  :custom
  ((outshine-cycle-silently . t)
   (outshine-fontify-whole-heading-line . t)
   (outshine-max-level . 15))
  :bind
  (:outshine-mode-map
   ;; for bookmark
   ("M-<up>" . nil)
   ("M-<down>" . nil)
   ("<backtab>" . nil) ;; outshine-kbd-<backtab>
   ("M-g o" . consult-outline)
   ("C-x M-RET" . outshine-insert-heading)
   ("C-c RET" . outshine-kbd-M-RET) ; conflict with ansible RET
   ("C-i" . nil) ; outshine cycle-buffer conflict with tempel-expand
   ("C-c C-n" . outline-next-heading)
   ("C-c C-p" . outline-previous-heading)
   ("C-c C-M-n" . outline-forward-same-level)
   ("C-c C-M-p" . outline-backward-same-level)
   ("C-c C-M-u" . outline-up-heading)
   ("C-x n s" . outshine-narrow-to-subtree)
   ("C-x n w" . widen)))

;; ** shr/eww/shrface

(leaf
  shr-tag-pre-highlight
  :ensure t
  :commands shr-tag-pre-highlight
  :custom
  (shr-tag-pre-highlight-lang-modes
   .
   '
   (("ocaml" . tuareg)
    ("elisp" . emacs-lisp)
    ("ditaa" . artist)
    ("asymptote" . asy)
    ("dot" . fundamental)
    ("sqlite" . sql)
    ("calc" . fundamental)
    ("C" . c)
    ("cpp" . c++)
    ("C++" . c++)
    ("screen" . shell-script)
    ("shell" . sh)
    ("bash" . sh)
    ("rust" . rustic)
    ("rust" . rustic)
    ("awk" . bash)
    ("json" . "js")
    ;; Used by language-detection.el
    ("emacslisp" . emacs-lisp)
    ;; Used by Google Code Prettify
    ("el" . emacs-lisp))))

(leaf
  shrface
  :ensure t
  :commands
  eww
  nov
  :hook
  (
   (
    (shrface-mode-hook
     .
     (lambda ()
       (progn
         (visual-line-fill-column-mode)
         (setq-local org-startup-truncated nil)
         (setq-local outline-regexp "[*]+"))))))
  :bind
  (
   (:eww-mode-map
    (("<backtab>" . nil)
     ("g" . nil))) ; previous link eww
   (:shrface-mode-map
    (("M-l" . shrface-links-consult) ;; lol
     ("M-h" . mark-paragraph) ;; originally org-mark-element
     ("C-x n s" . org-narrow-to-subtree)
     ("M-g" . consult-imenu)
     ("C-x n w" . widen)
     ("C-M-f" . org-forward-heading-same-level)
     ("C-M-b" . org-backward-heading-same-level)
     ("C-M-n" . shrface-next-headline)
     ("C-M-p" . shrface-previous-headline)
     ("C-M-u" . outline-up-heading)
     ("TAB" . shrface-outline-cycle)
     ("<backtab>" . shrface-outline-cycle-buffer)
     ("C-c C-e o" . shrface-html-export-as-org))))
  :custom
  ((shrface-href-versatile . t)
   (shrface-cookie-policy . nil)
   (shrface-bullets-bullet-list . '("*" "**" "***" "****"))
   (shrface-paragraph-fill-column . 80))

  :config (add-hook 'outline-view-change-hook #'shrface-outline-visibility-changed)

  (set-face-attribute 'shrface-href-face nil
                      :inherit 'variable-pitch
                      :foreground (face-attribute 'org-level-2 :foreground)))

;; * eww

;; First, rendering library
(leaf
  shr
  :custom
  ((shr-max-width . 80)
   (shr-max-image-proportion . 0.7)
   (shr-width . 80) ;
   ;; don’t render aria-hidden=true tags
   (shr-discard-aria-hidden . t)
   (shr-image-animate . nil) ; don’t animate gifs!
   (shr-use-colors . nil) ; don’t use colors! too flashy!
   (shr-cookie-policy . t) ;; for google search, etc
   (shr-folding-mode . t)
   (shr-offer-extend-specpdl . nil)
   (url-privacy-level . 'none)
   (browse-url-new-window-flag . nil) ;; never use a new window
   (url-automatic-caching . t)
   (browse-url-browser-function . #'eww-browse-url)))

;; loaded when running eww
(leaf shr-extras)

;; Then, browser
(leaf
  eww
  ;; TODO: lazy
  :require t
  :commands eww
  :preface
  (defun sd/eww-visit-clip-link (&optional arg)
    "Visit link in clipboard using EWW."
    (interactive "P")
    (eww (substring-no-properties (pop kill-ring))))
  (defun sd/eww-up-to-w3m (&optional arg)
    "Jump up to w3m see if the page works"
    (interactive "P")
    (w3m (eww-current-url)))
  (defun shrface-eww-setup ()
    (unless shrface-toggle-bullets
      (shrface-regexp)
      (setq-local imenu-create-index-function #'shrface-imenu-get-tree))
    ;; (add-function :before-until (local 'eldoc-documentation-function) #'paw-get-eldoc-note)
    ;; workaround to show annotations in eww
    (when (bound-and-true-p paw-annotation-mode)
      (paw-clear-annotation-overlay)
      (paw-show-all-annotations)
      (if paw-annotation-show-wordlists-words-p
          (paw-focus-find-words :wordlist t))
      (if paw-annotation-show-unknown-words-p
          (paw-focus-find-words))))

  (defun shrface-eww-advice (orig-fun &rest args)
    (require 'eww)
    (let
        (
         (shrface-org nil)
         (shr-bullet (concat (char-to-string shrface-item-bullet) " "))
         (shr-table-vertical-line "|")
         (shr-width 65)
         (shr-indentation 0)
         (shr-external-rendering-functions
          (append
           '
           ((title . eww-tag-title)
            (form . eww-tag-form)
            (input . eww-tag-input)
            (button . eww-form-submit)
            (textarea . eww-tag-textarea)
            (select . eww-tag-select)
            (link . eww-tag-link)
            (meta . eww-tag-meta)
            ;; (a . eww-tag-a)
            (code . shrface-tag-code)
            (pre . shr-tag-pre-highlight))
           shrface-supported-faces-alist))
         (shrface-toggle-bullets nil)
         (shrface-href-versatile t)
         (shr-use-fonts nil))
      (apply orig-fun args)))

  (defun sd/eww-hook ()
    (sd/remove-electrics)
    ;;(eldoc-overlay-mode -1)
    (setq-local fill-column 80)
    ;; to take new column-width for nice filling
    ;; when changing window size
    )
  (defun sd/eww-after-render-hook (&optional arg)
    ;; (org-indent-mode)
    (eldoc-mode)
    (eldoc-box-hover-at-point-mode)
    (shrface-eww-setup)
    ;;(eww-readable)
    ;; TODO: make this nicer
    ;; (add-hook 'window-configuration-change-hook #'(lambda () (eww-reload t))
    ;;   nil
    ;;   t)
    (shrface-mode))
  :hook
  ((eww-mode-hook . sd/eww-hook)
   (eww-after-render-hook . sd/eww-after-render-hook))
  :bind
  (("M-s C-M-w" . sd/eww-visit-clip-link)
   (:eww-mode-map
    (("W" . sd/eww-up-to-w3m)
     ("C-M-a" . backward-paragraph)
     ("C-M-e" . forward-paragraph)
     ("M-RET" . eww-open-in-new-buffer)
     ("h" . eww-list-histories)
     ("v" . nil) ;; to stop accidental hitting of 'eww-view-source'
     ("r" . eww-reload)
     ("g" . consult-imenu)
     ("i" . consult-imenu)
     ;; ("." . sd/browse-chrome)
     ("C-q" . kill-this-buffer)
     (";" . eww-forward-url) ;; after l
     ("n" . shr-next-link)
     ("p" . shr-previous-link)
     ("," . eww-reload)))
   (:dired-mode-map (("e" . eww-open-file))))
  :custom
  ;; don't delete history?
  ((eww-before-browse-history-function . 'ignore)
   (eww-header-line-format . nil)
   (eww-history-limit . 99999)
   (eww-restore-desktop . t)
   ;; tab support
   (browse-url-new-window-flag . t)
   (eww-browse-url-new-window-is-tab . nil)
   (eww-desktop-remove-duplicates . t)
   (eww-auto-rename-buffer . nil) ;; covered by 'epithet'
   (eww-form-checkbox-selected-symbol . "[x]")
   (eww-form-checkbox-symbol . "[ ]")
   ;; TODO: fix
   (eww-search-prefix . "https://www.google.com/search?ion=1&q="))
  :config
  ;; for shrface
  (require 'shrface)
  (advice-add 'eww-display-html :around #'shrface-eww-advice)
  (defun mw-start-eww-for-url (plist)
    "Raise Emacs and call eww with the url in PLIST."
    (eww (plist-get plist :url))
    nil)

  (setq browse-url-secondary-browser-function 'browse-url-default-browser)

  ;; make button/form/input styling consistent with theme
  (mapc
   (lambda (x)
     (set-face-attribute x nil
                         :foreground (face-attribute 'custom-button-unraised :foreground)
                         :background (face-attribute 'custom-button-unraised :background)))

   '
   (eww-form-file
    eww-form-checkbox
    eww-form-select
    eww-form-submit
    eww-form-text
    eww-form-textarea))

  (setq eww-download-directory
        (no-littering-expand-var-file-name "eww/downloads/"))
  ;; inhibit images by default
  ;; use my/eww-toggle-images to toggle them back on (bound to i)
  (setq-default shr-inhibit-images t)
  (setq eww-bookmarks-directory
        (no-littering-expand-var-file-name "eww/bookmarks/"))
  :if (executable-find "rdrview")
  :custom
  ;; TODO: filter for domain/s
  ;; (eww-retrieve-command
  ;;   .
  ;;   '
  ;;   ("rdrview"
  ;;     "-H"
  ;;     "-E"
  ;;     "utf-8"
  ;;     "-P"
  ;;     "-A"
  ;;     "Firefox"
  ;;     "-T"
  ;;     "title,sitename,url,body,byline,excerpt"))
  )

(leaf
  eww-extras
  ;; TODO: lazy
  :require t
  :bind (:eww-mode-map (("D" . sd/h2o-current-eww-url))))

(leaf
  shr-tag-pre-highlight
  :ensure t
  :commands shr-tag-pre-highlight
  :custom
  (shr-tag-pre-highlight-lang-modes
   .
   '
   (("ocaml" . tuareg)
    ("elisp" . emacs-lisp)
    ("ditaa" . artist)
    ("asymptote" . asy)
    ("dot" . fundamental)
    ("sqlite" . sql)
    ("calc" . fundamental)
    ("C" . c)
    ("cpp" . c++)
    ("C++" . c++)
    ("screen" . shell-script)
    ("shell" . sh)
    ("bash" . sh)
    ("rust" . rustic)
    ("rust" . rustic)
    ("awk" . bash)
    ("json" . "js")
    ;; Used by language-detection.el
    ("emacslisp" . emacs-lisp)
    ;; Used by Google Code Prettify
    ("el" . emacs-lisp))))

;; * flymake and flycheck

;; make flymake backends work with flycheck

(leaf flymake
  :ensure t
  :bind
  (:flymake-mode-map
   (("C-<left>" . flymake-goto-next-error)
    ("C-<right>" . flymake-goto-prev-error)
    ("M-g M-f" . flymake-show-project-diagnostics))))

(leaf flymake-flycheck
  :ensure t
  :hook (flymake-mode-hook . flymake-flycheck-auto))

(leaf flycheck
  :ensure t
  ;; make it fast
  :custom
  ((flycheck-idle-change-delay . 5)
   (flycheck-idle-b-switch-delay . 3)
   (flycheck-indication-mode . 'left-fringe)
   (flycheck-standard-error-navigation . t)
   (flycheck-deferred-syntax-check . nil)
   (flycheck-display-errors-delay . 2)
   (flycheck-highlighting-mode . 'symbols)
   ;; use load path of current emacs session for checking
   (flycheck-emacs-lisp-load-path . 'inherit)
   (flycheck-relevant-error-other-file-show . nil)
   ;; when saving
   (flycheck-check-syntax-automatically . '(save new-line))
   ;; navigate compilation errors, not standard errors with error
   ;; navigation keys
   (flycheck-standard-error-navigation . nil)
   (next-error-function . #'flycheck-next-error-function)
   (previous-error-function . #'flycheck-previous-error-function)))

;; TODO: try out just flymake combined atm
(leaf flycheck-inline
  :ensure t
  :hook (flycheck-mode-hook . flycheck-inline-mode)
  ;; use quick-peek for nice box display
  :config
  (setq
   flycheck-inline-display-function
   (lambda (msg pos err)
     (let*
         (
          (ov (quick-peek-overlay-ensure-at pos))
          (contents (quick-peek-overlay-contents ov)))
       (setf (quick-peek-overlay-contents ov)
             (concat
              contents
              (when contents
                "\n")
              msg))
       (quick-peek-update ov)))
   flycheck-inline-clear-function #'quick-peek-hide))

;; * modes

;; ** general prog mode

;; ** eldoc

(leaf eldoc :ensure t :custom ((eldoc-echo-area-use-multiline-p nil)
                               (eldoc-documentation-strategy . #'eldoc-documentation-compose))
  (eldoc-idle-delay . 0.5))

(leaf eldoc-box :ensure t)

;; main config

(leaf
  prog-mode
  :preface
  ;; spaces but tabs if available
  ;; https://www.emacswiki.org/emacs/SiteMap

  (defun infer-indentation-style ()
    ;; if our source file uses tabs, we use tabs, if spaces spaces, and if
    ;; neither, we use the current indent-tabs-mode
    (let
        (
         (space-count (how-many "^  " (point-min) (point-max)))
         (tab-count (how-many "^\t" (point-min) (point-max))))
      (if (> space-count tab-count)
          (setq indent-tabs-mode nil))
      (if (> tab-count space-count)
          (setq indent-tabs-mode t))))

  (defun sd/prog-mode-hook (&optional arg)
    "My setup for `prog-mode'."
    (interactive "P")
    ;; things to disable
    (ispell-minor-mode -1)
    ;; global in after-init
    (eldoc-box-hover-at-point-mode)
    ;; (add-to-list 'completion-at-point-functions #'cape-file)
    ;; (add-to-list 'completion-at-point-functions #'cape-dabbrev)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; (add-to-list 'completion-at-point-functions #'cape-keyword) ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; (add-to-list 'completion-at-point-functions #'yasnippet-capf)
    (yas-minor-mode)
    ;; (company-mode)
    ;; (company-quickhelp-mode)
    ;; (corfu-mode)
    ;; setup capf for tempel
    ;; others
    ;; (bug-reference-github-set-url-format)
    ;;(electric-operator-mode) buggy?
    ;; visual
    (smart-hungry-delete-add-default-hooks)
    (column-number-mode)
    (page-break-lines-mode)
    (visual-line-mode)
    (push '("<=" . ?≤) prettify-symbols-alist)
    (push '(">=" . ?≥) prettify-symbols-alist)

    (setq-local fill-column 80)
    (display-fill-column-indicator-mode)
    ;; general
    ;; (diff-hl-mode)
    ;;(electric-quote-local-mode -1)
    ;;(electric-pair-local-mode -1)
    ;;(electric-layout-local-mode -1)
    (smart-hungry-delete-default-prog-mode-hook)
    (display-line-numbers-mode)
    (which-function-mode)
    (outline-minor-mode)
    (hs-minor-mode)
    (goto-address-prog-mode)
    (outshine-mode)
    ;; (ws-butler-mode)
    ;;(move-dup-mode)
    (smartscan-mode)
    (show-paren-mode)
    (auto-fill-mode)
    ;; indentation
    (setq-local indent-tabs-mode nil)
    (infer-indentation-style)
    (electric-indent-local-mode)
    (aggressive-indent-mode))
  :hook (prog-mode-hook . sd/prog-mode-hook))

;; ** Parentheses

(leaf rainbow-delimiters
  :ensure t)

(leaf show-paren
  :ensure nil
  :custom
  ((show-paren-style . 'parenthesis) ; show matchin paren
   (show-paren-when-point-in-periphery . t) ; show when near paren
   (show-paren-delay . 0.4)
   (show-paren-when-point-inside-paren . t))) ; don’t show when inside paren

;; ** Whitespace

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

;; ** Indent

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

(use-package aggressive-indent
  :ensure t
  :custom
  (aggressive-indent-dont-electric-modes '(yaml-mode python-mode emacs-lisp-mode))
  (aggressive-indent-excluded-modes '(python-mode text-mode yaml-mode))
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
;; ** programming utilities

(leaf whitespace-cleanup-mode
  :ensure t
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

(leaf xref
  :ensure t
  :hook (xref-after-return-hook . recenter)
  :custom (xref-marker-ring . 30)) ; should be enough

;; * git
;; ** magit

;;; ** tree-sitter

;; TODO: get working
(leaf treesit :custom (treesit-font-lock-level . 4))

(setq-default treesit-font-lock-level 4)

(setq treesit-language-source-alist
      '
      ((awk "https://github.com/Beaglefoot/tree-sitter-awk")
       (bash "https://github.com/tree-sitter/tree-sitter-bash")
       (cmake "https://github.com/uyha/tree-sitter-cmake")
       (css "https://github.com/tree-sitter/tree-sitter-css")
       (elisp "https://github.com/Wilfred/tree-sitter-elisp")
       (go "https://github.com/tree-sitter/tree-sitter-go")
       (html "https://github.com/tree-sitter/tree-sitter-html")
       ;; hyprland
       (hyprlang "https://github.com/tree-sitter-grammars/tree-sitter-hyprlang")
       (javascript
        "https://github.com/tree-sitter/tree-sitter-javascript"
        "master"
        "src")
       (json "https://github.com/tree-sitter/tree-sitter-json")
       (jq "https://github.com/nverno/tree-sitter-jq" nil nil nil)
       (make "https://github.com/alemuller/tree-sitter-make")
       (markdown "https://github.com/ikatyang/tree-sitter-markdown")
       (python "https://github.com/tree-sitter/tree-sitter-python")
       (toml "https://github.com/tree-sitter/tree-sitter-toml")
       (tsx
        "https://github.com/tree-sitter/tree-sitter-typescript"
        "master"
        "tsx/src")
       (typescript
        "https://github.com/tree-sitter/tree-sitter-typescript"
        "master"
        "typescript/src")
       (yaml "https://github.com/ikatyang/tree-sitter-yaml")))

;; just handle everything else
(leaf
  treesit-auto
  :ensure t
  :require t
  :custom
  ((treesit-auto-install . t)
   (treesit-auto-langs . '(python bash yaml))
   (treesit-auto-add-to-auto-mode-alist . 'all))
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)) ;; all from treesit-auto-langs

;; * minibuffer
;; ** vertico, embark, consult

;; Enable Vertico.
(leaf vertico
  :ensure t
  :custom
  ((vertico-scroll-margin . 0) ;; Different scroll margin
  (vertico-count . 10) ;; Show more candidates
  (vertico-resize . 'grow-only) ;; Grow and shrink the Vertico minibuffer
  (vertico-cycle . t)) ;; Enable cycling for `vertico-next/previous'
  :config
  (vertico-mode))

(setq read-file-name-completion-ignore-case t
      read-buffer-completion-ignore-case t
      completion-ignore-case t)

;; Example configuration for Consult
(leaf consult
  :ensure t
  ;; Replace bindings. Lazily loaded by `use-package'.
  :bind (;; C-c bindings in `mode-specific-map'
         ("C-c M-x" . consult-mode-command)
         ("C-c k" . consult-kmacro)
         ("C-c m" . consult-man)
         ("C-c i" . consult-info)
         ([remap Info-search] . consult-info)
         ;; C-x bindings in `ctl-x-map'
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x t b" . consult-buffer-other-tab)    ;; orig. switch-to-buffer-other-tab
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings in `goto-map'
         ("M-g e" . consult-compile-error)
         ("M-g r" . consult-grep-match)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings in `search-map'
         ("M-s d" . consult-find)                  ;; Alternative: consult-fd
         ("M-s c" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         (:isearch-mode-map
         (("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi))            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         (:minibuffer-local-map
         (("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history)))))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setq register-preview-delay 0.1)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key "M-.")
  ;; (setq consult-preview-key '("S-<down>" "S-<up>"))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man :preview-key '(:debounce 0.05 any)
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

(leaf
  consult-todo
  :ensure t
  :bind (("M-s t" . consult-todo-all) ("M-s T" . consult-todo-project)))

;; Enable rich annotations using the Marginalia package

(use-package embark
  :ensure t

  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)
   ("C-c e" . embark-export)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  ;; Add Embark to the mouse context menu. Also enable `context-menu-mode'.
  ;; (context-menu-mode 1)
  ;; (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :ensure t ; only need to install it, embark loads it after consult if found
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

(use-package marginalia
  :ensure t
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :bind (:map minibuffer-local-map
              ("M-A" . marginalia-cycle))

  ;; The :init section is always executed.
  :init

  ;; Marginalia must be activated in the :init section of use-package such that
  ;; the mode gets enabled right away. Note that this forces loading the
  ;; package.
  (marginalia-mode))

;; Optionally use the `orderless' completion style.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion))))
  (completion-category-defaults nil) ;; Disable defaults, use our settings
  (completion-pcm-leading-wildcard t)) ;; Emacs 31: partial-completion behaves like substring
;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

;; Emacs minibuffer configurations.
(use-package emacs
  :custom
  ;; Enable context menu. `vertico-multiform-mode' adds a menu in the minibuffer
  ;; to switch display modes.
  (context-menu-mode t)
  ;; Support opening new minibuffers from inside existing minibuffers.
  (enable-recursive-minibuffers t)
  ;; Hide commands in M-x which do not work in the current mode.  Vertico
  ;; commands are hidden in normal buffers. This setting is useful beyond
  ;; Vertico.
  (read-extended-command-predicate #'command-completion-default-include-p)
  ;; Do not allow the cursor in the minibuffer prompt
  (minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)))

;; * dired

(leaf
  dired
  ;; TODO: lazy ?
  :hook
  ((dired-mode-hook . dired-hide-details-mode))
  ;;(dired-mode-hook . dired-async-mode))
  :bind
  (
   (:dired-mode-map
    :package
    window-extras
    (("C-M-o" . xc/switch-to-last-window)))
   (:dired-mode-map :package dired-extras (("RET" . xc/dired-find-file)))
   (:dired-mode-map :package daanturo-dired (("r" . daanturo-dired-do-rename)))
   (:dired-mode-map
    :package
    daanturo-dired
    (("_" . daanturo-dired-delete-no-trash)))
   (:dired-mode-map
    :package dired
    (("C-c w" . dired-copy-filename-as-kill)
     ("e" . wdired-change-to-wdired-mode)
     ("h" . diredp-dired-recent-dirs)
     ("C-c M-s" . dired-do-isearch)
     ("$" . eshell)
     ;; previous eww-open-file but it prompts
     ("w" . browse-url-of-dired-file)
     ("E" . redguardtoo-ediff-files)
     ("@" . dired-run-command)
     ("l" . nil)
     ("l" . dired-up-directory)
     (";" . dired-next-subdir)))) ;; dired-do-redisplay
  :custom
  (
   (dired-listing-switches
    .
    "-iafxhlvs --group-directories-first --time-style=long-iso")
   (dired-free-space-args . "-ph")
   ;; which files not to display
   (dired-omit-files . "^\\.\\|^#.*#$")
   ;; which directories to track
   (dirtrack-list . '("^[^:]*:\\(?:\e\\[[0-9]+m\\)?\\([^$#\e]+\\)" 1))
   (ls-lisp-ignore-case . t)
   (ls-lisp-dirs-first . t)
   (dired-dwim-target . t)
   ;; use system's trash can
   (delete-by-moving-to-trash . t)
   ;; don’t delete excess backup versions silently
   (delete-old-versions . t)
   ;; don't hide symbolic link targets
   (wdired-allow-to-change-permissions . nil)
   (wdired-create-parent-directories . t)
   (dired-auto-revert-buffer . #'dired-directory-changed-p)
   (dired-recursive-deletes . 'always)
   (delete-by-moving-to-trash . t)
   (dired-always-read-filesystem . t)
   (dired-vc-rename-file . t)
   (dired-copy-preserve-time . t)
   (dired-recursive-copies . t)
   (dired-clean-confirm-killing-deleted-buffers . nil)
   (dired-kill-when-opening-new-dired-buffer . t)
   (dired-hide-details-hide-symlink-targets . nil)
   (dired-omit-verbose . nil) ;; don't show messages when omitting files
   (dired-recursive-copies . 'always) ;; always copy recursively
   (dired-recursive-deletes . 'always) ;; always delete recursively
   (find-ls-option . '("-print0 | xargs -p4 -0 ls -ldn" . "-ldn"))
   (find-ls-subdir-switches . "-ldn")
   (find-ls-subdir-switches . "-ldn")
   ;; run command depending on os, depending on file-type
   (dired-guess-shell-alist-user
    .
    `
    (
     (
      ,
      (rx
       "."
       (or
        ;; videos
        "mp4"
        "avi"
        "mkv"
        "flv"
        "ogv"
        "ogg"
        "mov"
        ;; music
        "wav"
        "mp3"
        "flac"
        ;; images
        "jpg"
        "jpeg"
        "png"
        "gif"
        "xpm"
        "svg"
        "bmp"
        ;; docs
        "pdf"
        "md"
        "djvu"
        "ps"
        "eps"
        "doc"
        "docx"
        "xls"
        "xlsx"
        "ppt"
        "pptx")
       string-end)
      ,
      (pcase system-type
        ('gnu/linux "xdg-open")
        ('darwin "open")
        ('windows-nt "start")
        (_ "")))))))


(leaf dired-collapse
  :ensure t
  :global-minor-mode global-dired-collapse-mode)

(leaf dired-rainbow
  :ensure t)

(leaf dired-subtree
  :ensure t
  :bind (:dired-mode-map
         (("TAB" . dired-subtree-cycle))))


;; * window

(leaf zoom
  :ensure t
  :global-minor-mode
  :custom ((zoom-ignored-buffer-names . '(" *which-key*"))))

(leaf auto-dim-other-buffers
  :ensure t
  :global-minor-mode auto-dim-other-buffers-mode
  :custom (auto-dim-other-buffers-dim-on-switch-to-minibuffer . nil))

(leaf
  window
  :ensure nil
  :custom (window-resize-pixelwise . t)
  :bind (("C-M-(" . scroll-other-window-down) ("C-M-)" . scroll-other-window)))

(leaf winum
  :ensure t
  :require t
  :bind
  (("C-w" . nil) ;; kill-region
   ("C-w 1" . winum-select-window-1)
   ("C-w 2" . winum-select-window-2)
   ("C-w 3" . winum-select-window-3)
   ("C-w 4" . winum-select-window-4)
   ("C-w 5" . winum-select-window-5)
   ("C-w 6" . winum-select-window-6)
   ("C-w 7" . winum-select-window-7)
   ("C-w 8" . winum-select-window-8)
   ("C-w 9" . winum-select-window-9))
  :config (winum-mode)
  :custom
  ((winum-scope . 'frame-local)
   (winum-reverse-frame-list . nil)
   (winum-auto-assign-0-to-minibuffer . nil)
   (winum-auto-setup-mode-line . t)))

(leaf
  winner
  :bind ("C-c M-o" . winner-undo)
  :custom ((winner-ring-size . 999) (winner-dont-bind-my-keys . t)))

(leaf
  ace-window
  :ensure t
  :bind (("M-o s" . ace-swap-window) ("M-j" . ace-window))
  :custom
  ((aw-keys quote (106 105 112)) ;; j i p
   (aw-background . nil)
   (aw-scope . 'frame)
   (aw-char-position . 'top-left)
   (aw-ignore-current . t)
   (aw-leading-char-style . 'path)
   (aw-display-mode-overlay . nil)
   (aw-dispatch-alist
    .
    '
    ((?x aw-delete-window "Delete Window")
     (?m aw-swap-window "Swap Windows")
     (?M aw-move-window "Move Window")
     (?c aw-copy-window "Copy Window")
     (?j aw-switch-buffer-in-window "Select Buffer")
     (?n aw-flip-window)
     (?u aw-switch-buffer-other-window "Switch Buffer Other Window")
     (?c aw-split-window-fair "Split Fair Window")
     (?v aw-split-window-vert "Split Vert Window")
     (?b aw-split-window-horz "Split Horz Window")
     (?o delete-other-windows "Delete Other Windows")
     (??
      aw-show-dispatch-help
      "List of actions for `aw-dispatch-default'.")))
   (aw-ignored-buffers . '("wtf2"))
   (aw-ignore-on . t)))

(leaf zoom
  :ensure t
  :global-minor-mode zoom-mode)

(setq dired-sidebar-subtree-line-prefix "__")
(setq dired-sidebar-theme 'nerd-icons)
(setq dired-sidebar-use-term-integration t)
(setq dired-sidebar-use-custom-font t)

;; * look

(leaf minions
  :ensure t
  :global-minor-mode minions-mode)

(leaf kaolin-themes
  :ensure t
  :require t
  :init
  (defun my-mode-line-font-small ()
    (interactive)
    (set-face-attribute 'mode-line nil :height 85)
    (set-face-attribute 'mode-line-inactive nil :height 85))

  ;;COMMIT: remove my-toggle
  ;;(my-mode-line-font-small)
  :config
  (load-theme 'kaolin-mono-dark t nil)
  :custom ((kaolin-themes-hl-line-colored . nil)
           (kaolin-themes-bold . nil)
           (kaolin-themes-italic . nil)))

(blink-cursor-mode 0)

(setq-default x-stretch-cursor nil
              cursor-in-non-selected-windows nil)

;; * Filling and fringes

(leaf modern-fringes
  :ensure t
  :global-minor-mode modern-fringes-mode)

(setq-default fringe-mode '(0 .0))

(set-face-attribute 'fringe nil :inherit 'org-level-4)

(leaf virtual-auto-fill
  :ensure t
  :hook ((org-mode-hook Info-mode-hook . virtual-auto-fill-mode))
  :custom (virtual-auto-fill-fill-paragraph-require-confirmation . nil))

;; DEBUG
(leaf visual-fill-column
  :ensure t
  :hook (((visual-fill-line-mode-hook
           eww-after-render-hook
           ansible-doc-module-mode
           Info-mode-hook
           devdocs-mode-hook
           helpful-mode-hook
           help-mode-hook
           rfc-mode-hook
           erc-mode-hook
           telega-chat-mode-hook
           elp-results-mode
           nov-mode-hook) . visual-fill-column-mode))

  :custom ((visual-fill-column-fringes-outside-margins . t)
           (visual-fill-column-enable-sensible-window-split . t)
           (visual-fill-column-width . 80)
           (visual-fill-column-center-text . t)
           (visual-fill-column-extra-text-width . '(1 . 1))
           (visual-fill-column--use-split-window-parameter . t))
  :config
  (advice-add 'text-scale-adjust :after #'visual-fill-column-adjust))

(leaf default-text-scale
  :ensure t
  :bind
  (("C-x C--" . nil) ;; text-scale-adjust
   ("C-x C--" . default-text-scale-decrease)
   ("C-x C-=" . nil) ;; text-scale-adjust
   ("C-x C-=" . default-text-scale-increase) ("C-x C-M--" . viewing-2))
  :custom ((default-text-scale-amount . 5) (text-scale-mode-step . 1.1)))


;; * config/completion for python using company and eglot

(leaf pyvenv
  :ensure t
  :init
  (setenv "WORKON_HOME" "~/.venvs/")
  :config
  ;; (pyvenv-mode t)

  ;; Set correct Python interpreter
  (setq pyvenv-post-activate-hooks
        (list (lambda ()
                (setq python-shell-interpreter (concat pyvenv-virtual-env "bin/python")))))
  (setq pyvenv-post-deactivate-hooks
        (list (lambda ()
                (setq python-shell-interpreter "python3")))))

;; (leaf go-mode
;;   :ensure t
;;   :hook ((go-mode-hook . go-ts-mode)
;;          (go-ts-mode-hook . eglot)
;;          (go-ts-mode-hook . company-mode)))

(leaf python-mode
  :hook
  ((python-mode . pyvenv-mode)
   (python-mode . flycheck-mode)
   (python-mode . company-mode)
   (python-mode . blacken-mode)
   (python-mode . yas-minor-mode)
   (python-mode . eglot)
   (python-mode . python-ts-mode)
   (python-mode . company-mode)
   (python-mode . indent-bars-mode))
  :custom
  ;; NOTE: Set these if Python 3 is called "python3" on your system!
  (python-shell-interpreter "python3")
  :config
  )

;; A few more useful configurations...
;; (use-package emacs
;;   :custom
;;   ;; TAB cycle if there are only few candidates
;;   ;; (completion-cycle-threshold 3)

;;   ;; Enable indentation+completion using the TAB key.
;;   ;; `completion-at-point' is often bound to M-TAB.
;;   (tab-always-indent 'complete)

;;   ;; Emacs 30 and newer: Disable Ispell completion function.
;;   ;; Try `cape-dict' as an alternative.
;;   (text-mode-ispell-word-completion nil)

;;   ;; Hide commands in M-x which do not apply to the current mode.  Corfu
;;   ;; commands are hidden, since they are not used via M-x. This setting is
;;   ;; useful beyond Corfu.
;;   (read-extended-command-predicate #'command-completion-default-include-p))

(leaf company
  :ensure t
  :bind (:company-active-map
         ("<tab>" . nil)
         ("TAB" . nil)
         ("M-<tab>" . company-complete-common-or-cycle)
         ("M-<tab>" . company-complete-selection))
  :custom
  ((company-minimum-prefix-length . 2)
   (company-idle-delay . 0.2)))

(leaf company-quickhelp
  :ensure t
  :hook (company-mode . company-quickhelp-mode))

;; * completion and config for yaml using yaml-pro and lang serv

(defun sd/yaml-mode-hook ()
  (indent-bars-mode)
  (add-hook 'after-save-hook #'whitespace-cleanup))

;; TODO: test with ts -mode
(leaf yaml
  :hook (yaml-mode-hook . sd/yaml-mode-hook))

;; (leaf yaml-pro
;;   :ensure t
;;   :hook ((yaml-ts-mode-hook)
;;          . yaml-pro-ts-mode)
;;   :bind (:yaml-pro-mode-map
;;          (("C-M-f" . yaml-pro-next-subtree)
;;           ("C-M-b" . yaml-pro-prev-subtree)
;;           ("C-M-d" . yaml-pro-down-level)
;;           ("C-M-u" . yaml-pro-up-level)
;;           ("C-c w" . yaml-pro-mark-subtree)
;;           ("C-c C-M-f" . yaml-pro-move-subtree-down)
;;           ("C-c C-M-b" . yaml-pro-move-subtree-up))))


(leaf flycheck-yamllint
  :ensure t)

(leaf yaml-imenu
  :ensure t
  :bind (:yaml-ts-mode-map
         ("M-g i" . yaml-imenu)))

;; * ansible helpers

(leaf ansible
  :ensure t)

(leaf flymake-ansible-lint
  :ensure t
  :commands flymake-ansible-lint-setup
  :hook (((yaml-ts-mode yaml-mode) . flymake-ansible-lint-setup)
         ((yaml-ts-mode yaml-mode) . flymake-mode)))

(add-hook 'yaml-ts-mode #'outshine-mode)

(leaf ansible-doc
:ensure t)

;; * multiple cursors

(leaf multiple-cursors
  :ensure t
  :bind (("C-x f m c l" . mc/edit-lines)
         ;; next
         ("C-x f m c r" . mc/mark-all-like-this-dwim)
         ("C-x f m c n" . mc/mark-next-word-like-this)
         ("C-x f m c C-n" . mc/mark-next-like-this-symbol)
         ("C-x f m c C-p" . mc/mark-previous-like-this-symbol)
         ;; previous
         ("C-x f m c p" . mc/mark-previous-word-like-this)
         ("C-x f m c C-p" . mc/mark-previous-like-this-word)
         ("C-x f m c s-p" . mc/mark-previous-like-this-symbol)
         ;; all
         ("C-x f m c a a" . mc/mark-all-like-this)
         ("C-x f m c a w" . mc/mark-all-words-like-this)
         ("C-x f m c a s" . mc/mark-all-symbols-like-this)
         ("C-x f m c c" . mc/mark-all-words-like-this))
  :custom (mc/max-cursors . 6000)
  :config
  (add-to-list 'mc/unsupported-minor-modes 'corfu-mode))

;; * magit

(leaf magit
  :ensure t
  :bind ("C-x M-g" . magit-dispatch))

;; * terraform

(leaf terraform-mode
  :ensure t
  :custom ((terraform-indent-level . 2))
  :config
  (defun sd/terraform-mode-init ()
    (outline-minor-mode 1)
    (terraform-format-on-save-mode))
  :hook (terraform-mode-hook . sd/terraform-mode-init))

(leaf popup-imenu
  :ensure t
  :bind ("M-g i" . popup-imenu))

(leaf yafolding
  :ensure t
  :hook (hcl-mode . yafolding-mode)
  :bind (:yafolding-mode-map
         ("C-<tab>" . yafolding-toggle-element)))

(add-hook 'hcl-mode-hook #'flycheck-mode)

(leaf consult-flycheck
  :ensure t
  :bind ("M-g f" . consult-flycheck))

(leaf imenu
  :custom (imenu-auto-rescan . t))

;; * json

(leaf json-mode
  :bind (:json-ts-mode-map
         (("C-c ." . json-ts-jq-path-at-point)))
  :hook ((json-mode-hook
          js-json-mode-hook) . json-ts-mode))
(put 'narrow-to-region 'disabled nil)

(leaf jenkinsfile-mode
  :ensure t)

(leaf dockerfile-mode
  :ensure t)

(leaf anzu
  :ensure t
  :global-minor-mode global-anzu-mode)
