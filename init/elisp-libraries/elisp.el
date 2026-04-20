;; (require 'mm-url) ; to include mm-url-decode-entities-string
;; (require 'subr-x)
;; (require 'seq)
;; (require 'xdg)

(leaf loopy :ensure t)

(leaf
  xr
  :ensure t) ;; grab

(leaf unicode-escape :ensure t)

(leaf dash :ensure t)

(leaf
  elisp-refs
  :ensure t
  :commands
  helpful-callable
  helpful-variable
  helpful-key
  helpful-symbol)

(leaf transient :quelpa (transient :fetcher github :repo "magit/transient"))

(leaf elisp-def :quelpa (elisp-def :fetcher github :repo "Wilfred/elisp-def"))

(leaf smartparens :ensure t)

(leaf
  eros
  :after smartparens
  :preface
  ;; https://github.com/howardabrams/hamacs/blob/14e023c7302dd46893f8b008925aab3ee8ecdc2a/ha-programming-elisp.org
  (defun ha-eval-current-expression ()
    "Evaluates the expression the point is currently 'in'.
It does this, by jumping to the end of the current
expression (using evil-cleverparens), and evaluating what it
finds at that point."
    (interactive)
    (save-excursion
      (if (region-active-p)
        (eval-region (region-beginning) (region-end))

        (sp-end-of-sexp)
        (if (fboundp 'eros-eval-last-sexp)
          (call-interactively 'eros-eval-last-sexp)
          (call-interactively 'eval-last-sexp)))))
  :ensure t
  :bind ("C-x C-e" . ha-eval-current-expression)
  :config
  ;; https://xenodium.com/inline-previous-result-and-why-you-should-edebug
  (defun adviced:edebug-previous-result (_ &rest r)
    "Adviced `edebug-previous-result'."
    (eros--make-result-overlay
      edebug-previous-result
      :where (point)
      :duration eros-eval-result-duration))

  (advice-add
    #'edebug-previous-result
    :around #'adviced:edebug-previous-result))

(leaf
  inspector
  :ensure t
  :preface

  :bind
  (([remap eval-last-sexp] . eval-or-inspect-last-sexp)
    ([remap eval-expression] . eval-or-inspect-expression)))

(leaf tree-inspector :ensure t)

(leaf
  eros-inspector
  :ensure t
  :preface

  ;; TODO: do
  (defun eval-or-inspect-expression (arg)
    "Like `eval-expression', but also inspect when called with prefix ARG."
    (interactive "P")
    (pcase arg
      ('(4)
        (let ((current-prefix-arg nil))
          (call-interactively #'inspector-inspect-expression)))
      (_ (call-interactively #'eval-expression))))

  (defun eval-or-inspect-last-sexp (arg)
    "Like `eval-last-sexp', but also inspect when called with prefix ARG."
    (interactive "P")
    (pcase arg
      ('(4) (inspector-inspect-last-sexp))
      (_ (call-interactively #'eval-last-sexp))))
  :bind
  (([remap eval-last-sexp] . eval-or-inspect-last-sexp)
    ([remap eval-expression] . eval-or-inspect-last-sexp)))

(leaf dash-functional :ensure t)

(leaf f :ensure t)

(leaf asoc :quelpa (asoc :fetcher github :repo "troyp/asoc.el"))

(leaf s :ensure t)

(leaf cl-lib :ensure t)

(leaf thingatpt :ensure t)

(leaf deferred :ensure t)

(leaf epc :ensure t :after concurrent ctable)
