;; -*- lexical-binding: t -*-

(leaf string-inflection
  :ensure t
  :bind ("C-c u" . string-inflection-toggle)
  :config
  (defun xc/-string-inflection-style-cycle-function (str)
    "foo-bar => foo_bar => foo_bar => foobar => foobar => foo-bar"
    (cond
      ;; foo-bar => foo_bar
      ((string-inflection-kebab-case-p str)
        (string-inflection-underscore-function str))
      ;; foo_bar => foo_bar
      ((string-inflection-underscore-p str)
        (string-inflection-upcase-function str))
      ;; foo_bar => foobar
      ((string-inflection-upcase-p str)
        (string-inflection-pascal-case-function str))
      ;; foobar => foobar
      ((string-inflection-pascal-case-p str)
        (string-inflection-camelcase-function str))
      ;; foobar => foo-bar
      ((string-inflection-camelcase-p str)
        (string-inflection-kebab-case-function str))))

  (defun xc/string-inflection-style-cycle ()
    "foo-bar => foo_bar => foo_bar => foobar => foobar => foo-bar"
    (interactive)
    (string-inflection-insert
      (xc/-string-inflection-style-cycle-function
        (string-inflection-get-current-word)))))
