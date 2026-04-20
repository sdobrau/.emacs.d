;; -*- lexical-binding: t -*-

(setq-default user-full-name "strangepr0gram"
        user-mail-address "serban.dobrau@gmail.com"

        ;; Send email through SMTP
        message-send-mail-function 'smtpmail-send-it

        smtpmail-default-smtp-server "smtp.gmail.com"
        smtpmail-smtp-service 587
        smtpmail-local-domain "homepc")

;; auto-complete emacs address using bbdb command, optional
(add-hook 'message-mode-hook
          '(lambda ()
             (flyspell-mode t)
             (local-set-key (kbd "TAB") 'bbdb-complete-name)))
