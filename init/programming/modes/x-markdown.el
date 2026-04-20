;; -*- lexical-binding: t -*-

(leaf markdown-mode
  :ensure t
  :mode (("README\\.md\\'" . gfm-mode)      ;; git-hub flavoured
         ("\\.md\\'"       . markdown-mode) ;; normal
         ("\\.markdown\\'" . gfm-mode))
  :custom ((markdown-fontify-code-blocks-natively . t)
           (markdown-command . "cmark")))
