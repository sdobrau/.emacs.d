;;; -*- lexical-binding: t -*-

;; dark

(load-theme 'tsdh-dark t nil)

;;; * run exwm

(if (getenv "INSIDE_EXWM")
  (setq
    mouse-autoselect-window t
    focus-follows-mouse t))

(setq-default enable-local-variables t)

;; redguard init.el
;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))

;; Which means on every .el and .elc file loaded during start up, it has to runs
;; those regexps against the filename.

(defvar file-name-handler-alist-old file-name-handler-alist)
(setq file-name-handler-alist nil)

;; we will set it back in zz-finish.el

;; wtf
(setq-default max-lisp-eval-depth 65536)
(setq-default max-specpdl-size 13000)

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

;; (defun sd/font-lock-fontify-buffer-1 (buf1 buf2)
;;   (interactive)
;;   (font-lock-fontify-buffer))

(add-to-list 'term-file-aliases '("foot" . "xterm"))

;; (funcall-interactively #'toggle-debug-on-error t)

(require 'epa-file)
(epa-file-enable)

;;; comp settings
;; max optimizations
(setq-default
  native-comp-speed 2
  ;; 4 cores
  native-comp-async-jobs-number 12
  native-comp-async-report-warnings-errors nil
  byte-compile-warnings nil
  bytecomp--inhibit-lexical-cookie-warning t
  byte-compile-verbose nil
  byte-compile-docstring-max-column 120
  native-comp-async-query-on-exit t
  native-comp-warning-on-missing-source nil
  native-comp-jit-compilation t
  ;; handled by compile-angel for new files. not pkgs
  native-comp-always-compile t
  warning-suppress-types '((comp)) ; hide compilation warnings
  native-compile-target-directory (concat user-emacs-directory "data/eln-cache"))

;;; additional data/ placements

;; we set these here early on to make sure they don't write
;; to .emacs.d/

(setq-default
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

;;; init functions and load path

(defun manateelazycat-add-subdirs-to-load-path (dir)
  "Recursive add directories to `load-path'."
  (let ((default-directory (file-name-as-directory dir)))
    (add-to-list 'load-path dir)
    (normal-top-level-add-subdirs-to-load-path)))

(manateelazycat-add-subdirs-to-load-path
 (concat user-emacs-directory "packages/other")) ;
(manateelazycat-add-subdirs-to-load-path
  (concat user-emacs-directory "packages/quelpa/build"))
(manateelazycat-add-subdirs-to-load-path (concat user-emacs-directory "lib"))

(setq-default enable-local-variables ':all)

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
(pinentry-start)

(setq custom-file (concat user-emacs-directory "junk/trashcustom"))

;; redguard init.el
;; @see https://www.reddit.com/r/emacs/comments/3kqt6e/2_easy_little_known_steps_to_speed_up_emacs_start/
;; Normally file-name-handler-alist is set to
;; (("\\`/[^/]*\\'" . tramp-completion-file-name-handler)
;; ("\\`/[^/|:][^/|]*:" . tramp-file-name-handler)
;; ("\\`/:" . file-name-non-special))
;; Which means on every .el and .elc file loaded during start up, it has to runs those regexps against the filename.
;; (setq file-name-handler-alist nil)

(setq-default tramp-completion-use-auth-sources nil)

;; ignore tramp remote file errors
(setq-default debug-ignored-errors
  (cons 'remote-file-error debug-ignored-errors))

;;; session-wide vars

(defvar my-home-directory (concat (getenv "HOME")))
(defvar my-git-directory (concat my-home-directory "/git/"))
(defvar my-org-directory (concat my-home-directory "/org"))
(defvar my-org-roam-directory (concat my-org-directory "/roam"))
(defvar my-garden (concat (getenv "HOME") "/media/garden"))
(defvar my-emacs-dot-files-directory
  (concat my-garden "/elisps/emacs.dot.files"))
(defvar my-music-directory "/ent/Music/")
(defvar my-screenshots-directory
  (concat my-home-directory "/media/screenshots/"))
(defvar my-youtube-directory (concat my-home-directory "/media/youtube/"))
(defvar my-font "monospace 10")
(set-face-font 'variable-pitch "DejaVu Sans")
(set-face-attribute 'variable-pitch nil :weight 'normal)
(defvar my-mail-attachment-directory
  (concat my-home-directory "/mail/attachments/"))

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

(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(set-charset-priority 'unicode)
(setq default-process-coding-system '(utf-8-unix . utf-8-unix))
(set-language-environment "utf-8")

;;; gc: don't gc at all during init

(setq-default
 gc-cons-threshold 300
 garbage-collection-messages nil
 gc-cons-percentage 0.8)

;; Emacs tries saving your buffers if it receives a fatal signal
;; (including module segfaults).  This is batshit insane, I prefer a
;; clean exit over silent corruption.  The following setting is supposed
;; to make it so:

(setq-default attempt-stack-overflow-recovery nil)
(setq-default attempt-orderly-shutdown-on-fatal-signal nil)

;;; tls

;;   +++
;;   ** TLS connections have their security tightened by default.
;;   Most of the checks for outdated, believed-to-be-weak TLS algorithms
;;   and ciphers are now switched on by default.  (In addition, several new
;;   TLS weaknesses are now warned about.)  By default, the NSM will
;;   flag connections using these weak algorithms and ask users whether to
;;   allow them.  To get the old behavior back (where certificates are
;;   checked for validity, but no warnings about weak cryptography are
;;   issued), you can either set 'network-security-protocol-checks' to nil,
;;   or adjust the elements in that variable to only happen on the 'high'
;;   security level (assuming you use the 'medium' level).
;;
;;   +++
;;   ** Native GnuTLS connections can now use client certificates.
;;   Previously, this support was only available when using the external
;;   'gnutls-cli' command.  Call 'open-network-stream' with
;;   ':client-certificate t' to trigger looking up of per-server
;;   certificates via 'auth-source'.

(let
  (
    (trustfile
      (replace-regexp-in-string
        "\\\\" "/"
        (replace-regexp-in-string
          "\n"
          ""
          (shell-command-to-string "python3 -m certifi")))))

  (setq
    tls-program
    (list
      (format
        "gnutls-cli%s --ocsp --dh-bits=2048
--priority='SECURE192:+SECURE128:-VERS-ALL:+VERS-TLS1.2:%%PROFILE_MEDIUM'
--x509cafile %s -p %%p %%h "
        (if (eq window-system 'w32)
          ".exe"
          "")
        trustfile))
    gnutlfs-verify-error t
    gnutls-trustfiles (list trustfile)
    tls-checktrust t
    gnutls-min-prime-bits 2048
    gnutls-algorithm-priority
    (if (eq window-system 'w32)
      ;; for fetching packages when on windows
      ;; see https://emacs.stackexchange.com/a/56067/15763
      "normal:-vers-tls1.3"
      ;; otherwise, hardened
      "SECURE192:+SECURE128:-VERS-ALL:+VERS-TLS1.2")))

;; regexp for authinfo entries that should be hidden
(setq authinfo-hidden "password")
;; DON't save creds to auth sources. annoying
(setq auth-source-save-behavior nil)

;; https://github.com/Sliim/emacs.d/blob/master/modules/emacsd-tls-hardening-module.el
;; Enable TLS cert checking
;; ([[https://glyph.twistedmatrix.com/2015/11/editor-malware.html][source]])

;;; package options

(setq-default
  package-user-dir
  (directory-file-name (concat user-emacs-directory "packages/elpa")) ; elpa pkgs
  load-prefer-newer t ; prefer newer things
  package-enable-at-startup nil ; package-initialize is later in after leaf
  package-list-unversioned t ; unversioned pkg too in list/packages
  package-load-list '(all) ; load all
  package-native-compile nil) ; don’t compile at startup

(defvar sd/current-emacs-client-executable
  (string-trim
    (nth
      3
      (split-string (shell-command-to-string "ls /usr/bin/emacsclient*31*")
        "/"
        nil
        nil)))
  "Current 'emacsclient' executable.
For use in setting for '$EDITOR' and '$VISUAL'.
Varies, may be with or without 'vcs'. ")

(setenv "VISUAL" (concat sd/current-emacs-client-executable " -a emacs"))
(setenv "EDITOR" (concat sd/current-emacs-client-executable " -a emacs"))
(setenv "NODE_NO_READLINE" "1")
(setenv "PAGER" "cat") ;; for eshell, so piped output does not break it
(setenv "PS1" "\\W > ")

;; dis-italicize comment face
(set-face-attribute 'font-lock-comment-face nil :slant 'normal)
