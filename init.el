;;; -*- lexical-binding: t -*-

(setopt x-select-enable-primary t)

;; * sort keys

(global-set-key (kbd "C-w") #'kill-region)

;; * set scroll

(setopt
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

;; * Package setup

(defun sd/package--missing-autoloads-p ()
  "Return non-nil if any package directory lacks its `*-autoloads.el` file."
  (when (and (boundp 'package-user-dir)
             (stringp package-user-dir)
             (file-directory-p package-user-dir))
    (catch 'missing
      (dolist (dir (directory-files package-user-dir t "^[^.]" t))
        (when (file-directory-p dir)
          (let* ((base (file-name-nondirectory (directory-file-name dir)))
                 (name (if (string-match "\\`\\(.+\\)-[0-9]" base)
                           (match-string 1 base)
                         base))
                 (autoloads (expand-file-name (format "%s-autoloads.el" name) dir))
                 (main (expand-file-name (format "%s.el" name) dir)))
            (when (and (file-exists-p main)
                       (not (file-exists-p autoloads)))
              (throw 'missing t)))))
      nil)))

(defun sd/package-ensure-autoloads ()
  "Generate missing `*-autoloads.el` files under `package-user-dir`.

This is a *repair* function. We avoid doing any work unless missing autoloads
are detected, because it can require `package`/`compile` and slow down startup.")
(interactive)
(when (sd/package--missing-autoloads-p)
  (require 'package)
  (dolist (dir (directory-files package-user-dir t "^[^.]" t))
    (when (file-directory-p dir)
      (let* ((base (file-name-nondirectory (directory-file-name dir)))
             (name (if (string-match "\\`\\(.+\\)-[0-9]" base)
                       (match-string 1 base)
                     base))
             (autoloads (expand-file-name (format "%s-autoloads.el" name) dir))
             (main (expand-file-name (format "%s.el" name) dir)))
        (when (and (file-exists-p main)
                   (not (file-exists-p autoloads)))
          (ignore-errors
            (package-generate-autoloads name dir)))))))

(eval-and-compile
  (customize-set-variable
   'package-archives
   '
   (("org" . "https://orgmode.org/elpa/")
    ("melpa" . "https://melpa.org/packages/")
    ("gnu" . "https://elpa.gnu.org/packages/")
    ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

  ;; (package-initialize)

  (customize-set-variable
   'package-user-dir
   (directory-file-name (concat user-emacs-directory "packages/elpa")))

  ;; Avoid "Error loading autoloads" warnings for packages missing
  ;; `*-autoloads.el` files. This is normally a no-op.
  (when (sd/package--missing-autoloads-p)
    (sd/package-ensure-autoloads))

  (package-activate-all)
  (customize-set-variable
   'package-archive-priorities
   '(("melpa-stable" . 10) ("melpa" . 20) ("gnu" . 30) ("nongnu" . 40)))
  (customize-set-variable 'package-menu-hide-low-priority nil))
(defun sd/package-refresh-contents (&optional async)
  "Refresh package archive contents.

This is intentionally *not* run on every startup, because it can be slow and
performs network I/O.

With prefix argument ASYNC, refresh asynchronously."
  (interactive "P")
  (if async
      (package-refresh-contents :async)
    (package-refresh-contents)))

;; `use-package` is built-in in Emacs 29+, but require it explicitly.
(require 'use-package)

;; hard dependency, place first

;; magit-remote.el:29:11: Error: transient--init-suffix-key is already defined as something else than a generic function

(use-package magit
  :ensure t
  :preface
  ;; Signed-off if emacs.signOff true
  ;; https://emacs.stackexchange.com/questions/85157/automatically-adding-signed-off-by-trailers-to-git-commits
  (defun maybe-git-commit-signoff ()
    "Potentially add a Signed-off-by trailer.

Run \"git config set --local emacs.signOff true\" in a repository if you are
sure it will always be appropriate to sign-off commits to it by default."
    (when (magit-git-config-p "emacs.signOff")
      (apply 'git-commit-signoff (git-commit-get-ident "Signed-off-by"))))

  (defun maybe-git-commit-co-authored-by ()
    "Potentially add a Co-authored-by trailer.

Run \"git config set --local emacs.coAuthoredBy true\" in a repository if you are
sure it will always be appropriate to sign-off commits to it by default."
    (when (magit-git-config-p "emacs.coAuthoredBy")
      (apply 'git-commit-co-authored (git-commit-get-ident "Co-authored-by"))))

  (defun maybe-git-commit-reviewed-by ()
    "Potentially add a Reviewed-by trailer.

Run \"git config set --local emacs.reviewedBy true\" in a repository if you are
sure it will always be appropriate to sign-off commits to it by default."
    (when (magit-git-config-p "emacs.reviewedBy")
      (apply 'git-commit-review (git-commit-get-ident "Reviewed-by"))))

  :bind ("C-x M-g" . magit-dispatch)
  :config (add-hook 'git-commit-setup-hook 'maybe-git-commit-signoff)
  (add-hook 'git-commit-setup-hook 'maybe-git-commit-co-authored-by)
  (add-hook 'git-commit-setup-hook 'maybe-git-commit-reviewed-by))

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

;; * shell

(setopt confirm-kill-processes nil)
(setopt kill-buffer-query-functions nil)
(setopt shell-command-switch "-c")

(setopt async-shell-command-display-buffer nil)

;; redirection supported, region supported
(use-package shell-command+
  :ensure t
  :bind ("M-!" . shell-command+)
  :custom (shell-command+-prompt "$+: "))

;; * mail

(setopt
 mm-encrypt-option nil
 mm-sign-opton nil
 mml-secure-openpgp-encrypt-to-self t
 mml-secure-openpgp-sign-with-sender t
 mml-secure-smime-encrypt-to-self t
 mml-secure-smime-sign-with-sender t
 ;; composition
 mail-user-agent 'message-user-agent
 compose-mail-user-agent-warnings nil
 message-ignored-cited-headers ""
 message-confirm-send t
 message-kill-buffer-on-exit t
 message-forward-as-mime t
 message-wide-reply-confirm-recipients t
 ;; sendmail / smtpmail
 send-mail-function #'smtpmail-send-it
 smtpmail-smtp-server "smtp.gmail.com"
 smtpmail-smtp-service 465
 smtpmail-stream-type 'ssl)

(use-package notmuch
  :ensure t
  :preface
  (defun sd/notmuch-mark-all-read-and-quit ()
    "Mark all messages in the current Notmuch search/tree buffer as read,
then quit."
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (push-mark (point-max) t t)
      (notmuch-search-tag (list "-unread")))
    (notmuch-bury-or-kill-this-buffer))
  (defun sd/notmuch-unread-view ()
    "Open a Notmuch tree view of unread messages."
    (interactive)
    (notmuch-search "tag:unread"))
  (defun sd/notmuch-message-fill-column ()
    "Set `message-fill-column' to 80 in notmuch message mode."
    (setq-local message-fill-column 80)
    (setq-local fill-column 80))
  (defun sd/notmuch-search-add-important-tag ()
    (interactive)
    (notmuch-search-add-tag '("+important")))
  (defun sd/notmuch-search-add-important-tag ()
    (interactive)
    (notmuch-search-add-tag '("+important")))
  (defun sd/notmuch-search-add-deleted-tag ()
    (interactive)
    (notmuch-search-add-tag '("+deleted")))
  (defun sd/notmuch-search-remove-unread-tag ()
    (interactive)
    (notmuch-search-remove-tag '("-unread")))
  (defun sd/notmuch-tree-add-important-tag ()
    (interactive)
    (notmuch-tree-add-tag '("+important")))
  (defun sd/notmuch-tree-add-important-tag ()
    (interactive)
    (notmuch-tree-add-tag '("+important")))
  (defun sd/notmuch-tree-add-deleted-tag ()
    (interactive)
    (notmuch-tree-add-tag '("+deleted")))
  (defun sd/notmuch-tree-remove-unread-tag ()
    (interactive)
    (notmuch-tree-remove-tag '("-unread")))
  (defun sd/notmuch-tree-get-message-id-to-clipboard ()
    (interactive)
    (kill-new (string-replace "id:" "" (notmuch-tree-get-message-id))))
  (defun sd/notmuch-show-get-message-id-to-clipboard ()
    (interactive)
    (kill-new (string-replace "id:" "" (notmuch-show-get-message-id))))
  :hook (notmuch-message-mode-hook . sd/notmuch-message-fill-column)
  :bind (("C-x `" . sd/notmuch-unread-view)
         ("C-x m" . notmuch)
         :map notmuch-search-mode-map
         ("`" . sd/notmuch-mark-all-read-and-quit)
         ("i" . sd/notmuch-search-add-important-tag)
         ("r" . sd/notmuch-search-remove-unread-tag)
         ("d" . sd/notmuch-search-add-deleted-tag)
         :map notmuch-tree-mode-map
         ("`" . sd/notmuch-mark-all-read-and-quit)
         ("i" . sd/notmuch-tree-add-important-tag)
         ("I" . sd/notmuch-tree-get-message-id-to-clipboard)
         ("r" . sd/notmuch-tree-remove-unread-tag)
         ("d" . sd/notmuch-tree-add-deleted-tag)
         :map notmuch-show-mode-map
         ("I" . sd/notmuch-show-get-message-id-to-clipboard))
  :custom ((notmuch-show-logo nil)
           (notmuch-column-control 1.0)
           (notmuch-hello-auto-refresh t)
           (notmuch-hello-recent-searches-max 20)
           (notmuch-hello-thousands-separator "")
           (notmuch-hello-sections '(notmuch-hello-insert-saved-searches))
           (notmuch-show-all-tags-list t)
           ;; search
           (notmuch-search-oldest-first nil) ;; newest email
           (notmuch-saved-searches
            '((:name "📥 deleted"
                     :query "tag:deleted"
                     :sort-order newest-first
                     :key "d")
              (:name "📥 inbox"
                     :query "tag:inbox -tag:deleted"
                     :sort-order newest-first
                     :key "a")
              (:name "📥 important"
                     :query "tag:important"
                     :sort-order newest-first
                     :key "i")
              (:name "📥 sent"
                     :query "tag:sent"
                     :sort-order newest-first
                     :key "s")
              (:name "💬 all unread (inbox)"
                     :query "tag:unread and tag:inbox"
                     :sort-order newest-first
                     :key "u")))
           (notmuch-search-result-format
            '(("date" . "%12s  ")
              ("count" . "%-7s  ")
              ("authors" . "%-20s  ")
              ("subject" . "%-80s  ")
              ("tags" . "(%s)")))
           (notmuch-tree-result-format
            '(("date" . "%12s  ")
              ("authors" . "%-20s  ")
              ((("tree" . "%s")
                ("subject" . "%s"))
               . " %-80s  ")
              ("tags" . "(%s)")))
           (notmuch-tree-thread-symbols
            '((prefix . "╾")
              (top . "─")
              (top-tee . "┬")
              (vertical . "│")
              (vertical-tee . "├")
              (bottom . "╰")
              (arrow . "╴"))
            )
           (notmuch-search-line-faces
            '(("unread" . notmuch-search-unread-face)
              ("flag" . italic)))
           ;; tags
           (notmuch-archive-tags nil)
           (notmuch-message-replied-tags '("+replied"))
           (notmuch-message-forwarded-tags '("+forwarded"))
           (notmuch-show-mark-read-tags '("-unread"))
           (notmuch-draft-tags '("+draft"))
           (notmuch-draft-folder "drafts")
           (notmuch-draft-save-plaintext 'ask)
           (notmuch-tag-formats
            '(("unread" (propertize tag 'face 'notmuch-tag-unread))
              ("flag" (propertize tag 'face 'notmuch-tag-flagged))))
           (notmuch-tag-deleted-formats
            '(("unread" (notmuch-apply-face bare-tag 'notmuch-tag-deleted))
              (".*" (notmuch-apply-face tag 'notmuch-tag-deleted))))
           (notmuch-tag-added-formats
            '(("del" (notmuch-apply-face tag 'notmuch-tag-added))
              (".*" (notmuch-apply-face tag 'notmuch-tag-added))))
           ;; composition
           (notmuch-mua-compose-in 'current-window)
           (notmuch-mua-hidden-headers nil)
           (notmuch-address-command 'internal)
           (notmuch-address-use-company nil)
           (notmuch-always-prompt-for-sender t)
           (notmuch-mua-cite-function 'message-cite-original-without-signature)
           (notmuch-mua-reply-insert-header-p-function 'notmuch-show-reply-insert-header-p-never)
           (notmuch-mua-user-agent-function nil)
           (notmuch-maildir-use-notmuch-insert t)
           (notmuch-crypto-process-mime t)
           (notmuch-crypto-get-keys-asynchronously t)
           (notmuch-mua-attachment-regexp
            '(concat "\\b\\(attache\?ment\\|attached\\|attach\\|"
                     "pi[èe]ce\s+jointe?\\|"))
           ;; reading messages
           (notmuch-show-relative-dates t)
           (notmuch-show-all-multipart/alternative-parts nil)
           (notmuch-show-indent-messages-width 2)
           (notmuch-show-indent-multipart nil)
           (notmuch-show-part-button-default-action 'notmuch-show-view-part)
           (notmuch-show-text/html-blocked-images ".") ; block everything
           (notmuch-wash-wrap-lines-length 120)
           (notmuch-unthreaded-show-out nil)
           (notmuch-message-headers '("From" "To" "Cc" "Subject" "Date"))
           (notmuch-message-headers-visible t)
           ;; to ensure patches are not broken
           (message-fill-column 999)))

(use-package notmuch-bookmarks
  :ensure t
  :config
  (notmuch-bookmarks-mode))

;; * histories and save place

;; (use-package savehist
;;   :init (savehist-mode)
;;   :custom
;;   ((history-length 100) ;; t is way too large
;;    (savehist-save-minibuffer-history t)
;;    ;; what other variables to save?
;;    (savehist-additional-variables '
;;     (search-ring
;;      regexp-search-ring
;;      ;; kill-ring ;; don’t save
;;      comint-input-ring
;;      sr-history-registry
;;      file-name-history
;;      org-mark-ring
;;      dogears-list
;;      tablist-name-filter
;;      winner-ring-alist
;;      mark-ring
;;      eshell-history-ring
;;      kmacro-ring))))

;; Save point history. Abbreviate file-names for confidentiality and make
;; backups of the master save-place file.
(use-package saveplace
  :ensure nil
  :custom
  ((save-place-abbreviate-file-names t)
   (save-place-limit nil)
   (save-place-version-control t)))

;; * Disable the mouse.
(setopt x-mouse-click-focus-ignore-position t)

;; * clipboard
;; Expectable behaviour of clipboard. Cut and paste uses the clipboard
;; and primary selection. When killing text outside Emacs, append it
;; to the clipboard as well.

(setopt
 select-enable-clipboard t
 select-enable-primary t
 save-interprogram-paste-before-kill t)

;; * pinentry

(use-package pinentry :if (display-graphic-p) :ensure t
  :config (pinentry-start))

;; Save host information in =.emacs/data/nsm-settings.el=.
(setopt nsm-save-host-names t)

;; * ai

;; TODO: customize, various models, etc
(use-package gptel
  :ensure t
  :hook
  ((gptel-post-response-functions . gptel-end-of-response)
   (gptel-post-stream-hook . gptel-auto-scroll)
   (gptel-mode-hook . visual-line-mode))
  :bind ("C-x C-g" . gptel-menu)
  :custom
  (
   (gptel-model . 'llama3:8b-instruct-q8_0)
   (gptel-track-media t)
   (gptel-include-reasoning nil)
   (gptel-use-header-line nil)
   (gptel-default-mode #'org-mode)
   (gptel-org-branching-context t))
  :config
  (gptel-make-ollama "Ollama"             ;Any name of your choosing
    :host (concat (getenv "OLLAMA_IP") ":11434")               ;Where it's running
    :stream t                             ;Stream responses
    :models '(qwen2.5:3b
              qwen2.5-coder:3b
              qwen2.5-coder:7b
              qwen2.5-coder:3b-instruct-q8_0
              zephyr:7b-beta-q6_K
              mistral:7b-instruct-v0.2-q6_K
              llama3:8b-instruct-q8_0))
  (setopt gptel-api-key (auth-source-pass-get 'secret "openai")))

;; TODO
(use-package agent-shell
  :ensure t
  :ensure t
  :custom (agent-shell-thought-process-expand-by-default t))

(use-package whisper
  :vc (:url "https://github.com/natrys/whisper.el" :branch "master"))

;; * the greps

(use-package grep
  :after (wgrep rg)
  :bind
  (
   (:map wgrep-mode-map ("C-c C-c" . save-buffer))))

(use-package deadgrep
  :ensure t
  :bind ("M-s x" . deadgrep))

;; * keys

;; Key helper
(use-package which-key
  ;; todo number-or-marker-p if which-key-mode
  :bind
  (("C-h C-k" . which-key-show-top-level)
   ("C-h M-k" . which-key-show-major-mode)
   ("C-h C-M-k" . which-key-show-full-keymap))
  :custom
  ((which-key-show-early-on-C-h t)
   (which-key-paging-key ">")
   (which-key-idle-delay 1.0)
   (which-key-max-description-length 30)
   (which-key-allow-imprecise-window-fit t) ; performance [redguardtoo]
   (which-key-separator ": ")
   (which-key-idle-secondary-delay 0.3)
   (which-key-min-display-lines 6)
   (which-key-min-column-description-width 80)
   (which-key-sort-order 'which-key-key-order)
   (which-key-sort-uppercase-first nil)
   (which-key-popup-type 'minibuffer)
   ;; TODO: function to show in same buffer
   (which-key-side-window-location 'top)))

;; * documents and documentation

;; Better help buffer
(use-package helpful
  :ensure t
  :bind
  (([remap describe-function] . helpful-callable)
   ([remap describe-variable] . helpful-variable)
   ([remap describe-key] . helpful-key)
   ([remap describe-symbol] . helpful-symbol)
   ("C-c C-d" . helpful-at-point)
   (:map helpful-mode-map ("q" . helpful-kill-buffers) ("g" . helpful-update)))
  :custom
  ((helpful-switch-buffer-function #'pop-to-buffer)
   (help-window-select t)
   (apropos-do-all t))) ;; more extensively)

(use-package elisp-demos
  :ensure t
  :after helpful
  :config (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update))

;; ** the mans and unix

(use-package man
  ;; TODO: lazy load
  :demand t
  :commands man consult-man smartscan-mode
  :custom
  ((Man-notify-method 'thrifty) ;; in pop-up frame
   (Man-width nil))
  :bind (:map Man-mode-map ("g" . nil) ("g" . consult-imenu)))

;; alternative
(use-package woman
  ;; TODO lazy load
  :demand t
  :custom
  ((woman-fill-frame t)
   (woman-fill-column 80)
   (woman-imenu t)
   (woman-cache-level 3))
  :bind (("C-h /" . woman)
         (:map woman-mode-map ("g" . consult-imenu))))

;; cli -h|--help
(use-package noman
  :ensure t
  :bind
  (("C-h n" . noman)
   (:map noman-mode-map ("n" . Man-next-section) ("p" . Man-previous-section)))
  :custom ((noman-reuse-buffers nil)))

;; ** pdfs

;;; pdf
(if (display-graphic-p)
    (use-package
      pdf-outline
      :hook (pdf-view-mode-hook . pdf-outline-imenu-enable)
      :bind (:map pdf-view-mode-map ("M-g o" . pdf-outline)))

  ;; TODO: tweak keybindings
  (use-package
    pdf-tools
    :ensure t
    :demand t
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

    :bind ((:map pdf-view-mode-map ("C-M-s" . pdf-occur) ("C-c l" . org-store-link)))
    ;; :bind (:map pdf-history-minor-mode-map TODO: fix otherwise gives undefined
    ;;        (("l" . pdf-history-backward)
    ;;         (";" . pdf-history-forward)))

    :hook
    ((pdf-view-after-change-page-hook . pdf-view-midnight-minor-mode)
     ;;(pdf-view-mode-hook . pdf-loader-install)
     ;;(pdf-view-mode-hook . pdf-view-midnight-minor-mode)
     (pdf-view-mode-hook . my-pdf-view-set-midnight-colors))
    ;; lol

    :custom
    ((pdf-info-epdfinfo-program "~/bin/epdfinfo")
     (pdf-tools-enabled-modes '
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
     (pdf-view-display-size 'fit-height)
     (pdf-view-continuous t)
     (pdf-view-use-dedicated-register nil)
     (pdf-view-max-image-width 1080)
     (pdf-outline-imenu-use-flat-menus t)
     (pdf-view-display-size 'fit-page)
     (pdf-view-use-scaling nil))
    :config
    (pdf-loader-install :no-query)
    (set-face-attribute 'pdf-links-read-link nil
                        :background (face-attribute 'mode-line :background))
    (set-face-attribute 'pdf-links-read-link nil
                        :foreground (face-attribute 'mode-line :foreground)))

  ;; Save place in PDF files.

  (use-package
    saveplace-pdf-view
    :ensure t
    :hook (pdf-view-mode-hook . save-place-mode)))

;; ** epub

(use-package
  nov
  :ensure t
  :preface
  (defun sd/nov-mode-hook ()
    (turn-on-visual-line-mode)
    (visual-line-fill-column-mode))
  :hook (nov-mode-hook . sd/nov-mode-hook)
  :bind
  (
   (:map nov-mode-map ("C-M-a" . backward-paragraph)
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
         ("M-g i" . consult-imenu))
   (:map nov-button-map ("M-n" . nov-next-document)
         ("M-n" . nov-next-document)
         ("M-p" . nov-previous-document)
         ("n" . shr-next-link)
         ("p" . shr-previous-link)))
  :custom (nov-text-width 80)
  :mode ("\\.epub\\'" . nov-mode)
  :config
  (setopt
   nov-unzip-program (executable-find "bsdtar")
   nov-unzip-args '("-xC" directory "-f" filename))
  (setopt
   nov-shr-rendering-functions
   (append nov-shr-rendering-functions shr-external-rendering-functions)
   nov-header-line-format ""))

;; * files

(use-package
  files-extras
  ;; TODO: lazy load
  ;; TODO: find-next|prev-file-same-mode C-x f C-n|p
  :preface
  (defun sd/dired-to-downloads (&optional arg)
    "Go to DOWNLOADS folder."
    (interactive "P")
    (dired "/ent/chrome-downloads"))
  :defer t
  :bind
  (("C-x C-M-f" . find-file-rec)
   ("C-x s-f" . open-all-files-in-directory)
   ("C-x f" . nil) ;; set-fill-column
   ("C-x f r" . redguardtoo-vc-rename-file-and-buffer)
   ("C-x f d" . +delete-current-file)
   ("C-x f l" . count-words)
   ("C-x f c" . redguardtoo-vc-copy-file-and-rename-buffer)
   ("C-x f g" . open-on-github)
   ("C-x f w" . jf/nab-file-name-to-clipboard)
   ("C-x f -" . xah-open-file-from-clipboard)
   ("C-x f u" . revert-buffer)
   ("C-x f n" . find-next-file)
   ("C-x f C-r" . recover-this-file)
   ("C-x f p" . find-previous-file)
   ("C-x f x" . kf-make-file-executable)
   ("C-x f /" . save-in-tmp-dir)
   ("C-x f @" . sd/tramp-remote-find-file-for-me))
  ;;daanturo-open-files-with-mode-in-dir maybe
  :config
  (advice-add 'find-file :around #'find-file--line-number)
  (add-to-list 'find-file-not-found-functions #'er-auto-create-missing-dirs))

;; * buffer

(global-set-key (kbd "C-c h") #'previous-buffer)
(global-set-key (kbd "C-c l") #'next-buffer)

;; Don't ask for confirmation when reverting a buffer
(setopt
 revert-without-query '(".*")
 whitespace-line-column 120
 require-final-newline t)

(setopt large-file-warning-threshold 500000000)

;; * utilities

(lossage-size 5000)

(use-package activities
  :ensure t
  :init (activities-mode 1)
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

(use-package
  crux
  :ensure t
  :bind
  ((:map prog-mode-map ("C-a" . crux-move-beginning-of-line) ("C-c C-j" . crux-top-join-line))
   (:map text-mode-map ("C-a" . crux-move-beginning-of-line)
         ("C-o" . crux-smart-open-line-above))))

(use-package
  hide-lines
  :ensure t
  :bind (("C-c h" . hide-lines) ("C-c C-h" . hide-lines-show-all)))

;; Some useful keybindings

(use-package
  recentf
  :ensure t
  :custom
  ((recentf-max-menu-items 200)
   (recentf-max-saved-items 6000)
   (recentf-auto-cleanup t))

  :config
  (setopt recentf-exclude
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

(use-package
  yasnippet
  :ensure t
  :preface
  :bind
  (("C-o" . yas-expand)))

(use-package yasnippet-snippets :ensure t)

(use-package
  consult-yasnippet
  :after consult
  :ensure t
  :bind ("C-c <TAB>" . consult-yasnippet))

(use-package
  yankpad
  :ensure t
  :custom (yankpad-file "~/org/yankpad.org")
  :bind (("C-c C-o" . yankpad-expand)
         ("C-c C-M-o" . yankpad-insert)))

;;;;; * pair

(use-package
  smart-hungry-delete
  :init (smart-hungry-delete-add-default-hooks)
  :ensure t
  :bind (("C-d" . smart-hungry-delete-forward-char))
  :hook ((text-mode-hook . smart-hungry-delete-default-text-mode-hook)))

(use-package
  replace
  :custom (list-matching-lines-jump-to-current-line t)
  :hook (occur-mode-hook . hl-line-mode)
  :bind (:map occur-mode-map ("t" . toggle-truncate-lines)))

;;;;; * regexp

(use-package
  visual-regexp-steroids
  :ensure t
  :bind
  (("M-%" . vr/replace)
   ("C-c M-%" . vr/mc-mark)
   ("C-M-s" . vr/isearch-forward)
   ("C-M-r" . vr/isearch-backward)))

;;;;; * region operations

;; Automatically append to kill-ring when selecting by mouse
(setopt mouse-drag-copy-region t)

;;;;; * search

(use-package isearch
  :custom
  ((search-highlight t)
   (search-whitespace-regexp ".*?")
   (isearch-lax-whitespace t)
   (isearch-regexp-lax-whitespace nil)
   ;; would be stuck in search otherwise
   (search-nonincremental-instead nil)
   (isearch-lazy-highlight t)
   (isearch-lazy-count t) ;; show match numbers in prompt
   (lazy-highlight-initial-delay 6)
   (lazy-highlight-interval 1)
   (lazy-highlight-no-delay-length 10)
   (lazy-count-prefix-format nil)
   (isearch-lazy-count-suffix-format " (%s/%s)")
   (isearch-yank-on-move 'shift) ;; motion keys yank txt to srch str
   (isearch-allow-scroll 'unlimited) ;; allow scrolling when isearchin
   (isearch-repeat-on-direction-change t)
   (isearch-wrap-pause t))
  :bind
  (
   (:map isearch-mode-map ("C-g" . isearch-cancel)
         ("C-d" . isearch-forward-symbol-at-point) ;; instead of isearch-abort
         ("M-/" . isearch-complete) ("C-o" . sd/isearch-deadgrep))
   (:map minibuffer-local-isearch-map ("M-/" . isearch-complete-edit) ("C-M-p" . isearch-delete-wrong))))

;;;;; * project

(use-package isearch-project
  :ensure t
  :bind
  (:map project-prefix-map
        :package
        project
        (("C-s" . isearch-project-forward-symbol-at-point))))

(use-package find-file-in-project
  :ensure t
  :custom (ffip-use-rust-fd t)
  :bind
  (:map project-prefix-map ("f" . find-file-in-project)
        ("d" . find-directory-in-project-by-selected)))

(use-package
  bookmark-in-project
  :ensure t
  :bind
  (("C-x p C-n" . bookmark-in-project-jump-next)
   ("C-x p C-p" . bookmark-in-project-jump-previous)
   ("C-x p m" . bookmark-in-project-toggle)
   ("C-x p RET" . bookmark-in-project-jump)))

;;;;; * editing

;;;;; * undo

;; TODO: good keymap
(use-package surround
  :ensure t
  :bind
  ("C-c M-w" . surround-mark))

(setopt set-mark-command-repeat-pop t)

(use-package phi-rectangle
  :ensure t
  :bind ("C-x SPC" . phi-rectangle-set-mark-command))

;; * movement

(use-package register :custom (register-use-preview 'never))

;; 2. bookmark for bookmark-wide - alt
;; TODO: replace with harpoon?
;; https://github.com/otavioschwanck/harpoon.el

(use-package bookmark
  :custom ((bookmark-fontify nil)
           ;; save bookmark file whenever bookmarks are modified
           (bookmark-save-flag 1)
           (bookmark-version-control t)
           (bookmark-automatically-show-annotations t)))

(use-package
  ring
  :custom
  ((global-mark-ring-max 15000)
   (mark-ring-max 1500)
   (kill-ring-max 1500)
   (kill-do-not-save-duplicates t)))

(use-package
  movement-extras
  :bind
  (
   (:map prog-mode-map ([remap next-line] . zk-phi-next-line)
         ([remap previous-line] . zk-phi-previous-line))
   (:map text-mode-map ([remap next-line] . zk-phi-next-line)
         ([remap previous-line] . zk-phi-previous-line))
   ;; 'python-mode-map' void error when loading this
   ;; do i have to?
   ;; (:map python-mode-map
   ;;  (([remap next-line] . zk-phi-next-line)
   ;;   ([remap previous-line] . zk-phi-previous-line)))
   ;; only forward, backward is default.
   ("M-f" . koek-mtn/next-word)))

;; =M-del=: delete subword.
;; =C-m-<backspace>=: delete superword.

(use-package subword-extras :bind (("C-M-<backspace>" . backward-kill-superword)))

;; * goto family
(use-package
  goto-chg
  :ensure t
  :bind (("M-g l" . goto-last-change) ("M-g C-l" . goto-last-change-reverse)))

(use-package goto-address
  :ensure nil
  :hook (after-init . global-goto-address-mode))

(use-package
  goto-char-preview
  :ensure t
  :bind (("M-g c" . nil) ("M-g c" . goto-char-preview)))

(use-package
  goto-line-preview
  :ensure t
  :bind (("M-g g" . nil) ("M-g g" . goto-line-preview)))

;; ** jumping

(use-package
  smartscan
  :ensure t
  :bind
  (:map prog-mode-map
        (("M-n" . smartscan-symbol-go-forward)
         ("M-p" . smartscan-symbol-go-backward)))
  (:map special-mode-map ("M-n" . smartscan-symbol-go-forward)
        ("M-p" . smartscan-symbol-go-backward))
  (:map Man-mode-map ("M-n" . smartscan-symbol-go-forward)
        ("M-p" . smartscan-symbol-go-backward))

  :custom ((smartscan-symbol-selector "symbol")
           (smartscan-use-extended-syntax t)))

(use-package smart-mark :ensure t)

(use-package beginend :ensure t)

;; * org
;; ** org main

(use-package
  org
  :ensure nil ;; already covered from org-plus-contrib install
  :preface

  (defun sd/org-paste-as-child-subtree (&optional arg)
    "Paste kill as child subtree of tree at point."
    (interactive "P")
    (org-paste-subtree (+ (org-outline-level) 1)))

  (defun sd/org-mode-hook (&optional arg)
    (interactive "P")
    (auto-fill-mode)
    (setq-local fill-column 80)
    (if (display-graphic-p)
        (org-variable-pitch-minor-mode))
    (display-fill-column-indicator-mode)
    (turn-on-visual-line-mode))

  :hook
  (org-mode-hook . sd/org-mode-hook)
  :bind
  ((:map org-mode-map
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
   ("C-c M-a" . org-mark-ring-push)
   ("C-c M-g" . org-mark-ring-goto)
   (:map org-src-mode-map ("C-c C-c" . org-edit-src-exit)))

  :custom
  ((org-ellipsis " ") ;; nothing
   ;; (org-src--allow-write-back nil)
   ;; add id always
   (org-id-link-to-org-use-id nil)
   ;; hide leading stars
   (org-hide-leading-stars t)
   (org-pretty-entities t)
   ;; refile
   (org-refile-targets '((nil (:maxlevel 15))))
   ;; ;; A\B\NewC -> NewC appended to B
   (org-refile-allow-creating-parent-nodes t)
   (org-refile-use-cache nil)
   (org-refile-use-outline-path 'file)
   (org-outline-path-complete-in-steps nil)
   ;; ;; linking
   (org-return-follows-link t)
   (org-tab-follows-link t)
   ;; (org-link-keep-stored-after-insertion nil)
   (org-link-file-path-type 'absolute)

   ;; folding
   (org-startup-folded nil)
   ;; show point when editing invisible region
   (org-catch-invisible-edits 'show)
   (org-M-RET-may-split-line nil)
   ;; ;; when motioning in lists, cycle/circular
   (org-list-use-circular-motion t)
   ;; show headline, ancestors and entries+children in all org views
   (org-show-context-detail t)
   (org-startup-indented nil)
   (org-adapt-indentation nil)
   ;; properties are inherited
   (org-use-property-inheritance t)
   ;; org-use-property-inheritance ("property" "property" ...)
   ;; properties to inherit
   ;; dont display date prompt interpretation
   (org-read-date-display-live nil)
   ;; org clock+occur highlights not removed if
   ;; editing, c-c c-c to remove highlights
   (org-remove-highlights-with-change nil)
   ;; get image width from #+attr keyword in org file,
   ;; otherwise default
   (org-image-actual-width 100)
   ;; depth of org headers parsing for imenu
   (org-element-use-cache nil)
   (org-element-cache-persistent nil)
   (org-imenu-depth 9)
   (org-src-fontify-natively nil)
   (org-fontify-quote-and-verse-blocks t)
   (org-fontify-whole-heading-line t)
   ;; ;; don't ask for confirmation when evaluating with babel
   (org-confirm-babel-evaluate nil)
   (org-link-elisp-confirm-function nil)
   (org-edit-src-auto-save-idle-delay 2)
   (org-edit-src-persistent-message nil)
   (org-edit-src-turn-on-auto-save t)
   (org-hide-block-startup nil)
   (org-cycle-hide-block-startup nil)
   (org-src-ask-before-returning-to-edit-buffer nil)
   (org-src-strip-leading-and-trailing-blank-lines t)
   ;; show dedicated buffer in current window
   (org-src-window-setup 'current-window)
   ;; don’t preserve leading whitespace characters
   (org-src-preserve-indentation nil)
   (org-edit-src-content-indentation 0)
   (org-src-tab-acts-natively t)
   (org-babel-load-languages '
    ((emacs-lisp t)
     (scheme t) (ruby t) (python t)
     ;; (sh t) todo get ob-sh
     ;;(c t)
     (lisp t) (shell t))))

  :config
  (set-face-attribute 'org-link nil :inherit 'org-archived))
;; ** org utilities

(use-package
  org-bookmark-heading
  :ensure t
  :commands
  org-mode
  bookmark-jump
  :custom (org-bookmark-jump-indirect t))

(use-package org-variable-pitch
  :ensure t)

;; ** shr/eww/shrface

(use-package
  shr-tag-pre-highlight
  :ensure t
  :commands shr-tag-pre-highlight
  :custom
  (shr-tag-pre-highlight-lang-modes '
   (("ocaml" tuareg)
    ("elisp" emacs-lisp)
    ("ditaa" artist)
    ("asymptote" asy)
    ("dot" fundamental)
    ("sqlite" sql)
    ("calc" fundamental)
    ("C" c)
    ("cpp" c++)
    ("C++" c++)
    ("screen" shell-script)
    ("shell" sh)
    ("bash" sh)
    ("rust" rustic)
    ("rust" rustic)
    ("awk" bash)
    ("json" "js")
    ;; Used by language-detection.el
    ("emacslisp" emacs-lisp)
    ;; Used by Google Code Prettify
    ("el" emacs-lisp))))

(use-package
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
   (:map eww-mode-map ("<backtab>" . nil)
         ("g" . nil)) ; previous link eww
   (:map shrface-mode-map ("M-l" . shrface-links-consult) ;; lol
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
         ("C-c C-e o" . shrface-html-export-as-org)))
  :custom
  ((shrface-href-versatile t)
   (shrface-cookie-policy nil)
   (shrface-bullets-bullet-list '("*" "**" "***" "****"))
   (shrface-paragraph-fill-column 80))

  :config (add-hook 'outline-view-change-hook #'shrface-outline-visibility-changed)

  (set-face-attribute 'shrface-href-face nil
                      :inherit 'variable-pitch
                      :foreground (face-attribute 'org-level-2 :foreground)))

;; * eww

;; First, rendering library
(use-package
  shr
  :custom
  ((shr-max-width 80)
   (shr-max-image-proportion 0.7)
   (shr-width 80) ;
   ;; don’t render aria-hidden=true tags
   (shr-discard-aria-hidden t)
   (shr-image-animate nil) ; don’t animate gifs!
   (shr-use-colors nil) ; don’t use colors! too flashy!
   (shr-cookie-policy t) ;; for google search, etc
   (shr-folding-mode t)
   (shr-offer-extend-specpdl nil)
   (url-privacy-level 'none)
   (browse-url-new-window-flag nil) ;; never use a new window
   (url-automatic-caching t)
   (browse-url-browser-function #'eww-browse-url)))

;; loaded when running eww
(use-package shr-extras)

;; Then, browser
(use-package
  eww
  ;; TODO: lazy
  :demand t
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
   (:map eww-mode-map ("W" . sd/eww-up-to-w3m)
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
         ("," . eww-reload))
   (:map dired-mode-map ("e" . eww-open-file)))
  :custom ((eww-before-browse-history-function 'ignore)
           (eww-header-line-format nil)
           (eww-history-limit 99999)
           (eww-restore-desktop t)
           ;; tab support
           (browse-url-new-window-flag t)
           (eww-browse-url-new-window-is-tab nil)
           (eww-desktop-remove-duplicates t)
           (eww-auto-rename-buffer t) ;; covered by 'epithet'
           (eww-form-checkbox-selected-symbol "[x]")
           (eww-form-checkbox-symbol "[ ]")
           ;; TODO: fix
           (eww-search-prefix "https://www.google.com/search?ion=1&q="))
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


  ;; inhibit images by default
  ;; use my/eww-toggle-images to toggle them back on (bound to i)
  (setopt shr-inhibit-images t))
(use-package
  eww-extras
  ;; TODO: lazy
  :demand t
  :bind (:map eww-mode-map ("D" . sd/h2o-current-eww-url)))

(use-package
  shr-tag-pre-highlight
  :ensure t
  :commands shr-tag-pre-highlight
  :custom
  (shr-tag-pre-highlight-lang-modes '
   (("ocaml" tuareg)
    ("elisp" emacs-lisp)
    ("ditaa" artist)
    ("asymptote" asy)
    ("dot" fundamental)
    ("sqlite" sql)
    ("calc" fundamental)
    ("C" c)
    ("cpp" c++)
    ("C++" c++)
    ("screen" shell-script)
    ("shell" sh)
    ("bash" sh)
    ("rust" rustic)
    ("rust" rustic)
    ("awk" bash)
    ("json" "js")
    ;; Used by language-detection.el
    ("emacslisp" emacs-lisp)
    ;; Used by Google Code Prettify
    ("el" emacs-lisp))))

;; * flymake and flycheck

;; make flymake backends work with flycheck

(use-package flymake
  :ensure t
  :bind
  (:map flymake-mode-map ("C-<left>" . flymake-goto-next-error)
        ("C-<right>" . flymake-goto-prev-error)
        ("M-g M-f" . flymake-show-project-diagnostics)))

(use-package flymake-flycheck
  :ensure t
  :hook (flymake-mode-hook . flymake-flycheck-auto))

(use-package flycheck
  :ensure t
  ;; make it fast
  :custom
  ((flycheck-idle-change-delay 5)
   (flycheck-idle-buffer-switch-delay 3)
   (flycheck-indication-mode 'left-fringe)
   (flycheck-standard-error-navigation t)
   (flycheck-deferred-syntax-check nil)
   (flycheck-display-errors-delay 2)
   (flycheck-highlighting-mode 'symbols)
   ;; use load path of current emacs session for checking
   (flycheck-emacs-lisp-load-path 'inherit)
   (flycheck-relevant-error-other-file-show nil)
   ;; when saving
   (flycheck-check-syntax-automatically '(save new-line))
   ;; navigate compilation errors, not standard errors with error
   ;; navigation keys
   (flycheck-standard-error-navigation nil)
   (next-error-function #'flycheck-next-error-function)
   (previous-error-function #'flycheck-previous-error-function)))

(use-package flycheck-inline
  :ensure t
  :hook (flycheck-mode-hook . flycheck-inline-mode)
  ;; use quick-peek for nice box display
  :config
  (setopt
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

;; ** terminal

;; dependency for ghostel
(use-package dape
  :ensure t)

(use-package ghostel
  :after dape
  :vc (:url "https://github.com/dakra/ghostel"
            :lisp-dir "lisp"
            :rev :newest)
  :bind (("C-c v v" . ghostel)
         ("C-c v b" . ghostel-list-buffers))
  :custom ((ghostel-eval-cmds

            '(("find-file" find-file)
              ("find-file-other-window" find-file-other-window)
              ("dired" dired)
              ("magit-status-setup-buffer" magit-status-setup-buffer)
              ("dired-other-window" dired-other-window)
              ("message" message)))
           (ghostel-tramp-shell-integration t)
           (ghostel-module-auto-install 'download)
           (ghostel-max-scrollback 20971520)
           (ghostel-timer-delay 0.005))
  :config
  ;; Use ghostel buffers for *compilation* buffers
  (require 'ghostel-compile)
  (ghostel-compile-global-mode 1)
  ;; Use ghostel for visual commands
  ;; Or use 'ghostel'
  (require 'ghostel-eshell)
  (add-hook 'eshell-load-hook #'ghostel-eshell-visual-command-mode)
  (add-to-list 'project-switch-commands '(ghostel-project "Ghostel") t))

(use-package detached
  :ensure t
  :init
  (detached-init)
  :bind (;; Replace `async-shell-command' with `detached-shell-command'
         ([remap async-shell-command] . detached-shell-command)
         ;; Replace `compile' with `detached-compile'
         ([remap compile] . detached-compile)
         ([remap recompile] . detached-compile-recompile)
         ;; Replace built in completion of sessions with `consult'
         ([remap detached-open-session] . detached-consult-session)
         ("C-x f C-d" . detached-open-session))
  :custom ((detached-show-output-on-attach t)
           (detached-terminal-data-command system-type)))

;; ** asciidoc

(use-package asciidoc-mode
  :ensure t
  :preface (defun sd/asciidoc-mode-hook ()
             (interactive)
             (visual-line-mode)
             (remove-hook 'after-save-hook #'whitespace-cleanup))
  :hook (asciidoc-mode-hook . sd/asciidoc-mode-hook)
  :config (asciidoc-install-grammars))

;; ** lsp

(use-package eglot
  :bind ("C-c ." . eglot-code-actions)
  :custom ((eglot-autoshutdown t)
           (eglot-confirm-server-edits nil)
           (eglot-extend-to-xref t)
           (eglot-advertise-cancellation t)))

;; ** js mode

(use-package js-mode
  :hook ((js-mode-hook . js-ts-mode)
         (js-ts-mode-hook . eglot-ensure)))

  (use-package emmet-mode
    :ensure t
    :hook (html-mode-hook . emmet-mode))

(use-package nodejs-repl
  :ensure t
  :bind (:map js-ts-mode-map
              (("C-c C-r" . nodejs-repl-send-region)
               ("C-c C-f " . nodejs-repl-send-file)
               ("C-c C-c" . nodejs-repl-send-buffer)
               ("C-c C-p" . nodejs-repl))))
(add-hook 'js-mode-hook #'yas-minor-mode)

(use-package jsfmt
  :ensure t)

;; * c mode

(add-hook 'c-mode-common-hook
          (lambda ()
            (setq c-basic-offset 8)
            (setq indent-tabs-mode t)
            (setq tab-width 8)
            (eglot-ensure)))
;; ** ruby mode

(use-package ruby-end
  :ensure t
  :hook (ruby-mode-hook . ruby-end-mode))

(use-package ruby
  :hook ((ruby-mode-hook . ruby-ts-mode)
         (ruby-ts-mode-hook . eglot-ensure))
  :bind (:map ruby-ts-mode-map
              (("C-c C-l" . ruby-send-line)
               ("C-c C-b" . ruby-send-block)
               ("C-c C-r" . ruby-send-region)
               ("C-c C-e" . ruby-send-region-and-go)
               ("C-c C-c" . ruby-send-buffer))))

(use-package rubocop
  :ensure t
  :hook (ruby-ts-mode-hook . rubocop-mode))

(use-package inf-ruby
  :ensure t
  :bind (:map ruby-ts-mode-map
              (("C-c C-p" . ruby-switch-to-inf)
               ("C-M-x" . ruby-send-definition))))

;; ** markdown mode

;;Tree-sitter bindings for Emacs 30+

(use-package markdown-ts-mode
  :mode ("\\.md\\'" . markdown-ts-mode)
  :ensure t
  :defer 't
  :config
  (add-to-list 'treesit-language-source-alist '(markdown "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown/src"))
  (add-to-list 'treesit-language-source-alist '(markdown-inline "https://github.com/tree-sitter-grammars/tree-sitter-markdown" "split_parser" "tree-sitter-markdown-inline/src")))

;; ** python mode

(use-package flycheck-mypy
  :ensure t)

(use-package eglot-python-preset
  :ensure t
  :custom (eglot-python-preset-lsp-server 'zuban))

(use-package python-docstring
  :ensure t
  :hook (python-ts-mode-hook . python-docstring-mode))

(use-package python-black
  :ensure t
  :config
  :hook (python-ts-mode-hook . python-black-on-save-mode-enable-dwim))

;; ** go mode

(add-hook 'go-mode-hook #'yas-minor-mode)

(use-package go-mode
  :ensure t
  :hook (go-mode-hook . go-ts-mode)
  :bind (:map go-mode-map
              ("C-x f f" . gofmt)))

(use-package go-imenu
  :ensure t
  :hook (go-mode-hook . go-imenu-setup))

(use-package gofmt-tag
  :ensure t
  :hook (go-mode-hook . gofmt-tag-mode))

(use-package go-scratch
  :ensure t)

(add-hook 'go-ts-mode-hook #'eglot-ensure)

;; ** eldoc

(use-package eldoc
  :ensure t
  :custom ((eldoc-echo-area-use-multiline-p nil)
           (eldoc-documentation-strategy #'eldoc-documentation-compose)
           (eldoc-idle-delay 0.5)))

(use-package eldoc-box :ensure t)

;; ** prog mode

(use-package virtual-comment
  :ensure t
  :bind (:map prog-mode-map
              (("C-c ;" . virtual-comment-make)
               ("C-c C-;" . virtual-comment-delete)
               ("C-c C->" . virtual-comment-next)
               ("C-c C-<" . virtual-comment-previous))))

(use-package hl-line
  :ensure t)

(use-package hl-column
  :ensure t)

(use-package exercism
  :ensure t
  :demand t)

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
  (virtual-comment-mode)
  (add-hook 'after-save-hook #'whitespace-cleanup)
  (hl-line-mode)
  (hl-column-mode)
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

(add-hook 'prog-mode-hook #'sd/prog-mode-hook)

;; ** completion

(use-package corfu
  :ensure t
  :init (global-corfu-mode)
  :hook (corfu-mode-hook . corfu-history-mode)
  :bind (:map corfu-map
              ("TAB" . corfu-next)
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
              ([backtab] . corfu-previous)
              :map corfu-popupinfo-map :package corfu-popupinfo
              ("M-n" . corfu-popupinfo-scroll-up)
              ("M-p" . corfu-popupinfo-scroll-down))
  :custom (corfu-auto t) ; popup auto on delay
  (corfu-preselect-first t)
  (corfu-separator ?\s) ; space
  (corfu-min-width 40)
  (corfu-max-width 80)
  (corfu-auto-prefix 1)
  (corfu-separator ?\s) ; for orderless comp, use spc?
  (corfu-quit-at-boundary nil)
  (corfu-quit-no-match 'separator)
  (corfu-sort-function #'corfu-sort-length-alpha)
  (corfu-echo-documentation t)
  (corfu-auto-delay 0.05)
  (corfu-scroll-margin 5)
  (corfu-count 15)
  (completion-styles '(basic))
  (completion-category-overrides
   ((file (styles orderless-fast partial-completion))))
  (corfu-popupinfo-delay 0.5)
  (corfu-popupinfo-max-height 60)
  (corfu-popupinfo-max-width 80)
  :config
  ;; TODO: consider minibuffer completion for corfu
  ;; (add-to-list 'corfu--frame-parameters `(font . ,my-font))
  (add-hook 'corfu-mode-hook #'corfu-popupinfo-mode))

(if (not (display-graphic-p))
    (use-package corfu-terminal
      :ensure t
      :config (corfu-terminal-mode)))

;; ** Parentheses

(use-package rainbow-delimiters
  :ensure t)

(use-package paren
  :ensure nil
  :custom
  ((show-paren-style 'parenthesis) ; show matchin paren
   (show-paren-when-point-in-periphery t) ; show when near paren
   (show-paren-delay 0.4)
   (show-paren-when-point-inside-paren t))) ; don’t show when inside paren

;; ** Whitespace

(setopt backward-delete-char-untabify-method 'hungry)

(use-package whitespace
  :custom
  ;; what to do when a buffer is visited or written
  ((whitespace-action '(auto-cleanup))
   ;; which blanks to visualize?
   ;; disable whitespace mode in these modes
   (whitespace-space-regexp "\\( +\\|\x3000+\\)") ; mono and multi-byte space
   (whitespace-display-mappings
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

(setopt
 indent-tabs-mode nil
 c-basic-indent 2
 c-basic-offset 2
 sh-basic-offset 2
 ;; tab-stop positions are (2 4 6 8 ...)
 tab-stop-list (number-sequence 2 200 2)
 tab-width 8)

;; TODO: what?
;; (paragraph-indent-minor-mode)

(use-package align
  :ensure t)

;; ** programming utilities

(use-package whitespace-cleanup-mode
  :ensure t
  :custom
  (whitespace-cleanup-mode-only-if-initially-clean nil)
  (whitespace-style '(face
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

(use-package xref
  :ensure t
  :hook (xref-after-return-hook . recenter)
  :custom (xref-marker-ring 30)) ; should be enough

;; * git
;; ** magit

;;; ** tree-sitter

;; TODO: get working
(use-package treesit :custom (treesit-font-lock-level 4))

(setopt treesit-font-lock-level 4)

(setopt treesit-language-source-alist
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
(use-package
  treesit-auto
  :ensure t
  :demand t
  :custom
  ((treesit-auto-install t)
   (treesit-auto-langs '(python bash yaml))
   (treesit-auto-add-to-auto-mode-alist 'all))
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)) ;; all from treesit-auto-langs

;; * minibuffer
;; ** vertico, embark, consult

;; Enable Vertico.
(use-package vertico
  :ensure t
  :custom
  ((vertico-scroll-margin 0) ;; Different scroll margin
   (vertico-count 5) ;; Show more candidates
   (vertico-resize 'grow-only) ;; Grow and shrink the Vertico minibuffer
   (vertico-cycle t)) ;; Enable cycling for `vertico-next/previous'
  :config
  (vertico-mode))

(setopt read-file-name-completion-ignore-case t
        read-buffer-completion-ignore-case t
        completion-ignore-case t)

;; Example configuration for Consult
(use-package consult
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
         (:map isearch-mode-map ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
               ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
               ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
               ("M-s L" . consult-line-multi)))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Tweak the register preview for `consult-register-load',
  ;; `consult-register-store' and the built-in commands.  This improves the
  ;; register formatting, adds thin separator lines, register sorting and hides
  ;; the window mode line.
  (advice-add #'register-preview :override #'consult-register-window)
  (setopt register-preview-delay 0.1)

  ;; Use Consult to select xref locations with preview
  (setopt xref-show-xrefs-function #'consult-xref
          xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep consult-man :preview-key '(:debounce 0.05 any)
   consult-bookmark consult-recent-file consult-xref
   ;; :preview-key "M-."
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; "C-+"

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (keymap-set consult-narrow-map (concat consult-narrow-key " ?") #'consult-narrow-help)
  )

(use-package
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
  (setopt prefix-help-command #'embark-prefix-help-command)

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
;; (use-package savehist
;;   :init
;;   (savehist-mode))

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

(use-package
  dired
  ;; TODO: lazy ?
  :hook
  ((dired-mode-hook . dired-hide-details-mode))
  ;;(dired-mode-hook . dired-async-mode))
  :bind
  ((:map dired-mode-map
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
   (dired-listing-switches "-iafxhlvs --group-directories-first --time-style=long-iso")
   (dired-free-space-args "-ph")
   ;; which files not to display
   (dired-omit-files "^\\.\\|^#.*#$")
   ;; which directories to track
   (dirtrack-list '("^[^:]*:\\(?:\e\\[[0-9]+m\\)?\\([^$#\e]+\\)" 1))
   (ls-lisp-ignore-case t)
   (ls-lisp-dirs-first t)
   (dired-dwim-target t)
   ;; use system's trash can
   (delete-by-moving-to-trash t)
   ;; don’t delete excess backup versions silently
   (delete-old-versions t)
   ;; don't hide symbolic link targets
   (wdired-allow-to-change-permissions nil)
   (wdired-create-parent-directories t)
   (dired-auto-revert-buffer #'dired-directory-changed-p)
   (dired-recursive-deletes 'always)
   (delete-by-moving-to-trash t)
   (dired-always-read-filesystem t)
   (dired-vc-rename-file t)
   (dired-copy-preserve-time t)
   (dired-recursive-copies t)
   (dired-clean-confirm-killing-deleted-buffers nil)
   (dired-kill-when-opening-new-dired-buffer t)
   (dired-hide-details-hide-symlink-targets nil)
   (dired-omit-verbose nil) ;; don't show messages when omitting files
   (dired-recursive-copies 'always) ;; always copy recursively
   (dired-recursive-deletes 'always) ;; always delete recursively
   (find-ls-option '("-print0 | xargs -p4 -0 ls -ldn" . "-ldn"))
   (find-ls-subdir-switches "-ldn")
   (find-ls-subdir-switches "-ldn")
   ;; run command depending on os, depending on file-type
   (dired-guess-shell-alist-user `
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

;; * window

(use-package zoom
  :ensure t
  :init (zoom-mode 1)
  :custom ((zoom-ignored-buffer-names '(" *which-key*"))))

(use-package auto-dim-other-buffers
  :ensure t
  :init (auto-dim-other-buffers-mode 1)
  :custom (auto-dim-other-buffers-dim-on-switch-to-minibuffer nil))

(use-package winum
  :ensure t
  :demand t
  :bind
  (("M-o" . nil) ;; kill-region
   ("M-o 1" . winum-select-window-1)
   ("M-o 2" . winum-select-window-2)
   ("M-o 3" . winum-select-window-3)
   ("M-o 4" . winum-select-window-4)
   ("M-o 5" . winum-select-window-5)
   ("M-o 6" . winum-select-window-6)
   ("M-o 7" . winum-select-window-7)
   ("M-o 8" . winum-select-window-8)
   ("M-o 9" . winum-select-window-9))
  :config (winum-mode)
  :custom
  ((winum-scope 'frame-local)
   (winum-reverse-frame-list nil)
   (winum-auto-assign-0-to-minibuffer nil)
   (winum-auto-setup-mode-line t)))

(use-package
  winner
  :init (winner-mode)
  :bind ("C-c M-o" . winner-undo)
  :custom ((winner-ring-size 999) (winner-dont-bind-my-keys t)))

(use-package
  ace-window
  :ensure t
  :bind (("M-o s" . ace-swap-window) ("M-j" . ace-window))
  :custom
  ((aw-keys quote (106 105 112)) ;; j i p
   (aw-background nil)
   (aw-scope 'frame)
   (aw-char-position 'top-left)
   (aw-ignore-current t)
   (aw-leading-char-style 'path)
   (aw-display-mode-overlay nil)
   (aw-dispatch-alist '
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
   (aw-ignored-buffers '("wtf2"))
   (aw-ignore-on t)))

(use-package zoom
  :ensure t
  :init (zoom-mode 1))

;; * look

(use-package minions
  :ensure t
  :init (minions-mode 1))

(use-package kaolin-themes
  :ensure t
  :demand t
  :init
  (defun my-mode-line-font-small ()
    (interactive)
    (set-face-attribute 'mode-line nil :height 85)
    (set-face-attribute 'mode-line-inactive nil :height 85))

  ;;COMMIT: remove my-toggle
  ;;(my-mode-line-font-small)
  :config
  (load-theme 'kaolin-mono-dark t nil)
  :custom ((kaolin-themes-hl-line-colored nil)
           (kaolin-themes-bold nil)
           (kaolin-themes-italic nil)))

(blink-cursor-mode 0)

(setopt x-stretch-cursor nil
        cursor-in-non-selected-windows nil)

;; * Filling and fringes

(use-package modern-fringes
  :ensure t
  :init (modern-fringes-mode 1))

(setopt fringe-mode '(0 . 0))

(set-face-attribute 'fringe nil :inherit 'org-level-4)

(use-package default-text-scale
  :ensure t
  :bind
  (("C-x C--" . nil) ;; text-scale-adjust
   ("C-x C--" . default-text-scale-decrease)
   ("C-x C-=" . nil) ;; text-scale-adjust
   ("C-x C-=" . default-text-scale-increase) ("C-x C-M--" . viewing-2))
  :custom ((default-text-scale-amount 5) (text-scale-mode-step 1.1)))

;; * completion and config for yaml using yaml-pro and lang serv

(defun sd/yaml-mode-hook ()
  (indent-bars-mode)
  (add-hook 'after-save-hook #'whitespace-cleanup))

;; TODO: test with ts -mode
(use-package yaml
  :hook (yaml-mode-hook . sd/yaml-mode-hook))

;; (use-package yaml-pro
;;   :ensure t
;;   :hook ((yaml-ts-mode-hook)
;;          . yaml-pro-ts-mode)
;;   :bind (:map yaml-pro-mode-map
;;          (("C-M-f" . yaml-pro-next-subtree)
;;           ("C-M-b" . yaml-pro-prev-subtree)
;;           ("C-M-d" . yaml-pro-down-level)
;;           ("C-M-u" . yaml-pro-up-level)
;;           ("C-c w" . yaml-pro-mark-subtree)
;;           ("C-c C-M-f" . yaml-pro-move-subtree-down)
;;           ("C-c C-M-b" . yaml-pro-move-subtree-up))))


(use-package flycheck-yamllint
  :ensure t)

(use-package yaml-imenu
  :ensure t
  :bind (:map yaml-ts-mode-map
              ("M-g i" . yaml-imenu)))

;; * ansible helpers

(use-package ansible
  :ensure t)

(use-package flymake-ansible-lint
  :ensure t
  :commands flymake-ansible-lint-setup
  :hook ((yaml-ts-mode . flymake-ansible-lint-setup)
         (yaml-mode . flymake-ansible-lint-setup)
         (yaml-ts-mode . flymake-mode)
         (yaml-mode . flymake-mode)))

(use-package ansible-doc
  :ensure t)

;; * multiple cursors

(use-package multiple-cursors
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
  :custom (mc/max-cursors 6000)
  :config
  (add-to-list 'mc/unsupported-minor-modes 'corfu-mode))

;; * magit

;; * terraform

(use-package terraform-mode
  :after magit
  :ensure t
  :custom ((terraform-indent-level 2))
  :config
  (defun sd/terraform-mode-init ()
    (outline-minor-mode 1)
    (terraform-format-on-save-mode))
  :hook (terraform-mode-hook . sd/terraform-mode-init))

(use-package popup-imenu
  :ensure t
  :bind ("M-g i" . popup-imenu))

(add-hook 'hcl-mode-hook #'flycheck-mode)

(use-package consult-flycheck
  :ensure t
  :bind ("M-g f" . consult-flycheck))

(use-package imenu
  :custom (imenu-auto-rescan t))

;; * json

(use-package json-mode
  :bind (:map json-ts-mode-map
              ("C-c ." . json-ts-jq-path-at-point))
  :hook ((json-mode-hook . json-ts-mode)
         (js-json-mode-hook . json-ts-mode)))
(put 'narrow-to-region 'disabled nil)

(use-package jenkinsfile-mode
  :ensure t)

(use-package dockerfile-mode
  :ensure t)

(use-package anzu
  :ensure t)

;; ** global

(use-package jinx
  :ensure t
  :init (global-jinx-mode)
  :custom (jinx-languages "en_GB"))

