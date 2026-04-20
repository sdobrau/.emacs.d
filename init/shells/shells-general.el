(setq-default confirm-kill-processes nil)
(setq-default kill-buffer-query-functions nil)
(setq-default shell-command-switch "-c")

(setq-default async-shell-command-display-buffer . nil)

;; TODO: for vterm
;; (leaf quick-shell-keybind
;;   :ensure t
;;   :bin)

;; redirection supported, region supported
(leaf
  shell-command+
  :ensure t
  :bind ("M-!" . shell-command+)
  :custom (shell-command+-prompt . "$+: "))

;; TODO: keys
(leaf shelldon :ensure t)

(leaf
  xterm-color
  :ensure t
  :commands eshell
  :custom ((xterm-color-use-bold-for-bright . t)))

;; commands on marked files
(leaf dwim-shell-command :ensure t)

;; TODO: fix
;; (leaf
;;   recall
;;   :ensure t
;;   :bind*
;;   ;; Or if minibuffer completion is your preferable interface
;;   (("C-c ! !" . recall-rerun)
;; ("C-c ! e" . recall-rerun-edit)
;;     ("C-c ! l" . recall-find-log)
;;     ("C-c ! k" . recall-process-kill)
;;     ("C-c ! b" . recall-buffer))
;;   ;; Enable process surveillance
;;   (recall-mode +1)
;;   :config
;;   (setq-default recall-completing-read-fn #'recall-consult-completing-read)
;;   (run-at-time t 120 #'recall-save))

;; run commands detached from emacs
;; TODO: wait and test. wip and not working with consult
;; (leaf detached
;;   :if (executable-find "dtach")
;;  (lea :quelpa
;;   (detached
;;     :fetcher sourcehut
;;     :branch "lean"
;;     :repo "niklaseklund/detached.el"
;;     :files (:defaults "lean/*.el" "lean/*.org"))
;;   :init (detached-init)
;;   :bind-keymap ("C-c M-!" . detached-embark-action-map)
;;   ;; C-c C-d to detach
;;   :bind
;;   ( ;; Replace `async-shell-command' with `detached-shell-command'
;;     ([remap async-shell-command] . detached-shell-command)
;;     ;; Replace `compile' with `detached-compile'
;;     ([remap compile] . detached-compile)
;;     ([remap recompile] . detached-compile-recompile)
;;     ;; Replace built in completion of sessions with `consult'
;;     ([remap detached-open-session] . detached-consult-session))
;;   :custom
;;   ((detached-show-output-on-attach . t)
;;     ;; command regexps to use 'tail' instead of 'tee' with
;;     ;; (detached-degraded-commands . '("^ls"))
;;     ;; command regexps for weird escape sequences
;;     ;; (detached-plain-text-commands . '("^ls"))
;;     ;; not really using these atm
;;     (detached-init-block-list . '(eshell shell org))
;;     (detached-terminal-data-command . system-type)))
