;;; -*- lexical-binding: t -*-

;; don't compile, otherwise compiles on each start

(menu-bar-mode 0)
(tool-bar-mode 0)
(scroll-bar-mode 0)

(setopt compile-command nil)

;; dark

;; exwm
(if (getenv "INSIDE_EXWM")
    (setopt
     mouse-autoselect-window t
     focus-follows-mouse t))

(setopt enable-local-variables t)

(defvar file-name-handler-alist-old file-name-handler-alist)
(setopt file-name-handler-alist nil)

;; we will set it back in zz-finish.el

;; wtf
(setopt max-lisp-eval-depth 65536)
(setopt max-specpdl-size 13000)

;; Emacs determines terminal capabilities by:
;;
;; querying terminfo capabilities
;; issuing terminal queries
;; looking at the name of the terminfo
;;
;; The last point is the reason Emacs by default only has 8 colors in foot. We need to tell Emacs that foot is an XTerm compatible terminal. The easiest way to do that is to add the following to your .emacs:
;; https://codeberg.org/dnkl/foot/wiki#only-8-colors-in-emacs
;;

;; TODO: run major mode hooks only if visible not if visited, and add font lock to major mode

(add-to-list 'term-file-aliases '("foot" . "xterm"))

;; (funcall-interactively #'toggle-debug-on-error t)

(require 'epa-file)
(epa-file-enable)

;;; comp settings
;; max optimizations
(setopt
 native-comp-speed 2
 ;; 4 cores
 native-comp-async-jobs-number (string-to-number (shell-command-to-string "nproc"))
 native-comp-async-report-warnings-errors nil
 byte-compile-warnings nil
 bytecomp--inhibit-lexical-cookie-warning t
 byte-compile-verbose nil
 byte-compile-docstring-max-column 120
 native-comp-async-query-on-exit t
 native-comp-warning-on-missing-source nil
 native-comp-jit-compilation nil
 native-comp-always-compile nil
 warning-suppress-types '((comp))) ; hide compilation warnings
;;; * optional startup profiling

(defvar sd/startup-profile-enabled
  (or (getenv "EMACS_STARTUP_PROFILE") nil)
  "When non-nil, record slow events during startup.

Enable by launching Emacs with:

  EMACS_STARTUP_PROFILE=1 emacs

You can also enable per-form timing inside init/early-init with:

  EMACS_STARTUP_PROFILE=1 EMACS_STARTUP_PROFILE_FORMS=1 emacs

The report is shown in buffer `*startup-profile*' after startup.")

(defvar sd/startup-profile-forms-enabled
  (or (getenv "EMACS_STARTUP_PROFILE_FORMS") nil)
  "When non-nil, also time individual `eval` calls during init loading.

This is more detailed but adds overhead. Use it only when profiling.")

(defvar sd/startup-profile-threshold 0.05
  "Only record events slower than this many seconds.")

(defvar sd/startup-profile--events nil)

(defun sd/startup-profile--secs-since (t0)
  (float-time (time-subtract (current-time) t0)))

(defun sd/startup-profile--record (kind what secs)
  (push (list :kind kind :what what :secs secs) sd/startup-profile--events))

(defun sd/startup-profile--advice-require (orig feature &rest args)
  (if (not sd/startup-profile-enabled)
      (apply orig feature args)
    (let ((t0 (current-time)))
      (prog1 (apply orig feature args)
        (let ((secs (sd/startup-profile--secs-since t0)))
          (when (>= secs sd/startup-profile-threshold)
            (sd/startup-profile--record 'require feature secs)))))))

(defun sd/startup-profile--advice-load (orig file &rest args)
  (if (not sd/startup-profile-enabled)
      (apply orig file args)
    (let ((t0 (current-time)))
      (prog1 (apply orig file args)
        (let ((secs (sd/startup-profile--secs-since t0)))
          (when (>= secs sd/startup-profile-threshold)
            (sd/startup-profile--record 'load file secs)))))))

(defun sd/startup-profile--init-loading-p ()
  "Non-nil when we are currently loading early-init/init."
  (and (stringp load-file-name)
       (or (string-match-p "early-init\\.el\\'" load-file-name)
           (string-match-p "init\\.el\\'" load-file-name)
           (string-match-p "/init\\'" load-file-name))))

(defun sd/startup-profile--advice-eval (orig form &optional lexical)
  (if (not (and sd/startup-profile-enabled
                sd/startup-profile-forms-enabled
                (sd/startup-profile--init-loading-p)))
      (funcall orig form lexical)
    (let ((t0 (current-time)))
      (prog1 (funcall orig form lexical)
        (let ((secs (sd/startup-profile--secs-since t0)))
          (when (>= secs sd/startup-profile-threshold)
            (let* ((head (and (consp form) (car form)))
                   (what (cond
                          ((eq head 'leaf)
                           (list 'leaf (cadr form)))
                          ((eq head 'progn)
                           (list 'progn (car-safe (cadr form))))
                          ((eq head 'setq)
                           (list 'setq (cadr form)))
                          ((symbolp head)
                           head)
                          (t head))))
              (sd/startup-profile--record 'eval what secs))))))))

(defun sd/startup-profile-report ()
  "Show a report of slow loads/requires recorded during startup."
  (interactive)
  (let ((buf (get-buffer-create "*startup-profile*")))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (format "Emacs init time: %s\n\n" (emacs-init-time)))
      (insert (format "Recorded events (>= %.2fs): %d\n\n"
                      sd/startup-profile-threshold
                      (length sd/startup-profile--events)))
      (dolist (ev (sort (copy-sequence sd/startup-profile--events)
                        (lambda (a b)
                          (> (plist-get a :secs) (plist-get b :secs)))))
        (insert (format "%7.3fs  %-7s  %S\n"
                        (plist-get ev :secs)
                        (plist-get ev :kind)
                        (plist-get ev :what))))
      (goto-char (point-min))
      (special-mode))
    (pop-to-buffer buf)))

(when sd/startup-profile-enabled
  (advice-add #'require :around #'sd/startup-profile--advice-require)
  (advice-add #'load :around #'sd/startup-profile--advice-load)
  (when sd/startup-profile-forms-enabled
    (advice-add #'eval :around #'sd/startup-profile--advice-eval))
  (add-hook 'emacs-startup-hook #'sd/startup-profile-report))

;; * other

(setopt
 transient-history-file (concat user-emacs-directory "data/eln-cache/")
 undo-fu-session-directory (concat user-emacs-directory "data/undo-fu-session/")
 url-configuration-directory (concat user-emacs-directory "data/url/")
 eshell-history-file-name (concat user-emacs-directory "data/eshell/history")
 eshell-last-dir-ring-file-name (concat user-emacs-directory "data/eshell/lastdir")
 eww-bookmarks-directory (concat user-emacs-directory "data/eww/bookmarks/")
 recentf-save-file (concat user-emacs-directory "data/recentf-save.el")
 nsm-settings-file (concat user-emacs-directory "network-security.data")
 auto-save-list-file-prefix (concat user-emacs-directory "data/auto-save/sessions/")
 keyfreq-file (concat user-emacs-directory "data/keyfreq.el"))


(defun manateelazycat-add-subdirs-to-load-path (dir)
  "Recursive add directories to `load-path'."
  (let ((default-directory (file-name-as-directory dir)))
    (add-to-list 'load-path dir)
    (normal-top-level-add-subdirs-to-load-path)))

(manateelazycat-add-subdirs-to-load-path (concat user-emacs-directory "lib"))

(setopt enable-local-variables ':all)

;; disable native backup from the start.
(setq-default make-backup-files nil)

(setq-default minibuffer-auto-raise nil)

;; performance
(setq-default
 frame-inhibit-implied-resize t
 frame-resize-pixelwise t)

;; ignore X resources
(advice-add #'x-apply-session-resources :override #'ignore)
;; don't pass again over auto-mode-alist case-insen for perf
(setq auto-mode-case-fold nil)

(setq-default network-security-level 'high)

(server-start)
                                        ; GPG passphrase prompt in minibuffer.
;; See gpg-agent.conf 'allow-emacs-pinentry'.
;;
;; gpg --> gpg-agent --> pinentry --> Emacs
;; /tmp/emacs-$(id)/pinentry <- socket used for pinentry/emacs communication
;; TODO: make sure package is present first

(setq custom-file (concat user-emacs-directory "junk/trashcustom"))

(setq-default tramp-completion-use-auth-sources nil)

;; ignore tramp remote file errors
(setq-default debug-ignored-errors
              (cons 'remote-file-error debug-ignored-errors))

;;; session-wide vars

(defvar my-font "Roboto Mono 9")

(set-face-attribute 'variable-pitch nil :weight 'normal)

;;; pinentry emacs

(setf epg-pinentry-mode 'loopback)

(defun pinentry-emacs (desc prompt ok error)
  (let
      (
       (str
        (read-passwd
         (concat
          (replace-regexp-in-string
           "%22"
           "\""
           (replace-regexp-in-string "%0A" "\n" desc))
          prompt ": "))))
    str))

;;; frame options

(setq-default
 initial-frame-alist
 `
 ((font . ,my-font)
  (vertical-scroll-bars . nil)
  (menu-bar-lines . 0)
  (tool-bar-lines . 0)
  (fullscreen . maximized)
  (undecorated . nil)
  (title . "Emacs")
  (name . "Emacs"))
 default-frame-alist
 `
 ((font . ,my-font)
  (vertical-scroll-bars . nil)
  (height . 300)
  (width . 300)
  (menu-bar-lines . 0)
  (tool-bar-lines . 0)
  (min-width . nil)
  (min-height . nil)
  (undecorated . nil)))

(modify-all-frames-parameters
 `
 ((font . ,my-font)
  (height . 100)
  (width . 100)
  (vertical-scroll-bars . nil)
  (menu-bar-lines . 0)
  (tool-bar-lines . 0)
  (undecorated . nil)))

(custom-theme-set-faces 'user
                        '(variable-pitch ((t (:family "Arial" :height 100 :weight regular)))))

(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;;; remove startups

(setq inhibit-startup-message t)
(setq inhibit-startup-screen t)
(setq inhibit-splash-screen t)

(setq initial-scratch-message nil)

(setq-default custom-safe-themes t)

(when (eq window-system 'w32)
  (setenv "GIT_ASKPASS" "git-gui--askpass"))

;; window title during terminal
;; run it on each buffer change

(setq-default xterm-set-window-title t)

;;; locale

(setopt locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-charset-priority 'unicode)
(setopt default-process-coding-system '(utf-8-unix . utf-8-unix))
(set-language-environment "utf-8")

;;; gc: don't gc at all during init

(setopt
 gc-cons-threshold 300
 garbage-collection-messages nil
 gc-cons-percentage 0.8)

;; Emacs tries saving your buffers if it receives a fatal signal
;; (including module segfaults).  This is batshit insane, I prefer a
;; clean exit over silent corruption.  The following setting is supposed
;; to make it so:

(setopt attempt-stack-overflow-recovery nil)
(setopt attempt-orderly-shutdown-on-fatal-signal nil)

;;; tls

(defconst sd/tls-trustfile
  (seq-find
   #'file-exists-p
   '("/etc/ssl/certs/ca-certificates.crt"               ; Debian/Ubuntu/Arch
     "/etc/pki/tls/certs/ca-bundle.crt"                 ; Fedora/RHEL
     "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem" ; Fedora/RHEL (alt)
     "/etc/ssl/cert.pem"))
  "Path to a CA bundle used for TLS verification.

We prefer a system CA bundle to avoid spawning external processes
(e.g. `python3 -m certifi`) during startup.")

;; If we found a CA bundle, use it for hardened TLS configuration. Otherwise,
;; keep Emacs defaults (which usually already point at a system trust store).
(when sd/tls-trustfile
  (setq
   tls-program
   (list
    (format
     "gnutls-cli%s --ocsp --dh-bits=2048
--priority='SECURE192:+SECURE128:-VERS-ALL:+VERS-TLS1.2:%%PROFILE_MEDIUM'
--x509cafile %s -p %%p %%h "
     (if (eq window-system 'w32) ".exe" "")
     sd/tls-trustfile))
   gnutls-trustfiles (list sd/tls-trustfile)))

(setopt
 gnutls-verify-error t
 tls-checktrust t
 gnutls-min-prime-bits 2048
 gnutls-algorithm-priority
 (if (eq window-system 'w32)
     ;; for fetching packages when on windows
     ;; see https://emacs.stackexchange.com/a/56067/15763
     "normal:-vers-tls1.3"
   ;; otherwise, hardened
   "SECURE192:+SECURE128:-VERS-ALL:+VERS-TLS1.2"))

;; regexp for authinfo entries that should be hidden
(setopt authinfo-hidden "password")
;; DON't save creds to auth sources. annoying
(setopt auth-source-save-behavior nil)

;; https://github.com/Sliim/emacs.d/blob/master/modules/emacsd-tls-hardening-module.el
;; Enable TLS cert checking
;; ([[https://glyph.twistedmatrix.com/2015/11/editor-malware.html][source]])

;;; package options

(setopt
 package-user-dir
 (directory-file-name (concat user-emacs-directory "packages/elpa")) ; elpa pkgs
 load-prefer-newer t ; prefer newer things
 package-enable-at-startup t ; package-initialize is later in after leaf
 package-list-unversioned t ; unversioned pkg too in list/packages
 package-load-list '(all) ; load all
 package-native-compile nil) ; don’t compile at startup

(defun sd/current-emacsclient-executable ()
  "Return the emacsclient executable used by the current Emacs."
  (or (executable-find "emacsclient")
      "emacsclient"))

(setenv "VISUAL" (concat (sd/current-emacsclient-executable) " -a emacs"))
(setenv "EDITOR" (concat (sd/current-emacsclient-executable) " -a emacs"))
(setenv "GIT_EDITOR" (concat (sd/current-emacsclient-executable) " -a emacs"))
(setenv "NODE_NO_READLINE" "1")
(setenv "PAGER" "cat") ;; for eshell, so piped output does not break it
(setenv "PS1" "\\W > ")

;; dis-italicize comment face
(set-face-attribute 'font-lock-comment-face nil :slant 'normal)
