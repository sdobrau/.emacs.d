;; -*- lexical-binding: t -*-

(leaf
  js2-mode
  :ensure t
  :mode ("\\.js\\'" . js2-mode)
  :mode ("\\.mjs\\'" . js2-mode)
  :interpreter "node" ; hook for shell scripts running via node.js
  :custom
  ((js2-mode-show-parse-errors . t)
    (js2-basic-offset . 2)
    (js2-mode-show-strict-warnings . t)
    (js2-strict-missing-semi-warning . t)))

(leaf
  xref-js2
  :ensure t
  :bind (:js2-mode-map (("M-." . nil)))
  :hook
  (js2-mode-hook
    .
    (lambda ()
      (add-hook 'xref-backend-functions #'xref-js2-xref-backend nil t)))

  :custom (xref-js2-search-program . 'rg))
;; xref-js2-rg-arguments

(leaf
  add-node-modules-path
  :ensure t
  :hook (js2-mode-hook . add-node-modules-path))

(leaf
  import-js
  :ensure t
  :bind
  (:js2-mode-map
    (("C-c i i" . import-js-import)
      ("C-c i f" . import-js-fix)
      ("C-c i g" . import-js-goto))))

;; need eslint
(leaf js-auto-format-mode :ensure t :hook (js2-mode-hook . js-auto-format-mode))

(leaf indium :ensure t :hook (js2-mode-hook . indium-interaction-mode))

;; – ee is expand-node-at-point: expand bracketed list according to
;;  node type at point (array, object, function, call args).

;; – cc is contract-node-at-point: contract bracketed list according
;;  to node type at point (array, object, function, call args).

;; – ef is extract-function: extracts the marked expressions out into
;; – a new named function.

;; – em is extract-method: extracts the marked expressions out into a
;;  new named method in an object literal.

;; – tf is toggle-function-expression-and-declaration: toggle between
;;  function name() {} and var name = function (); – ta is
;;  toggle-arrow-function-and-expression: toggle between function
;;  expression to arrow function.

;; – ts is toggle-function-async: toggle between an async and a
;; – regular function.

;; – ip is introduce-parameter: changes the marked expression to a
;;  parameter in a local function.

;; – lp is localize-parameter: changes a parameter to a local var in a
;; – local function.

;; – wi is wrap-buffer-in-iife: wraps the entire buffer in an
;;  immediately invoked function expression
;;
;; – ig is inject-global-in-iife: creates a shortcut for a marked global by
;;  injecting it in the wrapping immediately invoked function
;;  expression – ag is add-to-globals-annotation: creates a /*global
;;  */ annotation if it is missing, and adds the var at point to it.

;; – ev is extract-var: takes a marked expression and replaces it with
;; – a var.

;; – el is extract-let: similar to extract-var but uses a
;; – let-statement.

;; – ec is extract-const: similar to extract-var but uses a
;; – const-statement.

;; – iv is inline-var: replaces all instances of a variable with its
;; – initial value.

;; – rv is rename-var: renames the variable on point and all
;; – occurrences in its lexical scope.

;; – vt is var-to-this: changes local var a to be this.a instead.

;; – ao is arguments-to-object: replaces arguments to a function call
;;  with an object literal of named arguments.

;; – 3i is ternary-to-if: converts ternary operator to if-statement.

;; – sv is split-var-declaration: splits a var with multiple vars
;; declared, into several var statements.

;; – ss is split-string: splits a string.

;; – st is string-to-template: converts a string into a template
;; string.

;; – uw is unwrap: replaces the parent statement with the selected
;; – region.

;; – lt is log-this: adds a console.log() statement for what is at
;; point (or region). with a prefix argument, use json
;; pretty-printing.

;; – dt is debug-this: adds a debug() statement for what is at point
;; – (or region).

;; – sl is forward-slurp: moves the next statement into current
;;  function, if-statement, for-loop or while-loop.

;; – ba is forward-barf: moves the last child out of current function,
;;  if-statement, for-loop or while-loop.

;;– k is kill: kills to the end of the line, but does not cross semantic boundaries.

;; prefix ef extract function

(leaf
  js2-refactor
  :ensure t
  :hook (js2-mode-hook . js2-refactor-mode)
  :custom (js2-skip-preprocessor-directives . t)
  :config (js2r-add-keybindings-with-prefix "C-c C-m"))
