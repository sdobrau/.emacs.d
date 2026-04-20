;; -*- lexical-binding: t -*-

(leaf json-mode
  :ensure t
  :after json-reformat json-snatcher
  :mode (("\\.bowerrc$" . json-ts-mode)
         ("\\.jshintrc$" . json-ts-mode)
         ("\\.json_schema$" . json-ts-mode)
         ("\\.json\\'" . json-ts-mode))
  :hook (json-ts-mode-hook . (lambda () (show-paren-mode -1))))

(leaf json-navigator
  :ensure t
  :after hierarchy)

;; (leaf jq-ts-mode
;;  :ensure t)

(leaf json-snatcher
  :ensure t)

(leaf json
  :after js2-mode
  :bind ((:js-mode-map
          ("C-c s-j f" . json-pretty-print-buffer)
          ("C-c s-j f" . json-pretty-print-buffer-ordered)
          ("C-c s-j M-f" . json-pretty-print)
          ("C-c s-j M-f" . json-pretty-print-ordered))
         (:js2-mode-map
          (("C-c s-j f" . json-pretty-print-buffer)
           ("C-c s-j f" . json-pretty-print-buffer-ordered)
           ("C-c s-j M-f" . json-pretty-print)
           ("C-c s-j M-f" . json-pretty-print-ordered)))))

(leaf counsel-jq
  :ensure t)
